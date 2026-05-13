#!/usr/bin/env node
// gdocs-post — post anchored comments to a Google Doc via the chrome-cdp
// daemon's per-tab Unix socket. Called by the `gdocs-comment` wrapper.
//
// Modes:
//   gdocs-post.mjs validate <plan.json>            # validate plan, exit 0/2
//   gdocs-post.mjs count <plan.json>               # print item count to stdout
//   gdocs-post.mjs <target> <plan.json> [residual] # post comments (default)
//
// <target> is a CDP target id or unique prefix; the socket is resolved by
// globbing the chrome-cdp daemon's runtime dir.
//
// Architecture notes:
//   - The Find & Replace dialog gives us a real text selection (Google
//     Docs renders to a canvas, so the DOM Selection API is useless).
//   - All selectors are structural / Material-class-based — no UI text
//     match, so the script works in any locale.
//   - Every step verifies its postcondition (input value matches,
//     dialog visibility via real CSS check, draft count drops to 0).

import net from 'net';
import { resolve } from 'path';
import { readFileSync, writeFileSync, existsSync, readdirSync } from 'fs';
import { homedir, platform } from 'os';

const IS_WINDOWS = platform() === 'win32';
const RUNTIME_DIR = IS_WINDOWS
  ? resolve(process.env.LOCALAPPDATA || resolve(homedir(), 'AppData', 'Local'), 'cdp')
  : process.env.XDG_RUNTIME_DIR
    ? resolve(process.env.XDG_RUNTIME_DIR, 'cdp')
    : resolve(homedir(), '.cache', 'cdp');

// ─── plan loading + validation ───────────────────────────────────────────────
const EMAIL_RE = /^[\w.+-]+@[\w-]+(\.[\w-]+)+$/;

function die(msg, code = 2) {
  process.stderr.write(`gdocs-post: ${msg}\n`);
  process.exit(code);
}

function loadPlan(path) {
  let raw;
  try { raw = readFileSync(path, 'utf8'); }
  catch (e) { die(`cannot read plan ${path}: ${e.message}`); }
  let plan;
  try { plan = JSON.parse(raw); }
  catch (e) { die(`plan ${path} is not valid JSON: ${e.message}`); }
  if (!Array.isArray(plan)) die(`plan ${path} must be a JSON array, got ${typeof plan}`);
  return plan;
}

function validatePlan(plan) {
  for (let i = 0; i < plan.length; i++) {
    const item = plan[i];
    if (typeof item !== 'object' || item === null || Array.isArray(item)) {
      die(`item ${i}: must be an object`);
    }
    if (typeof item.anchor !== 'string' || !item.anchor.trim()) {
      die(`item ${i}: 'anchor' must be a non-empty string`);
    }
    const mentions = item.mentions ?? [];
    if (!Array.isArray(mentions)) die(`item ${i}: 'mentions' must be an array`);
    for (let j = 0; j < mentions.length; j++) {
      const m = mentions[j];
      if (typeof m !== 'string' || !EMAIL_RE.test(m)) {
        die(`item ${i} mention ${j}: '${m}' does not look like a valid email`);
      }
    }
    // `text` is optional iff there's at least one mention — a mention-only
    // comment is a valid Google Docs primitive ("tag this person, no body
    // needed"). Otherwise it must be non-empty.
    const text = item.text ?? '';
    if (typeof text !== 'string') die(`item ${i}: 'text' must be a string when present`);
    if (!text.trim() && mentions.length === 0) {
      die(`item ${i}: 'text' must be a non-empty string when no mentions are provided`);
    }
  }
  return plan;
}

// ─── subcommands: validate, count ────────────────────────────────────────────
const argv = process.argv.slice(2);
if (argv[0] === 'validate') {
  if (argv.length < 2 || argv.length > 3) die('usage: gdocs-post.mjs validate <plan.json> [--print-count]');
  const plan = validatePlan(loadPlan(argv[1]));
  if (argv[2] === '--print-count') {
    process.stdout.write(`gdocs-comment: plan looks OK (${plan.length} items)\n`);
  }
  process.exit(0);
}
if (argv[0] === 'count') {
  if (argv.length !== 2) die('usage: gdocs-post.mjs count <plan.json>');
  process.stdout.write(loadPlan(argv[1]).length + '\n');
  process.exit(0);
}

// ─── post mode ───────────────────────────────────────────────────────────────
const [TARGET_ARG, PLAN_PATH, RESIDUAL_PATH] = argv;
if (!TARGET_ARG || !PLAN_PATH) {
  process.stderr.write('usage: gdocs-post.mjs <target> <plan.json> [residual-out.json]\n');
  process.stderr.write('       gdocs-post.mjs validate <plan.json>\n');
  process.stderr.write('       gdocs-post.mjs count <plan.json>\n');
  process.exit(2);
}

// Resolve `TARGET_ARG` (id or unique prefix) to a full target id by looking
// at chrome-cdp daemon sockets in RUNTIME_DIR. Spawning a daemon (the
// "Allow debugging" prompt) is the wrapper's job; if no socket exists we
// surface a clear error rather than silently hanging.
function resolveTargetId(prefix) {
  if (IS_WINDOWS) return prefix; // can't enumerate named pipes; trust caller
  let entries;
  try { entries = readdirSync(RUNTIME_DIR); }
  catch (e) { die(`cannot read chrome-cdp runtime dir ${RUNTIME_DIR}: ${e.message}`, 1); }
  const ids = entries
    .filter((f) => f.startsWith('cdp-') && f.endsWith('.sock'))
    .map((f) => f.slice(4, -5));
  const upper = prefix.toUpperCase();
  const matches = ids.filter((id) => id.toUpperCase().startsWith(upper));
  if (matches.length === 0) {
    die(`no chrome-cdp daemon socket matches prefix "${prefix}" in ${RUNTIME_DIR}\n` +
        '         (the wrapper should have spawned one — make sure cdp.mjs is reachable)', 1);
  }
  if (matches.length > 1) {
    die(`prefix "${prefix}" matches ${matches.length} sockets: ${matches.join(', ')}`, 1);
  }
  return matches[0];
}

const TARGET_ID = resolveTargetId(TARGET_ARG);
const SOCK = IS_WINDOWS
  ? `\\\\.\\pipe\\cdp-${TARGET_ID}`
  : resolve(RUNTIME_DIR, `cdp-${TARGET_ID}.sock`);

if (!IS_WINDOWS && !existsSync(SOCK)) {
  die(`daemon socket not found at ${SOCK}`, 1);
}

const plan = validatePlan(loadPlan(PLAN_PATH));

// ─── daemon RPC ──────────────────────────────────────────────────────────────
let conn;
let nextId = 1;
const pending = new Map();
let buf = '';

function rpc(cmd, args = []) {
  const id = nextId++;
  return new Promise((res, rej) => {
    pending.set(id, { res, rej });
    conn.write(JSON.stringify({ id, cmd, args }) + '\n');
    setTimeout(() => {
      if (pending.has(id)) { pending.delete(id); rej(new Error(`Timeout: ${cmd}`)); }
    }, 30000);
  });
}

function connectDaemon() {
  return new Promise((res, rej) => {
    conn = net.connect(SOCK);
    let opened = false;
    conn.on('connect', () => { opened = true; res(); });
    conn.on('error', (e) => {
      // Before the socket opens, surface the error to the connect promise.
      // After it opens, reject every pending rpc so we don't wait the full
      // 30 s per-call timeout × N pending — the daemon is gone, every call
      // will fail anyway.
      if (!opened) return rej(e);
      rejectPending(`daemon socket error: ${e.message}`);
    });
    conn.on('close', () => {
      if (!opened) return; // handled by 'error'
      rejectPending('daemon socket closed unexpectedly');
    });
    conn.on('data', (chunk) => {
      buf += chunk.toString();
      const lines = buf.split('\n');
      buf = lines.pop();
      for (const line of lines) {
        if (!line.trim()) continue;
        const msg = JSON.parse(line);
        if (pending.has(msg.id)) {
          const { res, rej } = pending.get(msg.id);
          pending.delete(msg.id);
          if (msg.ok) res(msg.result);
          else rej(new Error(msg.error));
        }
      }
    });
  });
}

function rejectPending(reason) {
  if (pending.size === 0) return;
  const err = new Error(reason);
  for (const { rej } of pending.values()) rej(err);
  pending.clear();
}

const sleep = (ms) => new Promise(r => setTimeout(r, ms));

// ─── stable structural selectors (no UI-text dependency) ─────────────────────
// FR_BTNS_FILLED matches Material's "filled" (primary-action) buttons in
// the F&R dialog. We do not click this selector — Google Docs' incremental
// search has already selected the first match by the time findAndSelect
// would need to. Instead, the selector is asserted to match exactly one
// element as a redesign tripwire: if a future Google UI redesign promotes
// a second button to primary (say "Replace All"), the script fails loudly
// instead of risking a wrong-button click on the next round of changes.
const SEL = {
  FR_DIALOG:      '.appsDocsUiWizFindandreplacedialogContainer',
  FR_INPUT_FIND:  '.appsDocsUiWizFindandreplacedialogContainer input',
  FR_BTNS_FILLED: '.appsDocsUiWizFindandreplacedialogContainer button[class*="WizButtonFilled"]',
  FR_BTN_CLOSE:   '.appsDocsUiWizFindandreplacedialogContainer button[class*="WizIconButtonStandard"]',
  DRAFT_TEXTAREA: '.docos-input-textarea',
  DRAFT_ACTIVE:   '.docos-docoview-active',
  DRAFT_SUBMIT:   '.docos-docoview-active .jfk-button-action',
  DRAFT_CANCEL:   '.docos-docoview-active .jfk-button-standard',
};

// Comprehensive visibility check: in DOM, has nonzero size, not hidden via CSS.
// (offsetParent !== null misses `visibility: hidden`, which Google Docs uses
//  for closed dialogs that linger in the DOM.)
const IS_VISIBLE_JS = `function(el) {
  if (!el || el.offsetParent === null) return false;
  const r = el.getBoundingClientRect();
  if (r.width === 0 || r.height === 0) return false;
  const s = window.getComputedStyle(el);
  return s.visibility !== 'hidden' && s.display !== 'none' && parseFloat(s.opacity || '1') > 0;
}`;

// ─── low-level input helpers ─────────────────────────────────────────────────
async function sendKey({ key, code, wCode, modifiers = 0 }) {
  const base = { key, code, windowsVirtualKeyCode: wCode, nativeVirtualKeyCode: wCode, modifiers };
  await rpc('evalraw', ['Input.dispatchKeyEvent', JSON.stringify({ ...base, type: 'rawKeyDown' })]);
  await rpc('evalraw', ['Input.dispatchKeyEvent', JSON.stringify({ ...base, type: 'keyUp' })]);
}

// Macros for the chords we use. modifier bits: Alt=1, Ctrl=2, Meta=4, Shift=8.
// On macOS we send Meta for ⌘; on other platforms we send Ctrl. Google Docs
// accepts either via Input.dispatchKeyEvent (the OS-level binding is bypassed).
const IS_MAC = platform() === 'darwin';
const CMD_BIT = IS_MAC ? 4 : 2;

// `key` is the *resulting* key after modifiers, the same value a real
// keydown event would carry as e.key. Shift-letter chords like ⌘⇧H must
// send 'H' (capital) to match what the browser would natively dispatch;
// Alt-letter chords like ⌘⌥M must send 'm' (raw lowercase) — sending the
// macOS-composed dead-key character 'µ' there only works on macOS, where
// Chrome happens to round-trip the same value. (Earlier we'd briefly
// over-applied the 'µ'→'m' fix to cmdShiftH; it caused a key/modifier
// pair no real keyboard produces.)
const KEY = {
  cmdShiftH: () => sendKey({ key: 'H', code: 'KeyH', wCode: 72, modifiers: CMD_BIT | 8 }),
  cmdOptM:   () => sendKey({ key: 'm', code: 'KeyM', wCode: 77, modifiers: CMD_BIT | 1 }),
  cmdA:      () => sendKey({ key: 'a', code: 'KeyA', wCode: 65, modifiers: CMD_BIT }),
  esc:       () => sendKey({ key: 'Escape', code: 'Escape', wCode: 27 }),
  backspace: () => sendKey({ key: 'Backspace', code: 'Backspace', wCode: 8 }),
};

async function typeText(text) {
  await rpc('evalraw', ['Input.insertText', JSON.stringify({ text })]);
}

async function mouseMove(x, y) {
  await rpc('evalraw', ['Input.dispatchMouseEvent', JSON.stringify({ type:'mouseMoved', x, y, button:'left', clickCount:1, modifiers:0 })]);
}

async function mouseClick(x, y, clickCount = 1) {
  await mouseMove(x, y);
  await rpc('evalraw', ['Input.dispatchMouseEvent', JSON.stringify({ type:'mousePressed', x, y, button:'left', clickCount, modifiers:0 })]);
  await sleep(40);
  await rpc('evalraw', ['Input.dispatchMouseEvent', JSON.stringify({ type:'mouseReleased', x, y, button:'left', clickCount, modifiers:0 })]);
}

async function tripleClick(x, y) {
  await mouseClick(x, y, 1); await sleep(40);
  await mouseClick(x, y, 2); await sleep(40);
  await mouseClick(x, y, 3);
}

// ─── DOM-layer helpers ───────────────────────────────────────────────────────
async function isVisible(selector) {
  const r = await rpc('eval', [`!!((${IS_VISIBLE_JS})(document.querySelector(${JSON.stringify(selector)})))`]);
  return r === 'true';
}

async function countVisible(selector) {
  const r = await rpc('eval', [
    `Array.from(document.querySelectorAll(${JSON.stringify(selector)})).filter(${IS_VISIBLE_JS}).length`,
  ]);
  return parseInt(r, 10);
}

// Get CSS coords for an element, scrolling it into view first so it lands
// inside the viewport (CDP clicks at offscreen coords are silently dropped).
async function getCoords(selector, scroll = true) {
  const r = await rpc('eval', [`
    (function() {
      const el = document.querySelector(${JSON.stringify(selector)});
      if (!(${IS_VISIBLE_JS})(el)) return 'null';
      ${scroll ? "el.scrollIntoView({block:'center', behavior:'instant'});" : ''}
      const r = el.getBoundingClientRect();
      return JSON.stringify({ x: Math.round(r.x + r.width/2), y: Math.round(r.y + r.height/2) });
    })()
  `]);
  return (r === 'null' || r === '') ? null : JSON.parse(r);
}

// Click an element and wait briefly. Only retries when the element is
// initially not found / not visible — it does not re-issue the click if the
// UI doesn't advance. Use `clickElUntil` when you need a postcondition.
async function clickEl(selector, { retries = 3, waitAfter = 500 } = {}) {
  for (let i = 0; i < retries; i++) {
    const c = await getCoords(selector, true);
    if (!c) { await sleep(300); continue; }
    await mouseClick(c.x, c.y);
    await sleep(waitAfter);
    return true;
  }
  return false;
}

// Click `selector`, then poll `verify` until it returns true or the budget
// expires. Re-issues the click between polls so an animation/overlay that
// swallowed the first one gets another chance. Returns true on success.
async function clickElUntil(selector, verify, { attempts = 4, pollMs = 250, pollSteps = 6 } = {}) {
  for (let attempt = 1; attempt <= attempts; attempt++) {
    const c = await getCoords(selector, true);
    if (!c) { await sleep(300); continue; }
    await mouseClick(c.x, c.y);
    for (let s = 0; s < pollSteps; s++) {
      await sleep(pollMs);
      if (await verify()) return true;
    }
  }
  return false;
}

async function getInputValue(selector) {
  return await rpc('eval', [`
    (function() {
      const el = document.querySelector(${JSON.stringify(selector)});
      return el ? (el.value || '') : '';
    })()
  `]);
}

// ─── high-level operations ──────────────────────────────────────────────────
async function ensureClean() {
  for (let i = 0; i < 5; i++) {
    const dlg = await isVisible(SEL.FR_DIALOG);
    const draft = await countVisible(SEL.DRAFT_TEXTAREA);
    if (!dlg && draft === 0) return true;
    if (draft > 0) await clickEl(SEL.DRAFT_CANCEL, { retries: 1, waitAfter: 600 });
    await KEY.esc();
    await sleep(400);
  }
  return !(await isVisible(SEL.FR_DIALOG)) && (await countVisible(SEL.DRAFT_TEXTAREA)) === 0;
}

async function openFindReplace() {
  for (let i = 0; i < 3; i++) {
    await KEY.cmdShiftH();
    await sleep(900);
    if (await isVisible(SEL.FR_INPUT_FIND)) return true;
  }
  return false;
}

async function clearFindInput() {
  const c = await getCoords(SEL.FR_INPUT_FIND, true);
  if (!c) return false;
  await tripleClick(c.x, c.y);
  await sleep(150);
  await KEY.backspace();
  await sleep(150);
  if ((await getInputValue(SEL.FR_INPUT_FIND)) === '') return true;
  // fallback: ⌘A + Backspace
  await KEY.cmdA();
  await sleep(100);
  await KEY.backspace();
  await sleep(150);
  return (await getInputValue(SEL.FR_INPUT_FIND)) === '';
}

// Parse the F&R dialog's leading "current of total" counter, language-
// agnostic. The counter ("1 of 23" / "1 z 23" / "1 von 23") appears as
// the first text content of the dialog once Google Docs has run its
// incremental search. To avoid latching onto digit-sequences inside the
// user's typed anchor (e.g. anchor "2024 budget 5 lines"), we only look
// at the first 32 chars of the dialog's trimmed textContent and require
// the pattern at position 0. Returns the total-matches number, or null
// if it can't be determined.
async function getMatchTotal() {
  const r = await rpc('eval', [`
    (function() {
      const dlg = document.querySelector(${JSON.stringify(SEL.FR_DIALOG)});
      if (!(${IS_VISIBLE_JS})(dlg)) return 'null';
      const head = (dlg.textContent || '').trim().slice(0, 32);
      const m = head.match(/^(\\d+)\\s+\\S+\\s+(\\d+)\\b/);
      return m ? m[2] : 'null';
    })()
  `]);
  return (r === 'null' || r === '') ? null : parseInt(r, 10);
}

// Sanity-check the F&R dialog's primary-action button. We don't click it —
// incremental search already selected the first match — but we want to
// fail loudly if a future UI redesign exposes more than one filled button
// in the dialog, so a stray "Replace All" can never become the click
// target. Returns the count of visible filled buttons; callers expect 1.
async function countFilledButtons() {
  const r = await rpc('eval', [`
    (function() {
      const btns = Array.from(document.querySelectorAll(${JSON.stringify(SEL.FR_BTNS_FILLED)}))
        .filter(${IS_VISIBLE_JS});
      return String(btns.length);
    })()
  `]);
  return parseInt(r, 10);
}

async function findAndSelect(anchor, log) {
  if (!await openFindReplace())  { log('F&R dialog did not open'); return false; }
  if (!await clearFindInput())   { log('could not clear Find input'); return false; }
  await typeText(anchor);
  await sleep(350);
  const v = await getInputValue(SEL.FR_INPUT_FIND);
  if (v !== anchor) {
    log(`Find input has "${v.slice(0, 60)}..." (expected "${anchor.slice(0, 60)}...")`);
    return false;
  }
  // Sanity-check the primary button count (still 1 = "Next") even though
  // we no longer click it — the assertion serves as an early-warning for
  // a future Google UI redesign.
  const filledCount = await countFilledButtons();
  if (filledCount !== 1) {
    log(`F&R dialog has ${filledCount} primary-action buttons (expected 1) — refusing to proceed`);
    return false;
  }
  // Verify the anchor actually matched. Poll briefly because incremental
  // search is debounced. FAIL CLOSED if the counter is unreadable — better
  // to abort one item than to post a comment to the wrong anchor.
  let total = null;
  for (let i = 0; i < 12; i++) {
    total = await getMatchTotal();
    if (total !== null) break;
    await sleep(150);
  }
  if (total === null) {
    log('could not read F&R match counter (locale may use unexpected format) — aborting item to avoid mis-anchoring');
    return false;
  }
  if (total === 0) {
    log(`anchor not found in doc (0 matches): "${anchor.slice(0, 60)}"`);
    return false;
  }
  // NOTE: we deliberately do *not* click the "Find Next" button here.
  // Incremental search has already selected the first match in the doc;
  // clicking Next would advance past it to match #2, which contradicts
  // SKILL.md's documented "first match wins" contract and would post
  // comments on the wrong occurrence for any non-unique anchor.
  if (!await clickElUntil(SEL.FR_BTN_CLOSE, async () => !(await isVisible(SEL.FR_DIALOG)))) {
    log('F&R dialog did not close after multiple clicks');
    return false;
  }
  return true;
}

async function openCommentDraft() {
  for (let i = 0; i < 3; i++) {
    await KEY.cmdOptM();
    await sleep(1200);
    if (await countVisible(SEL.DRAFT_TEXTAREA) > 0) return true;
  }
  return false;
}

async function submitDraft() {
  // Click + verify the draft textarea is gone (postcondition). Re-issues the
  // click until the budget is exhausted.
  const ok = await clickElUntil(
    SEL.DRAFT_SUBMIT,
    async () => (await countVisible(SEL.DRAFT_TEXTAREA)) === 0,
    { attempts: 4, pollMs: 400, pollSteps: 5 },
  );
  return ok ? 1 : 0;
}

// ─── per-item post ───────────────────────────────────────────────────────────
function buildCommentText(item) {
  const mentions = Array.isArray(item.mentions)
    ? item.mentions.map((e) => `+${e}`).join(' ')
    : '';
  const sep = mentions && item.text ? ' ' : '';
  return mentions + sep + (item.text || '');
}

async function postOne(item, idx, total) {
  const anchor = item.anchor;
  const body   = buildCommentText(item);
  const tag    = `[${idx + 1}/${total}] anchor: ${anchor.slice(0, 60)}${anchor.length > 60 ? '...' : ''}`;
  process.stdout.write(`${tag}\n`);
  const log = (msg) => process.stdout.write(`  ${msg}\n`);

  if (!await ensureClean())             { log('SKIP: could not reach clean state'); return false; }
  if (!await findAndSelect(anchor, (m) => log(`ERROR: ${m}`)))  return false;
  if (!await openCommentDraft())        { log('ERROR: draft did not open'); return false; }

  await typeText(body);
  await sleep(700);
  if ((await submitDraft()) === 0) { log('FAIL: draft still open after 4 submit attempts'); return false; }
  log(`✓ posted`);
  return true;
}

// ─── main ────────────────────────────────────────────────────────────────────
// Range vars first — they don't need the daemon socket, and validating them
// up here means a bad START/LIMIT exits before we open the connection (no
// half-closed daemon socket from an env-typo path).
function parseRangeEnv(name, defaultVal, min, max) {
  const raw = process.env[name];
  if (raw === undefined || raw === '') return defaultVal;
  const n = Number(raw);
  if (!Number.isInteger(n) || n < min || n > max) {
    process.stderr.write(`gdocs-post: ${name}=${JSON.stringify(raw)} is not a valid integer in [${min}, ${max}]\n`);
    process.exit(2);
  }
  return n;
}

async function main() {
  // START / LIMIT come from env. Resolve the bounds *together* — START's
  // max is plan.length - 1 (= "last addressable index"), and LIMIT's max
  // is `plan.length - start` (the remaining items). For an empty plan, we
  // skip range validation entirely and the loop runs zero iterations
  // legitimately.
  if (plan.length === 0) {
    process.stderr.write('gdocs-post: plan is empty — nothing to post.\n');
    process.exit(0);
  }
  const start = parseRangeEnv('START', 0, 0, plan.length - 1);
  const limit = parseRangeEnv('LIMIT', plan.length - start, 1, plan.length - start);

  try {
    await connectDaemon();
  } catch (e) {
    process.stderr.write(`gdocs-post: could not connect to daemon socket ${SOCK}: ${e.message}\n`);
    process.exit(1);
  }

  const posted = [];
  const failed = [];
  let aborted = false;

  try {
    await rpc('evalraw', ['Page.bringToFront', '{}']).catch(() => {});
    await sleep(400);

    // Background-tab preflight. Chrome aggressively throttles setTimeout on
    // hidden tabs, which would balloon our polling loops past the rpc
    // timeout and turn one bad item into a 25-minute hang. SKILL.md
    // documents exit 75 (EX_TEMPFAIL) for this case — re-run after the tab
    // is in the foreground.
    const hidden = await rpc('eval', ['document.hidden ? "1" : "0"']).catch(() => '0');
    if (hidden === '1') {
      process.stderr.write(
        'gdocs-post: tab is still hidden after Page.bringToFront — manually focus the\n' +
        '  browser window and re-run. Chrome throttles timers on background tabs, so\n' +
        '  posting would degrade into a long stall rather than fail per-item.\n');
      process.exit(75); // EX_TEMPFAIL; finally below still runs and closes conn.
    }

    // Refuse to start if the user already has an unsent comment draft open.
    // `ensureClean` between items clicks the active draft's Cancel button, so
    // running on top of a real human-authored draft would discard their text
    // without confirmation.
    if ((await countVisible(SEL.DRAFT_TEXTAREA)) > 0) {
      process.stderr.write(
        'gdocs-post: there is an unsent comment draft open in the doc. Close or post\n' +
        "  it before re-running — this script's cleanup path would otherwise discard\n" +
        '  it. Exiting without doing anything.\n');
      process.exit(1);
    }

    for (let i = start; i < start + limit && i < plan.length; i++) {
      let ok = false;
      try { ok = await postOne(plan[i], i, plan.length); }
      catch (e) { process.stdout.write(`  EXCEPTION: ${e.message}\n`); }
      (ok ? posted : failed).push(i);
      // Cleanup between items. ensureClean reports failure two ways: a
      // thrown exception (daemon drop, fatal rpc error) or a false return
      // (loop budget exhausted with a dialog/draft still visible). Both
      // need to abort the loop so the dirty UI state doesn't leak into the
      // next item — and so the tail of un-tried items lands in the
      // residual.
      let cleaned = false;
      try { cleaned = await ensureClean(); }
      catch (e) {
        process.stderr.write(`gdocs-post: ensureClean threw (${e.message}); aborting loop, will write residual\n`);
      }
      if (!cleaned) {
        if (!aborted) process.stderr.write('gdocs-post: ensureClean could not reach a clean UI state; aborting loop, will write residual\n');
        for (let j = i + 1; j < start + limit && j < plan.length; j++) failed.push(j);
        aborted = true;
        break;
      }
    }
  } finally {
    process.stderr.write(`\nsummary: ${posted.length} ok / ${failed.length} fail (${posted.length + failed.length} total)${aborted ? ' [aborted mid-run]' : ''}\n`);
    if (failed.length > 0 && RESIDUAL_PATH) {
      const residual = failed.map((i) => plan[i]);
      try {
        writeFileSync(RESIDUAL_PATH, JSON.stringify(residual, null, 2) + '\n');
        process.stderr.write(`gdocs-post: residual plan written to ${RESIDUAL_PATH} (${failed.length} items)\n`);
      } catch (e) {
        process.stderr.write(`gdocs-post: could not write residual plan to ${RESIDUAL_PATH}: ${e.message}\n`);
      }
    }
    try { conn.end(); } catch {}
  }

  process.exit(failed.length === 0 ? 0 : 1);
}

main().catch((e) => { process.stderr.write(`gdocs-post: ${e.stack || e.message}\n`); process.exit(1); });
