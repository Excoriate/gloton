use clap::Parser;

#[derive(Debug, Parser)]
#[command(
    name = "gloton",
    version,
    about = "Organize repository collections across Git hosting platforms",
    long_about = None,
    arg_required_else_help = true
)]
struct Cli {}

fn main() {
    Cli::parse();
}
