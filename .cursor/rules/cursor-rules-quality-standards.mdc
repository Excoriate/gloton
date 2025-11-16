---
title: "Cursor Rule Content Standards"
description: "Enforce comprehensive content quality standards for cursor rules including MDC format compliance, YAML frontmatter structure, and technical writing precision"
globs: ["**/*.mdc", ".cursor/rules/**"]
alwaysApply: true
---

# Cursor Rule Content Standards

## Description

This rule enforces comprehensive content quality standards for cursor rules that follow MDC (Model-Driven Code) format specifications. It ensures consistency, completeness, and technical precision in cursor rule content, covering YAML frontmatter structure, content organization, language precision, and quality validation. For file location and organization requirements, see [cursor-rules-location.mdc](cursor-rules-location.mdc).

## Rule

Create cursor rules with proper MDC format:

1. **YAML Frontmatter**: Include `description`, `globs`, `alwaysApply` fields with correct syntax
2. **Required Sections**: Description → Rule → Implementation → Benefits → Examples
3. **Direct Language**: Use imperative commands ("Execute", "Create", "Validate")
4. **Relative Paths**: Never use absolute paths in rule content
5. **Validate Syntax**: Check YAML and markdown formatting before saving

## Implementation

**Cursor IDE Integration:**
- Real-time YAML/markdown syntax validation
- Template generation for required sections
- Content quality checks during editing

**Technical Enforcement:**
- YAML syntax validation
- Markdown linting
- Section completeness verification

## Benefits

1. **Consistency**: Uniform structure across all cursor rules
2. **Quality**: Production-ready technical documentation
3. **Completeness**: All required sections present and validated
4. **Maintainability**: Clear structure with comprehensive examples

## Examples

### ✅ Correct Content Implementation

**YAML Frontmatter Example:**
```yaml
---
description: "Enforce TypeScript coding standards and best practices"
globs: ["**/*.ts", "**/*.tsx"]
alwaysApply: false
---
```

**Section Structure Example:**
```markdown
# Rule Title
## Description
## Rule
## Implementation
## Benefits
## Examples
```

### ❌ Incorrect Content Implementation

**Malformed Cursor Rule Content:**

```markdown
description: TypeScript rule
globs: *.ts
---

# TypeScript

This rule is about TypeScript...

## Some Requirements
- Maybe use types
- Could be good to check things
```

**Content Problems Identified:**
```
Content Issues/
├── Invalid YAML frontmatter syntax
├── Missing required fields (alwaysApply)
├── Incomplete content structure (missing Implementation, Benefits, Examples)
├── Vague language ("maybe", "could be")
├── No specific, actionable requirements
└── Missing technical precision and clarity
```

### 🔧 MDC Content Format Reference

**Complete YAML Frontmatter Example:**
```yaml
---
description: "Brief, actionable description of rule purpose and scope"
globs: ["**/*.ts", "**/*.tsx", "src/**/*.js"]  # Array format for multiple patterns
alwaysApply: true  # Boolean for global application
---
```

**Required Section Order:**
```
1. Description - Clear purpose and scope
2. Rule - Numbered, specific requirements
3. Implementation - Technical enforcement details
4. Benefits - Organizational advantages
5. Examples - Correct/incorrect patterns
```

**Content Quality Checklist:**
```
Content Validation/
├── YAML frontmatter syntax validation ✅
├── Required sections present ✅
├── Language precision maintained ✅
├── Technical terms clearly defined ✅
├── Examples include both correct/incorrect patterns ✅
├── ASCII diagrams render properly ✅
└── Cross-references to related rules ✅
```
