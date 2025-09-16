# Shlex - Shell-like Lexical Analysis for MoonBit

<div align="right">
  <strong>Language:</strong> 
  English | <a href="README_zh_CN.md">中文</a>
</div>

[![License](https://img.shields.io/badge/license-Apache%202.0%20OR%20MIT-blue.svg)](LICENSE)
[![MoonBit](https://img.shields.io/badge/MoonBit-0.1.0-orange.svg)](https://www.moonbitlang.com/)

A MoonBit library for shell-style lexical analysis, designed to parse and process shell-like command strings with high performance and Unicode support.

## Features

- **String Splitting**: Parse shell-style command strings into word arrays
- **Quote Handling**: Support for single and double quotes, preserving spaces within quotes
- **Escape Characters**: Support for backslash escape sequences
- **Comment Support**: Automatically ignore content after `#` comments
- **Error Handling**: Detailed error messages with position information
- **String Reconstruction**: Rebuild shell commands from word arrays
- **Unicode Support**: Full multi-language character support
- **Performance Optimized**: Efficient parsing algorithm suitable for large data processing
- **High Test Coverage**: 98.4% code coverage with comprehensive test suite

## Installation

```bash
moon add moonbit/shlex
```

## Quick Start

```moonbit
import { split, quote, join } from "moonbit/shlex"

// Basic splitting
split("ls -la file.txt") // Ok(["ls", "-la", "file.txt"])

// Quote handling
split("echo 'hello world'") // Ok(["echo", "hello world"])
split("git commit -m \"Initial commit\"") // Ok(["git", "commit", "-m", "Initial commit"])

// Escape characters
split("echo hello\\ world") // Ok(["echo", "hello world"])

// Comment handling
split("ls -la # list files") // Ok(["ls", "-la"])

// Word quoting
quote("hello world") // "'hello world'"
quote("it's") // "\"it's\""

// String reconstruction
join(["ls", "-la", "file name.txt"]) // "ls -la 'file name.txt'"
```

## API Documentation

### Core Functions

#### `split(input: String) -> Result[Array[String], ShlexError]`

Splits a string into a word array according to shell syntax.

**Parameters:**
- `input`: The string to split

**Returns:**
- `Ok(Array[String])`: Word array on success
- `Err(ShlexError)`: Error information on failure

**Errors:**
- `UnmatchedQuotes`: When encountering unmatched quotes
- `InvalidEscape`: When encountering invalid escape sequences

**Performance:**
- Time complexity: O(n), where n is the input string length
- Space complexity: O(m), where m is the number of output words

**Examples:**
```moonbit
// Basic splitting
split("ls -la file.txt") // Ok(["ls", "-la", "file.txt"])

// Quote handling
split("echo 'hello world'") // Ok(["echo", "hello world"])

// Error handling
split("echo 'unclosed") // Err(UnmatchedQuotes("Unmatched single quote", position))
```

#### `quote(word: String) -> String`

Adds appropriate quotes to a string to make it shell-safe.

**Parameters:**
- `word`: The string to quote

**Returns:**
- `String`: The quoted string

**Performance:**
- Time complexity: O(n), where n is the string length
- Space complexity: O(n)

**Examples:**
```moonbit
quote("hello") // "hello"
quote("hello world") // "'hello world'"
quote("it's") // "\"it's\""
quote("say \"hello\"") // "'say \"hello\"'"
```

#### `join(words: Array[String]) -> String`

Joins a word array into a single shell command string.

**Parameters:**
- `words`: The word array to join

**Returns:**
- `String`: The joined command string

**Performance:**
- Time complexity: O(n*m), where n is the number of words and m is the average word length
- Space complexity: O(n*m)

**Examples:**
```moonbit
join(["ls", "-la", "file name.txt"]) // "ls -la 'file name.txt'"
join(["echo", "hello", "world"]) // "echo hello world"
```

### Advanced Configuration

#### `split_with_config(input: String, config: ShlexConfig) -> Result[Array[String], ShlexError]`

Split strings with custom configuration options.

**Configuration Options:**
```moonbit
pub struct ShlexConfig {
  pub enable_comments: Bool        // Enable comment processing (default: true)
  pub track_positions: Bool        // Track error positions (default: true)
  pub single_quote: Char          // Single quote character (default: '\'')
  pub double_quote: Char          // Double quote character (default: '"')
  pub escape_char: Char           // Escape character (default: '\\')
  pub comment_char: Char          // Comment character (default: '#')
  pub whitespace_chars: String    // Whitespace characters (default: " \t\n\r")
}
```

### Utility Functions

#### `validate_roundtrip(words: Array[String]) -> Bool`

Validates that `split(join(words)) == words` holds true.

**Parameters:**
- `words`: The word array to validate

**Returns:**
- `Bool`: true if roundtrip is consistent, false otherwise

**Performance:**
- Time complexity: O(n*m), where n is the number of words and m is the average word length

### Error Types

#### `ShlexError`

```moonbit
pub enum ShlexError {
  /// Unmatched quotes error
  /// 
  /// # Parameters
  /// - `message`: Error description
  /// - `position`: Error position information
  UnmatchedQuotes(String, Position)
  
  /// Invalid escape sequence error
  /// 
  /// # Parameters
  /// - `message`: Error description
  /// - `position`: Error position information
  InvalidEscape(String, Position)
}

pub struct Position {
  pub line: Int     // Line number (1-based)
  pub column: Int   // Column number (1-based)
  pub index: Int    // Character index (0-based)
}
```

## Error Handling

When input contains unmatched quotes or invalid escape sequences, detailed error information is returned:

```moonbit
match split("echo 'unclosed quote") {
  Ok(words) => println("Words: \{words}")
  Err(UnmatchedQuotes(msg, pos)) => 
    println("Error: \{msg} at line \{pos.line}, column \{pos.column}")
  Err(InvalidEscape(msg, pos)) => 
    println("Escape error: \{msg} at position \{pos.index}")
}
```

## Usage Examples

### Basic Usage

```moonbit
// Parse command line arguments
let cmd = "git commit -m 'Fix issue #123' --author='John Doe <john@example.com>'"
match split(cmd) {
  Ok(words) => {
    println("Command: \{words[0]}")
    println("Arguments: \{words[1..]}")
  }
  Err(e) => println("Parse error: \{e}")
}

// Build safe commands
let args = ["find", "/tmp", "-name", "*.log", "-exec", "rm", "{}", ";"]
let safe_cmd = join(args)
println("Safe command: \{safe_cmd}")
```

### Advanced Usage

```moonbit
// Command line parser
struct CommandParser {
  command: String
  args: Array[String]
  options: Array[String]
  flags: Array[String]
}

fn parse_command(input: String) -> Result[CommandParser, String] {
  match split(input) {
    Ok(words) => {
      if words.length() == 0 {
        return Err("Empty command")
      }
      
      let command = words[0]
      let mut args: Array[String] = []
      let mut options: Array[String] = []
      let mut flags: Array[String] = []
      
      let mut i = 1
      while i < words.length() {
        let word = words[i]
        if word.starts_with("--") {
          options.push(word)
        } else if word.starts_with("-") {
          flags.push(word)
        } else {
          args.push(word)
        }
        i += 1
      }
      
      Ok(CommandParser {
        command: command,
        args: args,
        options: options,
        flags: flags
      })
    }
    Err(e) => Err("Parse error: " + e.to_string())
  }
}
```

### Unicode Support

```moonbit
// Multi-language support
split("你好 世界") // Ok(["你好", "世界"])
split("'résumé file.pdf'") // Ok(["résumé file.pdf"])
split("café naïve") // Ok(["café", "naïve"])

// Complex Unicode handling
let unicode_cmd = "find /path -name '文件*.txt' -type f"
match split(unicode_cmd) {
  Ok(words) => println("Unicode parsing successful: \{words}")
  Err(e) => println("Error: \{e}")
}
```

## Performance Characteristics

- **Efficient Parsing**: Single-pass algorithm with O(n) time complexity
- **Memory Optimized**: Streaming processing, avoiding unnecessary string copying
- **Unicode Optimized**: Native Unicode support without additional conversions
- **Error Recovery**: Fast error detection and reporting
- **High Coverage**: 98.4% test coverage ensuring reliability

## Compatibility

This library maintains compatibility with the following implementations:

- **Python `shlex`** - Behavior in POSIX mode
- **Rust `shlex`** - API design and feature set
- **GNU Bash** - Basic lexical analysis rules

### Key Differences

1. **Does not support** variable expansion (`$VAR`, `${VAR}`)
2. **Does not support** command substitution (`` `cmd` ``, `$(cmd)`)
3. **Does not support** wildcard expansion (`*`, `?`, `[...]`)
4. **Does not support** tilde expansion (`~`, `~user`)

These limitations ensure the library remains lightweight and secure while meeting most lexical analysis needs.

## Design Philosophy

This library follows POSIX shell lexical analysis rules and is particularly suitable for:

- Command-line tool argument parsing
- Configuration file command-line format parsing
- Applications that need to handle shell-style strings
- Scenarios requiring safe handling of user input

## Testing

```bash
# Run all tests
moon test

# Run specific tests
moon test --filter "basic_split"

# Check test coverage
moon coverage test
moon coverage report
```

## Project Structure

```
src/
├── lib.mbt          # Main implementation and basic tests
├── types.mbt        # Type definitions and error handling
└── lib_test.mbt     # Comprehensive test suite

.github/
└── workflows/       # CI/CD configuration
```

## Important Notes

- Single quotes do not support escaping (complies with POSIX shell standard)
- Limited escape support within double quotes
- Comment character `#` is treated as a regular character within quotes
- Empty strings and whitespace-only strings return empty arrays

## License

This project is licensed under Apache-2.0 OR MIT dual license.

## Contributing

Issues and Pull Requests are welcome! Please ensure:

1. Add appropriate test cases
2. Update relevant documentation
3. Follow existing code style
4. Ensure all tests pass

## Acknowledgments

This library's design and implementation reference:

- [Python shlex module](https://docs.python.org/3/library/shlex.html)
- [Rust shlex library](https://github.com/comex/rust-shlex)
- [POSIX Shell Syntax Specification](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html)
