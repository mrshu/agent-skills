---
name: scholar-search
description: Find academic papers, explore citations, and export BibTeX. Use when asked about research papers, references, citations, bibliography, or scholarly information.
---

# Academic Scholar Search

Find papers with **s2cli** (Semantic Scholar), **openalexcli** (OpenAlex), and **arxivy** (arXiv), get high-quality BibTeX with **dblpcli** (DBLP). All tools run via `uvx` — no installation needed.

## Finding Papers

Three tools for paper discovery, each with different strengths.

### s2cli (Semantic Scholar)

Best for: paper recommendations, citation/reference networks, arXiv/DOI lookups, citation count filtering.

```bash
# Search by keyword
uvx s2cli search "attention mechanism" --limit 10 --json
uvx s2cli search "transformers" --year 2020-2024 --min-citations 100 --json

# Filter options: --year, --venue, --field, --min-citations, --open-access

# Get paper details by ID (supports S2 ID, DOI, arXiv, CorpusId)
uvx s2cli paper ARXIV:1706.03762 --json
uvx s2cli paper DOI:10.18653/v1/N18-3011 --json

# Citation network
uvx s2cli citations ARXIV:1706.03762 --limit 20 --json   # papers citing this
uvx s2cli references ARXIV:1706.03762 --limit 20 --json  # papers cited by this

# Recommendations based on a seed paper
uvx s2cli recommend ARXIV:1706.03762 --limit 10 --json
uvx s2cli recommend ARXIV:1706.03762 --pool all-cs --json  # pool: 'recent' or 'all-cs'

# Author search and papers
uvx s2cli author search "Yoshua Bengio" --json
uvx s2cli author papers <author_id> --json
```

### openalexcli (OpenAlex)

Best for: broadest coverage (260M+ works), institution/journal queries, group-by aggregation, ORCID lookups, date range filtering.

```bash
# Search by keyword
uvx openalexcli search "attention mechanism" --limit 10 --json
uvx openalexcli search "transformers" --from-date 2020-01-01 --min-citations 100 --json

# Filter options: --filter, --from-date, --to-date, --min-citations, --open-access, --type, --sort, --group-by

# Get work by OpenAlex ID
uvx openalexcli work W2741809807 --json

# Citation network
uvx openalexcli citations W2741809807 --limit 20 --json
uvx openalexcli references W2741809807 --limit 20 --json

# Author search and works
uvx openalexcli author search "Yoshua Bengio" --json
uvx openalexcli author works <author_id> --json

# Institution queries
uvx openalexcli institution search "MIT" --json
uvx openalexcli institution works <institution_id> --json

# Journal/source queries
uvx openalexcli source search "Nature" --json
uvx openalexcli source works <source_id> --json

# Aggregation (unique to OpenAlex)
uvx openalexcli search "deep learning" --group-by publication_year --json
```

### arxivy (arXiv)

Best for: searching arXiv directly, getting paper details by arXiv ID, browsing recent submissions in a category. No API key needed.

```bash
# Search by keyword
uvx arxivy search "attention mechanism" --limit 10
uvx arxivy search "transformers" -c cs.CL -n 20
uvx arxivy search "diffusion models" --sort submittedDate

# Include abstracts in results
uvx arxivy search "RLHF" -c cs.AI --abstract

# Get paper details by arXiv ID (accepts bare IDs, versioned IDs, or full URLs)
uvx arxivy paper 1706.03762
uvx arxivy paper 1706.03762 2010.11929 1810.04805   # compare multiple
uvx arxivy paper 1706.03762 --json

# Browse recent submissions in a category
uvx arxivy new cs.AI
uvx arxivy new cs.CL -n 20 --abstract

# BibTeX export (fallback — prefer dblpcli for curated entries)
uvx arxivy bibtex 1706.03762
uvx arxivy bibtex 1706.03762 2010.11929 > refs.bib
```

**Note on output:** arxivy auto-detects whether stdout is a terminal. In a terminal it shows Rich tables; when piped it outputs JSON. Use `--json` to force JSON in a terminal.

### Which tool to pick

| Need | Use |
|---|---|
| Recommendations for a paper | `s2cli recommend` |
| Citation/reference graph traversal | `s2cli citations` / `s2cli references` |
| arXiv ID or DOI lookup | `s2cli paper` or `arxivy paper` |
| Search arXiv directly (by category, recency) | `arxivy search` |
| Browse new arXiv submissions | `arxivy new` |
| Broadest search coverage | `openalexcli search` |
| Filter by institution or journal | `openalexcli institution` / `openalexcli source` |
| Aggregate stats (group-by) | `openalexcli search --group-by` |
| ORCID-based author lookup | `openalexcli author get` |

## Getting BibTeX

Use **dblpcli** for high-quality BibTeX sourced directly from DBLP (curated, consistent formatting). If a paper isn't in DBLP (e.g. a very recent arXiv preprint), fall back to `uvx arxivy bibtex <arxiv_id>`.

### Workflow

1. Find the paper's DBLP key by searching:
   ```bash
   uvx dblpcli search "attention is all you need" --format json
   ```
   The `key` field in results (e.g., `conf/nips/VaswaniSPUJGKP17`) is what you need.

2. Export BibTeX:
   ```bash
   uvx dblpcli bibtex conf/nips/VaswaniSPUJGKP17
   ```

3. Batch export (multiple keys):
   ```bash
   uvx dblpcli bibtex conf/nips/VaswaniSPUJGKP17 journals/jmlr/KingmaB14
   ```

4. Custom citation key:
   ```bash
   uvx dblpcli bibtex conf/nips/VaswaniSPUJGKP17 --key vaswani2017attention
   ```

5. Save to file:
   ```bash
   uvx dblpcli bibtex conf/nips/VaswaniSPUJGKP17 --output refs.bib
   ```

### Full dblpcli command reference

```bash
# Search publications (supports AND/OR operators, author: prefix)
uvx dblpcli search "transformer attention" --format json
uvx dblpcli search "deep learning" --year 2020-2024 --format json
uvx dblpcli search "author:Vaswani" --limit 10 --format json

# Get publication details
uvx dblpcli pub conf/nips/VaswaniSPUJGKP17 --format json

# Author workflow
uvx dblpcli author search "Geoffrey Hinton" --format json    # find PID
uvx dblpcli author get <pid> --format json                   # author details
uvx dblpcli author pubs <pid> --format json                  # list publications
uvx dblpcli author bibtex <pid>                              # BibTeX for ALL papers

# Venue queries
uvx dblpcli venue search "NeurIPS" --format json
uvx dblpcli venue pubs conf/nips --year 2023 --format json
```

## Common Workflows

### Literature survey
1. Search broadly: `uvx s2cli search "topic" --json` or `uvx openalexcli search "topic" --json`
2. Find key papers, explore their citations: `uvx s2cli citations <id> --json`
3. Get recommendations: `uvx s2cli recommend <id> --json`
4. For each paper, find the DBLP key: `uvx dblpcli search "paper title" --format json`
5. Export BibTeX: `uvx dblpcli bibtex <key1> <key2> <key3> --output refs.bib`

### Build a bibliography from a list of papers
1. For each paper title, search DBLP: `uvx dblpcli search "title" --format json`
2. Collect DBLP keys from results
3. Batch export: `uvx dblpcli bibtex <key1> <key2> ... --output refs.bib`

### Citation network exploration
1. Start with a seed paper: `uvx s2cli paper ARXIV:1706.03762 --json`
2. Get citing papers: `uvx s2cli citations ARXIV:1706.03762 --limit 20 --json`
3. Get referenced papers: `uvx s2cli references ARXIV:1706.03762 --limit 20 --json`
4. Find related work: `uvx s2cli recommend ARXIV:1706.03762 --json`

### Get all papers by an author
- From DBLP: `uvx dblpcli author search "Name" --format json` → `uvx dblpcli author bibtex <pid>`
- From Semantic Scholar: `uvx s2cli author search "Name" --json` → `uvx s2cli author papers <id> --json`
- From OpenAlex: `uvx openalexcli author search "Name" --json` → `uvx openalexcli author works <id> --json`

## Configuration

| Variable | Purpose | Required |
|---|---|---|
| `S2_API_KEY` | Semantic Scholar API key (higher rate limits) | No |
| `OPENALEX_EMAIL` | OpenAlex polite pool (faster responses) | No |

Both tools work without these but may hit rate limits on heavy use.

## When to Use

Use this skill when the user asks about:
- Finding academic papers or research on a topic
- Citations, references, or bibliography
- BibTeX entries or .bib files
- Paper recommendations or related work
- Author publication lists
- Literature reviews or surveys
- DOI, arXiv, or paper lookups
- Browsing recent arXiv submissions in a category
