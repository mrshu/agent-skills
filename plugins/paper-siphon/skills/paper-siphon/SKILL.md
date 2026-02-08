---
name: paper-siphon
description: Convert academic PDFs to clean Markdown. Use whenever you encounter a PDF paper (local file or URL) that needs to be read, analyzed, or referenced as text.
---

# Paper Siphon — PDF to Markdown

Convert academic PDFs into clean Markdown using **paper-siphon**. Runs via `uvx` — no installation needed.

## Quick Start

```bash
# Local PDF
uvx paper-siphon paper.pdf

# Remote PDF (e.g. arXiv)
uvx paper-siphon https://arxiv.org/pdf/1706.03762.pdf

# Custom output path
uvx paper-siphon paper.pdf -o paper-notes.md
```

By default, output is written to the same filename with a `.md` extension (e.g. `paper.pdf` → `paper.md`).

## Choosing the Right Extraction Approach

Paper Siphon has multiple extraction pipelines. Pick the right one based on the paper's complexity.

### Default pipeline (Docling-based)

Best for: most papers — standard single/double-column text, simple tables, no heavy math.

```bash
uvx paper-siphon paper.pdf
```

This is the fastest option. It uses Docling to parse PDF structure, strips margin line numbers (common in journal proofs), and normalizes whitespace. **Start here** — it handles the majority of papers well.

### VLM pipeline (`--vlm`)

Best for: papers with complex layouts — multi-column figures interleaved with text, unusual formatting, scanned documents, or when the default pipeline produces garbled output.

```bash
uvx paper-siphon --vlm paper.pdf
```

This uses a vision-language model to interpret page images directly. It is significantly slower but handles visual complexity that pure text extraction misses. Use this when:

- The default output has mangled paragraphs or missing sections
- The paper has complex figure/table/text interleaving
- The PDF is a scan rather than born-digital

On Apple Silicon (M-series), this automatically uses MLX acceleration. To disable it:

```bash
uvx paper-siphon --vlm --no-mlx paper.pdf
```

To use the VLM pipeline with MLX dependencies explicitly included:

```bash
uvx --with 'paper-siphon[mlx]' paper-siphon --vlm paper.pdf
```

### Formula enrichment (`--enrich-formula`)

Best for: math-heavy papers where correct LaTeX rendering of equations matters.

```bash
uvx paper-siphon --enrich-formula paper.pdf
```

This post-processes extracted math expressions for better fidelity. **Warning:** resource-intensive — only enable when the paper's math content is important for the task at hand.

### Decision guide

| Paper type | Command |
|---|---|
| Standard text-heavy paper | `uvx paper-siphon paper.pdf` |
| Complex layout / scanned PDF | `uvx paper-siphon --vlm paper.pdf` |
| Math-heavy paper | `uvx paper-siphon --enrich-formula paper.pdf` |
| Math-heavy + complex layout | `uvx paper-siphon --vlm --enrich-formula paper.pdf` |

**Rule of thumb:** try the default pipeline first. If the output is garbled or incomplete, escalate to `--vlm`.

## CLI Reference

```
uvx paper-siphon [OPTIONS] INPUT
```

| Option | Description |
|---|---|
| `INPUT` | Path to a local PDF file, or a URL pointing directly to a PDF |
| `-o, --output PATH` | Custom output file path (default: input filename with `.md` extension) |
| `--vlm` | Use vision-language model pipeline for complex layouts |
| `--mlx / --no-mlx` | Enable/disable Apple Silicon MLX acceleration (default: enabled when available) |
| `--enrich-formula` | Enrich mathematical expressions (resource-intensive) |
| `-v, --verbose` | Enable detailed debug logging |

## Input Formats

- **Local PDF files:** `uvx paper-siphon ./downloads/paper.pdf`
- **Remote URLs:** `uvx paper-siphon https://arxiv.org/pdf/1706.03762.pdf`

For arXiv, use the `/pdf/` URL (not `/abs/`). For example:
- Correct: `https://arxiv.org/pdf/1706.03762.pdf`
- Wrong: `https://arxiv.org/abs/1706.03762`

## Common Workflows

### Download and read a paper someone linked

1. Extract the PDF:
   ```bash
   uvx paper-siphon https://arxiv.org/pdf/1706.03762.pdf -o attention.md
   ```
2. Read the resulting Markdown file to answer questions or summarize.

### Batch-convert a folder of PDFs

```bash
for f in papers/*.pdf; do uvx paper-siphon "$f"; done
```

### Combine with scholar-search

1. Find a paper with `scholar-search` skill
2. Get the PDF URL from the search results (look for arXiv or open-access links)
3. Convert to Markdown:
   ```bash
   uvx paper-siphon https://arxiv.org/pdf/<id>.pdf -o paper.md
   ```

## When to Use

Use this skill when:
- You encounter a PDF of a paper (local or URL) and need to read its contents
- A user shares a PDF link and asks about its content
- You need to extract text from an academic paper for summarization, analysis, or reference
- A user asks you to "download", "read", "extract", or "convert" a paper PDF
- You need to work with paper content that is only available as PDF
