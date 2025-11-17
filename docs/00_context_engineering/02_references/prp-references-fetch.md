---
title: "PRP: Fetched Online Reference Documentation"
description: "Prompt Retrieval Pattern for context-engineering fetched online reference documentation"
pattern_type: "template-prp"
category: "context-engineering"
version: "2.0"
audience: "llm"
token_cost: "~150 (initial), ~800 (expanded)"
retrieval_trigger: "agent needs to fetch online reference documentation"
updated: "2025-11-17"
---

# PRP: Fetched Online Reference Documentation

## Purpose

<prp_purpose>

**ALWAYS use this PRP when** fetching online reference documentation from external URLs listed in the project's [context-required reference document](../00_init/03-context-required.md).

**Result:** Each URL generates its own standalone reference document following this template.

**Rationale:** Structured fetching ensures consistency, traceability, and optimal token efficiency across all external documentation.

</prp_purpose>

## Execution Methods

**EXECUTE this PRP using one of two methods:**

<method_selection>

**Choose Method 1** if you have a direct URL.

**Choose Method 2** if referencing context-required.md entries.

</method_selection>

### Method 1: Direct URL Execution

**WHEN:** User provides a direct URL for documentation fetching.

**Example Input:**
```
"Fetch and create reference documentation for <https://doc.rust-lang.org/book/ch04-00-understanding-ownership.html>"
```

**Agent MUST execute this sequence:**
1. **Recognize** the URL pattern in user request
2. **Load** this PRP template immediately
3. **Fetch** the documentation from the provided URL using MCP server priority hierarchy
4. **Create** a properly structured reference document following this template's output structure

### Method 2: Reference-Based Execution

**WHEN:** User references an entry from [context-required document](../00_init/03-context-required.md) without providing direct URL.

**Example Input:**
```
"Fetch the 'Rust Book: Ownership' reference from context-required.md"
```

**Agent MUST execute this sequence:**
1. **Read** the context-required.md document
2. **Locate** the specified reference entry (by title or description)
3. **Extract** the URL from the "URL" column
4. **Load** this PRP template
5. **Fetch** the documentation from the extracted URL using MCP server priority hierarchy
6. **Create** a properly structured reference document following this template

**Benefits of Method 2** (prefer when applicable):
- ✅ **Consistency:** Ensures alignment with project's curated reference list
- ✅ **Traceability:** Automatically includes "Required For" mapping from context-required.md
- ✅ **Validation:** Confirms reference relevance to project before fetching
- ✅ **Bidirectional links:** Maintains traceability between context-required.md and fetched docs

**Method Selection Rule:**
- **USE Method 2** when URL exists in context-required.md (better traceability)
- **USE Method 1** when fetching ad-hoc documentation not in context-required.md

**Note**: Both methods produce identical structured output following this template.

## Context Engineering Mandatory Directives for this PRP

Based on [Anthropic's Context Engineering Principles](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents), agents executing this PRP **MUST** adhere to the following directives (BLOCKING - zero exceptions):

<context_engineering_directives>

### 1. Minimize Context, Maximize Signal

**Principle**: Add only **necessary** context. Every token must earn its place.

<minimize_context_maximize_signal>

**MANDATORY APPLICATION:**

**NEVER** copy entire documentation pages verbatim.
- **Rationale:** Low signal-to-noise ratio wastes context budget and reduces agent comprehension.

**ALWAYS** extract only implementation-critical sections.
- **Include:** Code examples, anti-patterns, key constraints, failure patterns
- **Rationale:** Code examples provide 5-10x information density compared to prose.

**NEVER** include marketing content, lengthy preambles, or redundant explanations.
- **Rationale:** Non-technical content provides zero actionable guidance for implementation.

**ALWAYS** compress verbose prose into bullet points while preserving code examples.
- **Rationale:** Bullet points enable fast scanning; code examples provide high-density signal.

</minimize_context_maximize_signal>

### 2. Semantic Chunking & Progressive Disclosure

**Principle**: Structure content for efficient retrieval, load detail on-demand.

<semantic_chunking>

**MANDATORY APPLICATION:**

**ALWAYS** break concepts into H3 sections with semantic anchors.
- **Example:** `## Context` → `### Ownership Rules`, `### Borrowing Patterns`, `### Lifetime Annotations`
- **Rationale:** Enables surgical loading of specific sections without full document retrieval.

**ALWAYS** use bullet points for key takeaways.
- **Rationale:** Bullet points enable fast scanning and reduce cognitive load.

**ALWAYS** separate code examples from explanations.
- **Format:** Explanation paragraph → Code block → Key takeaways bullets
- **Rationale:** Code provides high-density signal; separation enables independent processing.

**NEVER** create monolithic text blocks.
- **Rationale:** Large undifferentiated blocks slow retrieval and waste tokens during partial reads.

</semantic_chunking>

### 3. Just-In-Time Information Retrieval

**Principle**: Fetch content when needed, not upfront. Lazy-load heavy resources.

<just_in_time_retrieval>

**MANDATORY APPLICATION:**

**ALWAYS** store fetched docs separately from main context.
- **Location:** `docs/references/` directory (flat structure)
- **Rationale:** Retrieved only when task explicitly requires that knowledge domain.

**ALWAYS** use filename prefixes for fast filtering.
- **Pattern:** `[category]-[source]-[topic].md`
- **Examples:** `language-rust-ownership.md`, `api-github-auth.md`
- **Rationale:** Enables glob-based discovery without reading file contents.

**ALWAYS** cross-reference related docs with markdown links.
- **Format:** `See [Rust Lifetimes](./language-rust-lifetimes.md) for related concepts`
- **Rationale:** Enables lazy-loading of dependencies only when needed.

**NEVER** inline all external docs into main context.
- **Rationale:** Context saturation reduces agent performance and causes compaction cycles.

</just_in_time_retrieval>

### 4. High-Density Information Formats

**Principle**: Prioritize formats with maximum information per token.

<high_density_formats>

**MANDATORY APPLICATION:**

**ALWAYS** preserve code examples from source documentation.
- **Rationale:** Code examples provide 5-10x information density compared to prose explanations.
- **Format:** Include complete, runnable code blocks with language tags.

**ALWAYS** use tables for structured data.
- **Use cases:** API parameters, configuration options, command flags, data schemas
- **Rationale:** Tables compress multi-dimensional information into scannable format.

**ALWAYS** extract and highlight anti-patterns.
- **Rationale:** Failure prevention provides extremely high value per token.
- **Format:** `**Anti-pattern:** [What to avoid] - [Why incorrect] - [Correct approach]`

**NEVER** retain verbose tutorial walkthroughs.
- **Instead:** Compress to essential steps only (3-5 bullets maximum)
- **Rationale:** Step-by-step prose wastes tokens; key steps provide sufficient guidance.

</high_density_formats>

### 5. Contextual Relevance & Grounding

**Principle**: Connect abstract concepts to concrete project needs.

<contextual_grounding>

**MANDATORY APPLICATION:**

**ALWAYS** include "When To Use" section mapping to project features.
- **Format:** Bullet list linking concepts to specific implementation scenarios
- **Example:** "When implementing zero-copy string handling in HTTP request parsers"
- **Rationale:** Grounds abstract concepts in concrete project contexts.

**ALWAYS** include "Practical Application" section.
- **Content:** Project-specific use cases demonstrating concept application
- **Rationale:** Bridges theory-to-implementation gap, reduces agent uncertainty.

**ALWAYS** link to "Required For" column from context-required.md.
- **Format:** Include table mapping concepts to project requirements
- **Rationale:** Provides purpose justification for why this reference exists.

**NEVER** leave abstract theory ungrounded.
- **Rationale:** Disconnected concepts cannot guide implementation decisions.
- **Fix:** Add at least 1-2 concrete project examples per abstract concept.

</contextual_grounding>

### 6. Avoid Redundancy & Duplication

**Principle**: Single source of truth. Don't duplicate information across files.

<avoid_redundancy>

**MANDATORY APPLICATION:**

**ALWAYS** cross-reference related concepts via markdown links.
- **Format:** `See [Rust Lifetimes](./language-rust-lifetimes.md) for lifetime annotation rules`
- **Rationale:** Enables single source of truth; updates propagate automatically.

**ALWAYS** use `source_url` frontmatter field for re-verification.
- **Purpose:** Provides canonical source without duplicating metadata
- **Rationale:** Future agents can re-fetch updated documentation from source.

**NEVER** copy the same code example into multiple files.
- **Instead:** Link to canonical version or cross-reference related document
- **Rationale:** Reduces maintenance burden and prevents version drift.

**NEVER** repeat background explanations across docs.
- **Instead:** Link to comprehensive version and focus on unique aspects
- **Rationale:** Token efficiency through deduplication.

</avoid_redundancy>

### 7. Token Budget Discipline

**Principle**: Treat tokens as finite resource. Measure cost vs value.

<token_budget_discipline>

**MANDATORY APPLICATION:**

**ALWAYS** estimate token cost before fetching documentation.
- **Decision threshold:** Is this URL worth 2-5K tokens of context budget?
- **Rationale:** Prevent context saturation from low-value documentation.

**ALWAYS** compress verbose content aggressively.
- **Target:** 200-word paragraph → 5 bullet points (80% compression)
- **Rationale:** Maintains information content while reducing token consumption.

**ALWAYS** skip low-value sections during extraction.
- **Skip:** Author biographies, changelogs, historical context, acknowledgments
- **Rationale:** Zero implementation value; pure token waste.

**NEVER** fetch documentation without a compression plan.
- **Rationale:** Uncompressed fetching risks context saturation and agent degradation.
- **Requirement:** Define extraction strategy before MCP query execution.

</token_budget_discipline>

</context_engineering_directives>

---

## PRP Architecture

### File Naming Convention

- Pattern: `[category]-[source]-[topic-slug].md`
- Example: `language-rust-book-ownership.md` (for Rust Book Ownership chapter)
- Example: `api-github-authentication.md` (for GitHub API Authentication docs)
- Example: `build-cargo-workspaces.md` (for Cargo Workspaces docs)

### Storage Location

- `docs/references/` (all fetched references in single flat directory)

### Output Structure

#### YAML Frontmatter

```yaml
---
title: "[Source]: [Specific Topic]"
description: "Fetched from [URL] - [1-sentence summary]"
source_url: "[Full URL]"
source_type: "[official-docs | api-reference | tutorial | guide | specification]"
category: "context-engineering"
subcategory: "[language | build-system | api | database | observability | testing | security]"
version: "1.0"
audience: "llm"
fetch_date: "YYYY-MM-DD"
last_verified: "YYYY-MM-DD"
---
```

#### Overview

[2-3 sentence summary of what this fetched content covers and its relevance to the project]

#### When To Use (This Reference Document is Needed For)

Use this section to specify when agents should load this specific reference document. Map to project features, modules, or tasks that require this knowledge.

Example:

- When implementing [specific feature] that requires [concept from this reference]
- When debugging [specific issue] related to [topic from this reference]
- When the agent needs to understand [specific concept] for [project context]

#### Key Concepts

Main concepts/topics from fetched documentation

#### Context

The most important context/information from fetched documentation. It must include **examples**.

#### Examples

Code examples from fetched documentation, or inferred from the context fetched if the examples aren't provided in the fetched documentation.

#### Practical Application

How this applies specifically to the project.

#### Implementation Notes

Considerations for implementing this reference in the project.

#### Known Gotchas / Anti-Patterns

Common mistakes or limitations from source.

---

## Output

```markdown
---
title: "[Source]: [Specific Topic]"
description: "Fetched from [URL] - [1-sentence summary]"
source_url: "[Full URL]"
source_type: "[official-docs | api-reference | tutorial | guide | specification]"
category: "context-engineering"
subcategory: "[language | build-system | api | database | observability | testing | security]"
version: "1.0"
audience: "llm"
fetch_date: "YYYY-MM-DD"
last_verified: "YYYY-MM-DD"
---

# [Topic Title from Source]

## Overview

[2-3 sentence summary of what this fetched content covers and its relevance to the project]

---

## When To Use (This Reference Document is Needed For)

Use this section to specify when agents should load this specific reference document. Map to project features, modules, or tasks that require this knowledge.

Example:

- When implementing [specific feature] that requires [concept from this reference]
- When debugging [specific issue] related to [topic from this reference]
- When the agent needs to understand [specific concept] for [project context]

| Load this Reference When | Section (Anchor Link) | Required For |
|---------------------------|------------------------|--------------|
| [Project feature/module or specific task] | [#section-title](./file.md#section-title) | [Why needed - map to "Required For" column] |

---

## Key Concepts

[Main concepts/topics from fetched documentation]

---

## Context

### [Context 1]

[Explanation/content from fetched documentation]

**Code Example** (if applicable):

```[language]
[code snippet from source]
```

**Key Takeaways**:

- [Bullet 1]
- [Bullet 2]

### [Context 2]

[Explanation/content from fetched documentation]

**Code Example** (if applicable):

```[language]
[code snippet from source]
```

**Key Takeaways**:

- [Bullet 1]
- [Bullet 2]

---

## Examples

Code examples from fetched documentation, or inferred from the context fetched if the examples aren't provided in the fetched documentation.

---

## Practical Application

How this applies specifically to the project.

**Implementation Notes**:

Considerations for implementing this reference in the project.

---

## Known Gotchas / Anti-Patterns

Common mistakes or limitations from source.

- **[Anti-pattern]**: [Why avoid, correct approach]
- **[Gotcha]**: [Explanation and workaround]

---

## Related References

- [Related fetched content doc]
- [Cross-reference to context-required.md]

```

---

## Content Extraction Guidelines

<content_extraction_protocol>

**MANDATORY EXTRACTION** (high signal - always include):

**ALWAYS extract** these elements from source documentation:
- **Code examples** (complete, runnable snippets with language tags)
  - **Rationale:** 5-10x information density vs. prose
- **Key takeaways** (compress to bullet points for fast scanning)
  - **Rationale:** Enables rapid comprehension without full paragraph reads
- **Anti-patterns and gotchas** (failure prevention guidance)
  - **Rationale:** Highest value per token for preventing implementation errors
- **Practical applications** (project-specific use cases)
  - **Rationale:** Grounds abstract concepts in concrete implementation contexts

**MANDATORY COMPRESSION** (reduce prose - always apply):

**ALWAYS compress** verbose content using these transformations:
- **Verbose explanations** → Concise bullet points (target 80% reduction)
- **Tutorial walkthroughs** → Essential steps only (3-5 bullets maximum)
- **Background theory** → Core principles only (skip historical context)

**Rationale:** Maintains information content while dramatically reducing token consumption.

**MANDATORY EXCLUSION** (low signal - never include):

**NEVER include** these low-value elements:
- **Marketing content** (product promotions, sales language)
- **Redundant examples** (keep 1-2 canonical cases only)
- **Non-technical preambles** (author bios, acknowledgments, disclaimers)
- **Historical context** (version history, deprecated approaches)

**Rationale:** Zero implementation value; pure token waste.

</content_extraction_protocol>

### MCP Server Priority for Web Fetching

<mcp_server_selection>

**MANDATORY:** When fetching documentation, **ALWAYS follow this priority hierarchy** (BLOCKING - do not skip tiers):

**Rationale:** Tier-based selection ensures optimal performance (500% faster via caching), structured output (official sources), and reliability (maintained APIs).

**Tier 1: Specialized MCP Servers** (MUST use FIRST if domain matches)

- **AWS Documentation**: `mcp__awslabs-aws-documentation-mcp-server`
  - **Tools:** `search_documentation`, `read_documentation`, `recommend`
  - **MUST use for:** AWS service docs, CloudFormation, CDK, AWS CLI
  - **Benefit:** Official source, structured markdown, 500% faster via caching

- **Microsoft/Azure Docs**: `mcp__microsoft-docs-mcp`
  - **Tools:** `microsoft_docs_search`, `microsoft_docs_fetch`, `microsoft_code_sample_search`
  - **MUST use for:** Azure services, .NET, Microsoft 365, PowerShell
  - **Benefit:** Official code samples, breadth+depth workflow, comprehensive coverage

- **Context7**: `mcp__context7`
  - **Tools:** `resolve-library-id`, `get-library-docs`
  - **MUST use for:** JavaScript/Python/Go library documentation
  - **Benefit:** Up-to-date package docs, version-specific content, maintained APIs

- **Cloudflare Docs**: `mcp__cloudflare`
  - **Tools:** `search_cloudflare_documentation`
  - **MUST use for:** Cloudflare Workers, Pages, R2, D1, Zero Trust
  - **Benefit:** Official Cloudflare product documentation, current API references

**Tier 2: General Web Scraping** (USE if Tier 1 not applicable)

- **Firecrawl MCP**: `mcp__firecrawl-mcp__firecrawl_scrape` (primary Tier 2 tool)
  - **USE for:** Single page content extraction with markdown conversion
  - **Benefit:** Most powerful scraper, fastest, most reliable, clean markdown output
  - **Recommended options:** `formats: ["markdown"]`, `onlyMainContent: true`, `maxAge: 172800000` (2-day cache)
  - **Example configuration:**
    ```json
    {
      "url": "https://doc.rust-lang.org/book/ch04-00-understanding-ownership.html",
      "formats": ["markdown"],
      "onlyMainContent": true,
      "maxAge": 172800000
    }
    ```

- **Firecrawl Search**: `mcp__firecrawl-mcp__firecrawl_search` (when URL unknown)
  - **USE for:** Finding specific information across multiple websites
  - **Workflow:** Search first (without formats), then scrape relevant pages
  - **Example configuration:**
    ```json
    {
      "query": "Rust ownership borrowing lifetimes",
      "limit": 5,
      "sources": ["web"]
    }
    ```

- **Brave Search**: `mcp__brave-search__brave_web_search` (alternative search)
  - **USE for:** General queries, recent events, diverse web sources
  - **Options:** `count: 10`, `offset: 0` (pagination support)
  - **Example configuration:**
    ```json
    {
      "query": "Terraform AWS VPC module best practices",
      "count": 5
    }
    ```

**Tier 3: Built-in Fallback** (USE ONLY if MCP unavailable)

- **WebFetch Tool**: Claude's built-in web fetching (converts HTML to markdown)
  - **USE for:** When MCP servers unavailable or rate-limited
  - **Limitation:** May have restrictions, 15-min cache, lower reliability
  - **Example:**
    ```
    WebFetch("https://example.com/docs", "Extract key concepts and code examples")
    ```

**Decision Logic** (MANDATORY sequence - execute in order, BLOCKING):

<mcp_decision_tree>

**EXECUTE these checks in sequence** (stop at first match):

1. **Domain match found?** → **MUST USE** Tier 1 specialized MCP (AWS/Azure/Context7/Cloudflare)
   - **Rationale:** Official sources provide highest reliability and structured output

2. **Known URL provided?** → **MUST USE** `firecrawl_scrape` (Tier 2)
   - **Rationale:** Direct scraping is fast, reliable, and produces clean markdown

3. **Unknown URL (search needed)?** → **MUST USE** `firecrawl_search` or `brave_web_search` (Tier 2), **THEN** scrape results
   - **Rationale:** Search-then-scrape workflow ensures relevant content discovery

4. **MCP unavailable?** → **FALLBACK to** `WebFetch` (Tier 3)
   - **Rationale:** Last resort when specialized tools unavailable

**NEVER skip tiers** - this hierarchy ensures optimal performance and reliability.

</mcp_decision_tree>

**Best Practices** (MANDATORY application):

- **ALWAYS prefer Firecrawl over WebFetch** when available
  - **Rationale:** 5-10x more reliable, cleaner output, better markdown conversion

- **ALWAYS use `onlyMainContent: true`** to filter navigation/footer noise
  - **Rationale:** Reduces token waste from boilerplate content

- **ALWAYS enable caching** (`maxAge: 172800000`) for faster re-fetches
  - **Rationale:** 500% performance improvement on repeated queries

- **ALWAYS scrape first, then compress** - get raw content, then apply Content Extraction Guidelines
  - **Rationale:** Enables informed compression decisions based on complete source

- **ALWAYS cite source URL** in frontmatter (`source_url` field)
  - **Rationale:** Enables re-verification and future updates

</mcp_server_selection>

---

## File Organization Patterns

**Naming Convention**:

- `language-rust-book-ownership.md` (Rust Book: Ownership chapter)
- `api-github-authentication.md` (GitHub API: Authentication docs)
- `build-cargo-workspaces.md` (Cargo: Workspaces docs)

**Storage Location**:

- **Directory**: `docs/references/` (single flat directory, no subdirectories)
- **Path**: `/Users/304339/Documents/code/personal-src/gloton/docs/references/`
- **Structure**: Flat list of all fetched reference documents
- **Discovery**: Use category prefix in filename for filtering (e.g., `language-*`, `api-*`, `build-*`)

---

## Cross-Referencing Protocol

**Bidirectional Links**:

- Link TO: context-required.md entry that triggered fetch
- Link FROM: Related fetched docs in same category
- Use relative paths for portability

**Example**:

```markdown
## Related References

- [Rust Lifetimes](language-rust-book-lifetimes.md) (related concept - same directory)
- [Context Required: Language Fundamentals](../00_init/03-context-required.md#language-fundamentals) (source table)
```

---

## Versioning & Freshness Strategy

**Version Tracking**:

- `version: "1.0"` → Template structure version
- Increment when source changes significantly
- Document changes in description field

**Freshness Tracking**:

- `fetch_date` → Initial content capture date
- `last_verified` → Last accuracy check date
- Update `last_verified` during periodic reviews

---

## Implementation Example

<implementation_protocol>

**Scenario**: Agent needs to fetch <https://doc.rust-lang.org/book/ch04-00-understanding-ownership.html>

**EXECUTE these steps in sequence** (BLOCKING - complete each before proceeding to next):

### Step 1: Trigger Detection

**WHEN:** Agent encounters URL pattern or reference request in user input

**ACTION:** Load this PRP template immediately

**Rationale:** Ensures consistent execution across all documentation fetching tasks

---

### Step 2: Protocol Loading Announcement

**WHAT:** Display loading announcement to user for observability

**EXECUTE:**

```text
📖 Loading PRP: prp-references-fetch.md for [URL]
```

**Rationale:** User observability into agent's decision-making process

---

### Step 3: File Creation

**WHERE:** Create file at `docs/references/[category]-[source]-[topic-slug].md`

**MUST include:** All mandatory frontmatter fields (title, description, source_url, source_type, category, subcategory, version, audience, fetch_date, last_verified)

**Example for Rust Ownership documentation:**

```markdown
---
title: "Rust Book: Ownership"
description: "Fetched from Rust Book Ch04 - Memory safety without GC"
source_url: "https://doc.rust-lang.org/book/ch04-00-understanding-ownership.html"
source_type: "official-docs"
category: "context-engineering"
subcategory: "language"
version: "1.0"
audience: "llm"
fetch_date: "2025-11-17"
last_verified: "2025-11-17"
---

# Ownership

## Overview

Memory safety without garbage collection through Rust's ownership system, including borrowing rules and move semantics.

---

## When To Use (This Reference Document is Needed For)

- When implementing string handling with zero-copy optimizations
- When designing buffer reuse patterns for high-performance code
- When the agent needs ownership and borrowing rules for Rust development

| Load this Reference When | Section (Anchor Link) | Required For |
|---------------------------|------------------------|--------------|
| Implementing zero-copy string operations | [#context](./language-rust-book-ownership.md#context) | String handling, buffer management |

---

## Key Concepts

[Ownership rules, borrowing, move semantics - main concepts from Rust Book]

[... rest of structured content following template ...]
```

**Rationale:** Complete frontmatter enables traceability, versioning, and future re-verification

---

### Step 4: Content Fetching

**EXECUTE:** MCP server priority hierarchy (Tier 1 → 2 → 3)

**For this example:**

1. **Check Tier 1:** No Rust-specific MCP → Skip to Tier 2
2. **USE Tier 2:** `firecrawl_scrape` with options:

   ```json
   {
     "url": "https://doc.rust-lang.org/book/ch04-00-understanding-ownership.html",
     "formats": ["markdown"],
     "onlyMainContent": true,
     "maxAge": 172800000
   }
   ```

**APPLY:** Content Extraction Guidelines

- **Extract:** Code examples, key concepts, anti-patterns
- **Compress:** Verbose explanations → bullet points (target 80% reduction)
- **Skip:** Navigation, footer, author bio, historical context

**TARGET:** 200-500 tokens per major section

**Rationale:** Structured fetching ensures high signal-to-noise ratio and optimal token efficiency

---

### Step 5: Verification

**EXECUTE:** Verify file creation and content quality

**Commands:**

```bash
# Verify file exists
ls -lh /Users/304339/Documents/code/personal-src/gloton/docs/references/language-rust-book-ownership.md

# Verify file size (typical range: 1KB - 50KB)
du -h /Users/304339/Documents/code/personal-src/gloton/docs/references/language-rust-book-ownership.md
```

**CONFIRM:**

- ✅ File exists at correct path
- ✅ File size reasonable (>1KB, <50KB typical)
- ✅ All mandatory frontmatter fields present
- ✅ Content follows template structure
- ✅ Code examples preserved with language tags
- ✅ Key concepts extracted and compressed

**DISPLAY:** Success message with file path to user

**Rationale:** Verification prevents silent failures and ensures deliverable quality

</implementation_protocol>

---
