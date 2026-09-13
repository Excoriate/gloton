use std::process::{Command, Output};

fn gloton(args: &[&str]) -> Output {
    Command::new(env!("CARGO_BIN_EXE_gloton"))
        .args(args)
        .output()
        .expect("gloton binary should run")
}

#[test]
fn help_is_the_complete_current_command_surface() {
    let output = gloton(&["--help"]);

    assert!(output.status.success());
    assert!(output.stderr.is_empty());
    assert_eq!(
        String::from_utf8_lossy(&output.stdout),
        concat!(
            "Organize repository collections across Git hosting platforms\n",
            "\n",
            "Usage: gloton\n",
            "\n",
            "Options:\n",
            "  -h, --help     Print help\n",
            "  -V, --version  Print version\n",
        )
    );
}

#[test]
fn version_uses_the_package_identity() {
    let output = gloton(&["--version"]);

    assert!(output.status.success());
    assert!(output.stderr.is_empty());
    assert_eq!(String::from_utf8_lossy(&output.stdout), "gloton 0.1.0\n");
}

#[test]
fn missing_input_is_rejected_with_usage() {
    let output = gloton(&[]);

    assert_eq!(output.status.code(), Some(2));
    assert!(output.stdout.is_empty());
    assert!(String::from_utf8_lossy(&output.stderr).contains("Usage: gloton"));
}

#[test]
fn unimplemented_commands_are_rejected() {
    let output = gloton(&["sync"]);

    assert_eq!(output.status.code(), Some(2));
    assert!(output.stdout.is_empty());
    let stderr = String::from_utf8_lossy(&output.stderr);
    assert!(stderr.contains("unexpected argument 'sync'"));
    assert!(stderr.contains("Usage: gloton"));
}
