---
title: "[Source]: [Specific Topic/Chapter]"
description: "Fetched content from [URL] - [Brief 1-sentence summary]"
source_url: "[Full URL of fetched content]"
source_type: "[official-docs | api-reference | tutorial | guide | specification]"
category: "context-engineering"
subcategory: "[language | build-system | api | database | observability | testing | security]"
version: "1.0"
audience: "llm"
fetch_date: "YYYY-MM-DD"
last_verified: "YYYY-MM-DD"
---

# [Topic Title from Source]

**Source**: [Reference name from context-required.md]
**URL**: <[Original URL]>
**Context**: [Why this content is needed - map to "Required For" column from context-required.md]
**Use this Reference When**: [Specific project feature/module where this applies]

---

## Overview

[2-3 sentence summary of what this fetched content covers and its relevance to the project]

---

## Key Concepts

### [Concept 1]

[Explanation/content from fetched documentation]

**Code Example** (if applicable):

```[language]
[code snippet from source]
```

**Key Takeaways**:

- [Bullet point 1]
- [Bullet point 2]

### [Concept 2]

[Explanation/content from fetched documentation]

**Code Example** (if applicable):

```[language]
[code snippet from source]
```

**Key Takeaways**:

- [Bullet point 1]
- [Bullet point 2]

---

## Practical Application

**Use Cases**:

- [Specific project feature/module where this applies]
- [Another application scenario]

**Implementation Notes**:

- [Consideration 1]
- [Consideration 2]

---

## Important Gotchas / Anti-Patterns

- **[Anti-pattern name]**: [Why to avoid, correct approach]
- **[Gotcha/limitation]**: [Explanation and workaround]

---

## Related References

- [Link to related fetched content doc in same category]
- [Cross-reference to another section in context-required.md]

---

## Template Usage Guidelines

**Purpose**: This template structures fetched web content from external URLs listed in the project's context-required reference document. Each URL gets its own document using this template.

**File Naming Convention**:

- Pattern: `[category]-[source]-[topic-slug].md`
- Example: `language-rust-book-ownership.md` (for Rust Book Ownership chapter)
- Example: `api-github-authentication.md` (for GitHub API Authentication docs)
- Example: `build-cargo-workspaces.md` (for Cargo Workspaces docs)

**Storage Location**:

- `docs/00_context_engineering/02_fetched_content/[subcategory]/`
- Example: `docs/00_context_engineering/02_fetched_content/language/language-rust-book-ownership.md`
- Example: `docs/00_context_engineering/02_fetched_content/api/api-github-authentication.md`

**YAML Frontmatter Fields**:

- `title`: "[Source Name]: [Specific Topic]" (e.g., "Rust Book: Ownership")
- `description`: One-sentence summary with URL mention
- `source_url`: Full URL of fetched content (for re-verification)
- `source_type`: official-docs, api-reference, tutorial, guide, specification
- `subcategory`: Maps to categories in context-required.md (language, build-system, api, etc.)
- `fetch_date`: When content was originally fetched
- `last_verified`: When content was last checked for accuracy (update during reviews)

**Content Structure Guidelines**:

1. **Header Block**: Links back to source and context (why needed)
2. **Overview**: Brief summary (2-3 sentences) of fetched content scope
3. **Key Concepts**: Main sections from fetched content
   - Use H3 headers for each major concept
   - Include code examples where relevant
   - Extract key takeaways as bullet points
4. **Practical Application**: How this applies specifically to the project
5. **Gotchas/Anti-Patterns**: Common mistakes or limitations from source
6. **Related References**: Cross-links to other fetched docs

**Content Extraction Approach**:

- **Don't copy entire pages verbatim** - extract relevant sections
- **Focus on LLM-consumable structure** - clear hierarchy, code examples, bullet points
- **Preserve code examples** - these are high-signal for implementation
- **Summarize prose** - condense paragraphs into key takeaways
- **Add project context** - connect abstract concepts to specific project needs

**Versioning Strategy**:

- `version` field tracks template iteration (this is v1.0)
- `last_verified` tracks content freshness (update when re-checking source)
- If source content changes significantly, increment version and note changes

**Cross-Referencing**:

- Link back to context-required.md table entry that triggered this fetch
- Link to related fetched content docs in same category
- Use relative paths for portability
