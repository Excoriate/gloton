---
title: "Cursor Rules Location Management"
description: "Enforce consistent file location, naming conventions, and organizational structure for cursor rules within .cursor/rules directory"
globs: ["**/*.mdc", ".cursor/rules/**"]
alwaysApply: true
---

# Cursor Rules Location Management

## Description

Enforce consistent location and organization of all cursor rules within the `.cursor/rules` directory. This rule ensures systematic file management, proper naming conventions, and centralized rule governance for optimal cursor IDE integration and team collaboration. For content quality and MDC format standards, see [cursor-create-new-rules.md](./cursor-create-new-rules.md).

## Rule

Execute this mandatory protocol for all cursor rule file organization and management:

1. **Directory Structure Enforcement**: Create all cursor rules exclusively in `.cursor/rules/` directory
2. **File Naming Standards**: Use kebab-case naming convention: `[rule-name].mdc`
3. **File Extension Compliance**: Apply `.mdc` extension to all cursor rule files
4. **Individual File Separation**: Maintain one rule per file for modular management
5. **Version Control Integration**: Ensure all rules are tracked and documented in repository
6. **Access Control**: Validate file permissions and accessibility
7. **Naming Descriptiveness**: Use clear, purpose-indicating rule names that reflect functionality
8. **Path Validation**: Ensure all file paths are accessible and follow project conventions

## Implementation

**Cursor IDE Integration:**

- Global application (`alwaysApply: true`) ensures continuous enforcement across all file operations
- File pattern matching targets both `.mdc` files and `.cursor/rules/` directory structure
- Real-time validation prevents rule creation outside designated directory
- Automatic suggestions for proper naming conventions and file placement

**Technical Enforcement:**

- Directory structure validation before rule creation
- File extension verification during save operations
- Naming convention compliance checking
- File system accessibility validation
- Path verification and correction suggestions

**Automated Workflow Integration:**

- IDE prompts for proper rule location during creation
- Template generation with pre-populated directory paths
- File organization suggestions based on rule purpose
- Conflict resolution for duplicate rule names
- Migration assistance for misplaced rule files

## Benefits

### Organization & Maintainability

1. **Centralized Management**: Single directory location simplifies rule discovery and maintenance
2. **Predictable Structure**: Consistent organization reduces cognitive load for team members
3. **Scalable Architecture**: Systematic approach supports growing rule repositories
4. **Version Control Clarity**: Clear file organization improves change tracking and reviews

### Team Collaboration

5. **Standardized Workflow**: Uniform rule file management process across all team members
6. **Enhanced Discoverability**: Centralized location enables quick rule identification
7. **Conflict Prevention**: Systematic naming prevents duplicate or conflicting rule files
8. **Knowledge Transfer**: New team members can quickly understand rule file organization

### Technical Excellence

9. **IDE Optimization**: Proper file structure maximizes cursor IDE performance and features
10. **Integration Readiness**: Standardized file organization supports automated tooling and scripts
11. **Error Reduction**: Consistent file structure minimizes configuration and deployment errors
12. **Future-Proofing**: Systematic file organization accommodates rule system evolution

## Examples

### ✅ Correct File Organization

**Proper Directory Structure:**

```
project-root/
├── .cursor/
│   └── rules/                    ✅ Centralized rules directory
│       ├── api-validation.mdc    ✅ Kebab-case naming
│       ├── code-formatting.mdc   ✅ Descriptive purpose
│       ├── security-headers.mdc  ✅ Clear functionality
│       ├── typescript-rules.mdc  ✅ Technology-specific
│       └── documentation.mdc     ✅ Consistent extension
└── [other project files]
```

**File Naming Conventions:**

```
✅ CORRECT NAMING:
├── typescript-standards.mdc       # Technology + purpose
├── security-authentication.mdc   # Domain + function
├── documentation-metadata.mdc     # Type + specification
└── build-optimization.mdc        # Process + goal

✅ DESCRIPTIVE PATTERNS:
├── [technology]-[purpose].mdc     # e.g., react-hooks.mdc
├── [domain]-[function].mdc        # e.g., api-versioning.mdc
├── [process]-[goal].mdc           # e.g., test-coverage.mdc
└── [feature]-[requirement].mdc    # e.g., auth-tokens.mdc
```

### ❌ Incorrect File Organization

**Problematic Directory Structures:**

```
❌ SCATTERED PLACEMENT:
project-root/
├── .cursor/
│   ├── rules/
│   │   └── some-rule.mdc
│   └── other-config/
│       └── another-rule.mdc      # ❌ Wrong location
├── docs/
│   └── cursor-rules.mdc          # ❌ Outside .cursor/
└── rules/
    └── legacy-rule.mdc           # ❌ Wrong directory

❌ NAMING VIOLATIONS:
├── .cursor/rules/
│   ├── MyRule.mdc                # ❌ PascalCase instead of kebab-case
│   ├── api_validation.mdc        # ❌ Snake_case instead of kebab-case
│   ├── rule1.mdc                 # ❌ Non-descriptive naming
│   ├── temp.mdc                  # ❌ Temporary/unclear purpose
│   └── SECURITY.MDC              # ❌ All caps, wrong extension case
```

### 🔧 File Organization Patterns

**Migration Commands:**

```bash
# ✅ Correct migration process
mv cursor-rule.mdc .cursor/rules/api-standards.mdc
mv legacy-rules/*.mdc .cursor/rules/
find . -name "*.mdc" -not -path "./.cursor/rules/*" -exec mv {} .cursor/rules/ \;
```

**Validation Commands:**

```bash
# ✅ Verify rule location compliance
find .cursor/rules/ -name "*.mdc" -type f | wc -l    # Count rules
ls -la .cursor/rules/                                # Verify structure
find . -name "*.mdc" -not -path "./.cursor/rules/*"  # Find misplaced rules
```

**Directory Structure Validation:**

```
✅ COMPLIANT STRUCTURE:
.cursor/
└── rules/              # Single, centralized location
    ├── *.mdc          # All rules in designated directory
    └── [subdirs]/     # Optional categorization (if needed)
        └── *.mdc      # Organized by domain/technology

❌ NON-COMPLIANT PATTERNS:
├── .cursor/custom/rules/     # Extra nesting
├── cursor-rules/             # Wrong directory name
├── .vscode/rules/            # Wrong IDE directory
└── docs/cursor/              # Mixed with documentation
```

**File Organization Checklist:**

```
File Organization Validation/
├── All .mdc files in .cursor/rules/ directory ✅
├── Kebab-case naming convention followed ✅
├── Descriptive, purpose-indicating file names ✅
├── No duplicate or conflicting rule files ✅
├── Proper file extensions (.mdc) ✅
├── Files accessible and readable ✅
└── Cross-references between related rules ✅
```
