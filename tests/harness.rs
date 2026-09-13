use std::collections::BTreeSet;
use std::fs;
use std::path::{Path, PathBuf};

const CORE_SOURCES: &[&str] = &[
    ".ai/harness/AGENTS.md",
    ".ai/harness/rules/RULES.md",
    ".ai/harness/CONTEXT.md",
];

const CORE_CARRIERS: &[&str] = &[
    "AGENTS.md",
    "CLAUDE.md",
    ".github/copilot-instructions.md",
    ".cursor/rules/harness-core-context.mdc",
    ".agents/rules/harness-core-context.md",
];

const RULES: &[&str] = &[
    "governance/memory-freshness",
    "governance/rules-codebase-sync",
    "governance/ddd-freshness",
    "governance/root-files-freshness",
    "governance/specs-driven",
    "governance/anchor-context-startup",
    "governance/harness-self-improvement",
    "governance/anti-slop-gate",
    "governance/change-impact-review",
    "governance/adversarial-dispatch-discipline",
    "governance/actionable-artifact-gate",
    "rust/cli-clap",
];

const SKILL_CARRIERS: &[&str] = &[
    ".claude/skills/cbharness-capture-adr/SKILL.md",
    ".cursor/skills/cbharness-capture-adr/SKILL.md",
    ".codex/skills/cbharness-capture-adr/SKILL.md",
    ".omp/skills/cbharness-capture-adr/SKILL.md",
    ".pi/skills/cbharness-capture-adr.md",
];

fn root() -> PathBuf {
    PathBuf::from(env!("CARGO_MANIFEST_DIR"))
}

fn read(relative: &str) -> Vec<u8> {
    fs::read(root().join(relative)).unwrap_or_else(|error| panic!("{relative}: {error}"))
}

fn generated_rule_paths() -> BTreeSet<String> {
    let mut found = BTreeSet::new();
    for directory in [
        ".claude/rules",
        ".cursor/rules",
        ".github/instructions",
        ".omp/rules",
        ".agents/rules",
    ] {
        collect_rule_files(&root().join(directory), &root(), &mut found);
    }
    found
}

fn collect_rule_files(directory: &Path, repository: &Path, found: &mut BTreeSet<String>) {
    for entry in
        fs::read_dir(directory).unwrap_or_else(|error| panic!("{}: {error}", directory.display()))
    {
        let path = entry
            .expect("rule directory entry should be readable")
            .path();
        if path.is_dir() {
            collect_rule_files(&path, repository, found);
            continue;
        }
        found.insert(
            path.strip_prefix(repository)
                .expect("rule file should be inside repository")
                .to_string_lossy()
                .replace('\\', "/"),
        );
    }
}

fn expected_rule_paths() -> BTreeSet<String> {
    let mut expected = BTreeSet::from([
        ".agents/rules/cbharness-verification-surface.md".to_owned(),
        ".agents/rules/harness-core-context.md".to_owned(),
        ".claude/rules/cbharness-verification-surface.md".to_owned(),
        ".cursor/rules/harness-core-context.mdc".to_owned(),
    ]);
    for rule in RULES {
        let (namespace, name) = rule.split_once('/').expect("rule should be namespaced");
        expected.insert(format!(".claude/rules/{namespace}/{name}.md"));
        expected.insert(format!(".cursor/rules/{namespace}-{name}.mdc"));
        expected.insert(format!(
            ".github/instructions/{namespace}-{name}.instructions.md"
        ));
        expected.insert(format!(".omp/rules/{namespace}-{name}.md"));
        expected.insert(format!(".agents/rules/{namespace}-{name}.md"));
    }
    expected
}

fn assert_payload(carrier: &str, canonical: &str, marker_kind: &str) {
    let wrapper = read(carrier);
    let canonical_bytes = read(canonical);
    let source_marker = format!("<!-- Centralized {marker_kind}: {canonical} -->");
    assert!(
        wrapper
            .windows(source_marker.len())
            .any(|window| window == source_marker.as_bytes()),
        "{carrier} does not point to {canonical}"
    );
    let payload_marker = b"<!-- Canonical payload begins -->\n";
    let marker_index = wrapper
        .windows(payload_marker.len())
        .position(|window| window == payload_marker)
        .unwrap_or_else(|| panic!("{carrier} has no canonical payload marker"));
    assert_eq!(
        &wrapper[marker_index + payload_marker.len()..],
        canonical_bytes,
        "{carrier} payload drifted from {canonical}"
    );
}

#[test]
fn core_carriers_embed_all_three_canonical_sources() {
    for carrier in CORE_CARRIERS {
        let bytes = read(carrier);
        for source in CORE_SOURCES {
            let canonical = read(source);
            let start_prefix = format!("<!-- core-source: {source} sha256=");
            let start = bytes
                .windows(start_prefix.len())
                .position(|window| window == start_prefix.as_bytes())
                .unwrap_or_else(|| panic!("{carrier} does not identify {source}"));
            let body_start = bytes[start..]
                .iter()
                .position(|byte| *byte == b'\n')
                .map(|offset| start + offset + 1)
                .expect("core source marker should end with newline");
            let end_marker = format!("<!-- core-end: {source} -->");
            let body_end = bytes[body_start..]
                .windows(end_marker.len())
                .position(|window| window == end_marker.as_bytes())
                .map(|offset| body_start + offset)
                .unwrap_or_else(|| panic!("{carrier} does not close {source}"));
            assert_eq!(
                &bytes[body_start..body_end],
                canonical.as_slice(),
                "{carrier} embedded stale bytes for {source}"
            );
        }
    }
}

#[test]
fn detailed_rule_inventory_and_payloads_match_canonical_sources() {
    assert_eq!(generated_rule_paths(), expected_rule_paths());
    for rule in RULES {
        let (namespace, name) = rule.split_once('/').expect("rule should be namespaced");
        let canonical = format!(".ai/harness/rules/{rule}.md");
        for carrier in [
            format!(".claude/rules/{namespace}/{name}.md"),
            format!(".cursor/rules/{namespace}-{name}.mdc"),
            format!(".github/instructions/{namespace}-{name}.instructions.md"),
            format!(".omp/rules/{namespace}-{name}.md"),
            format!(".agents/rules/{namespace}-{name}.md"),
        ] {
            assert_payload(&carrier, &canonical, "rule");
        }
    }
}

#[test]
fn root_carriers_route_canonical_owners_and_existing_hooks() {
    const CANONICAL_OWNER_TEXT: &str =
        "Edit the smallest applicable canonical owner under `.ai/harness`; never edit a carrier.";
    const RECENCY_ECHO: &str =
        "Gloton normal work uses the root `Justfile`; completion requires `just ci`.";

    for carrier in ["AGENTS.md", "CLAUDE.md"] {
        let text = String::from_utf8(read(carrier)).expect("root carrier should be UTF-8");
        assert!(
            text.contains(CANONICAL_OWNER_TEXT),
            "{carrier} owner route drifted"
        );
        assert!(
            text.contains(RECENCY_ECHO),
            "{carrier} recency echo drifted"
        );
        assert!(
            !text.contains("Edit `.ai/harness/AGENTS.md` instead"),
            "{carrier} collapses distinct canonical owners"
        );
    }

    let claude = String::from_utf8(read("CLAUDE.md")).expect("CLAUDE.md should be UTF-8");
    for removed_hook in ["session-start.sh", "refresh-repo-structure.sh"] {
        assert!(
            !claude.contains(removed_hook),
            "CLAUDE.md references absent hook {removed_hook}"
        );
    }
}

#[test]
fn built_in_skill_payload_matches_every_declared_carrier() {
    let canonical = ".ai/harness/skills/cbharness-capture-adr.md";
    for carrier in SKILL_CARRIERS {
        assert_payload(carrier, canonical, "skill");
    }
}
