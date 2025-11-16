mod cli;

use clap::Parser;
use cli::{Cli, Commands};

fn main() {
  let cli = Cli::parse();

  match cli.command {
    Commands::Hello { name } => {
      let greeting = match name {
        Some(n) => format!("Hello, {}!", n),
        None => "Hello, World!".to_string(),
      };
      println!("{}", greeting);
    }
  }
}
