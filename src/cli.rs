use clap::{Parser, Subcommand};

#[derive(Parser)]
#[command(name = "gloton")]
#[command(version, about = "A simple CLI tool", long_about = None)]
pub struct Cli {
  #[command(subcommand)]
  pub command: Commands,
}

#[derive(Subcommand)]
pub enum Commands {
  /// Say hello to the world
  Hello {
    /// Optional name to greet
    #[arg(short, long)]
    name: Option<String>,
  },
}
