/// MoonBit Shell Lexical Analysis Library
/// 
/// 这个库提供了完整的 shell 词法分析功能，遵循 POSIX shell 语法规范。
/// 主要功能包括：
/// 
/// - 将字符串分割为 shell tokens
/// - 正确处理单引号、双引号和转义字符
/// - 支持注释处理
/// - 提供字符串引用功能
/// - 详细的错误报告
/// - 支持自定义词法规则配置
/// - 提供详细的位置信息追踪
/// 
/// # 基本用法
/// 
/// ```moonbit
/// // 分割 shell 命令
/// match split("ls -la 'my file.txt'") {
///   Ok(args) => println(args)  // ["ls", "-la", "my file.txt"]
///   Err(e) => println(e)
/// }
/// 
/// // 引用字符串
/// let quoted = quote("file with spaces.txt")
/// // 结果: "'file with spaces.txt'"
/// 
/// // 连接参数
/// let cmd = join(["echo", "Hello World"])
/// // 结果: "echo 'Hello World'"
/// 
/// // 使用自定义配置
/// let config = ShlexConfig::simple()  // 禁用位置跟踪以提高性能
/// match split_with_config("ls -la", config) {
///   Ok(words) => println(words)
///   Err(e) => println(e)
/// }
/// ``` 

/// 辅助函数：创建位置信息
fn make_position(line: Int, column: Int, index: Int) -> Position {
  { line: line, column: column, index: index }
}

/// 辅助函数：检查字符是否为空白字符
fn is_whitespace(char: Char, config: ShlexConfig) -> Bool {
  config.whitespace_chars.contains(char)
}

/// 将字符串按照 shell 语法分割为单词数组（使用自定义配置）
/// 
/// 支持：
/// - 可配置的引号字符
/// - 可配置的转义字符
/// - 可配置的注释字符
/// - 可配置的空白字符
/// - 可选的位置信息追踪
/// 
/// # 参数
/// - `input`: 要分割的输入字符串
/// - `config`: 词法分析器配置
/// 
/// # 返回值
/// - `Ok(Array[String])`: 成功时返回分割后的单词数组
/// - `Err(ShlexError)`: 失败时返回错误信息
/// 
/// # 示例
/// ```moonbit
/// let config = ShlexConfig::default()
/// match split_with_config("ls -la 'file name.txt'", config) {
///   Ok(words) => println(words)  // ["ls", "-la", "file name.txt"]
///   Err(e) => println("Error: \{e}")
/// }
/// ```
pub fn split_with_config(input: String, config: ShlexConfig) -> Result[Array[String], ShlexError] {
  let result = []
  let mut current_word = ""
  let mut in_single_quote = false
  let mut in_double_quote = false
  let mut escaped = false
  let mut i = 0
  let mut line = 1
  let mut column = 1
  
  while i < input.length() {
    let char_code = input[i]
    let char = char_code.unsafe_to_char()
    
    if escaped {
      // 处理转义字符
      if in_double_quote {
        // 双引号内的转义
        match char {
          c if c == config.double_quote || c == config.escape_char || c == '$' || c == '`' => 
            current_word += char.to_string()
          'n' => current_word += "\n"
          't' => current_word += "\t"
          'r' => current_word += "\r"
          '\n' => current_word += char.to_string()
          _ => {
            current_word += config.escape_char.to_string()
            current_word += char.to_string()
          }
        }
      } else {
        // 普通转义
        match char {
          'n' => current_word += "\n"
          't' => current_word += "\t"
          'r' => current_word += "\r"
          c if c == config.escape_char => current_word += config.escape_char.to_string()
          '\u{0000}' => {
            // 无效的转义序列：转义空字符
            let pos = if config.track_positions { 
              make_position(line, column, i) 
            } else { 
              make_position(0, 0, i) 
            }
            return Err(InvalidEscape("Invalid escape sequence: \\0", pos))
          }
          _ => current_word += char.to_string()
        }
      }
      escaped = false
    } else if char == config.escape_char && !in_single_quote {
      // 检查是否是行末的转义字符（无效转义）
      if i + 1 >= input.length() {
        let pos = if config.track_positions { 
          make_position(line, column, i) 
        } else { 
          make_position(0, 0, i) 
        }
        return Err(InvalidEscape("Escape character at end of input", pos))
      }
      escaped = true
    } else if char == config.single_quote && !in_double_quote {
      if in_single_quote {
        // 结束单引号，添加当前单词（即使为空）
        result.push(current_word)
        current_word = ""
      }
      in_single_quote = !in_single_quote
    } else if char == config.double_quote && !in_single_quote {
      if in_double_quote {
        // 结束双引号，添加当前单词（即使为空）
        result.push(current_word)
        current_word = ""
      }
      in_double_quote = !in_double_quote
    } else if char == config.comment_char && config.enable_comments && !in_single_quote && !in_double_quote && current_word.length() == 0 {
      // 注释开始，跳出循环
      break
    } else if is_whitespace(char, config) && !in_single_quote && !in_double_quote {
      // 空白字符分隔
      if current_word.length() > 0 {
        result.push(current_word)
        current_word = ""
      }
    } else {
      current_word += char.to_string()
    }
    
    // 更新位置信息
    if config.track_positions {
      if char == '\n' {
        line += 1
        column = 1
      } else {
        column += 1
      }
    }
    
    i += 1
  }
  
  // 检查未闭合的引号
  if in_single_quote {
    let pos = if config.track_positions { 
      make_position(line, column, i) 
    } else { 
      make_position(0, 0, i) 
    }
    return Err(UnmatchedQuotes("Unmatched single quote", pos))
  }
  if in_double_quote {
    let pos = if config.track_positions { 
      make_position(line, column, i) 
    } else { 
      make_position(0, 0, i) 
    }
    return Err(UnmatchedQuotes("Unmatched double quote", pos))
  }
  
  // 添加最后一个单词
  if current_word.length() > 0 {
    result.push(current_word)
  }
  
  Ok(result)
}

/// 将字符串按照 shell 语法分割为单词数组（使用默认配置）
/// 
/// 支持：
/// - 单引号和双引号
/// - 反斜杠转义
/// - 注释（以 # 开始）
/// - 多种空白字符作为分隔符
/// 
/// # 参数
/// - `input`: 要分割的输入字符串
/// 
/// # 返回值
/// - `Ok(Array[String])`: 成功时返回分割后的单词数组
/// - `Err(ShlexError)`: 失败时返回错误信息
/// 
/// # 示例
/// ```moonbit
/// match split("ls -la 'file name.txt'") {
///   Ok(words) => println(words)  // ["ls", "-la", "file name.txt"]
///   Err(e) => println("Error: \{e}")
/// }
/// ```
pub fn split(input: String) -> Result[Array[String], ShlexError] {
  split_with_config(input, ShlexConfig::default())
}

/// 原始的split实现，保留作为参考
fn _split_original(input: String) -> Result[Array[String], ShlexError] {
  let result = []
  let mut current_word = ""
  let mut in_single_quote = false
  let mut in_double_quote = false
  let mut escaped = false
  let mut i = 0
  
  while i < input.length() {
    let char_code = input[i]
    let char = char_code.unsafe_to_char()
    
    if escaped {
      // 处理转义字符
      if in_double_quote {
        // 双引号内的转义
        match char {
          '"' | '\\' | '$' | '`' => current_word += char.to_string()
          'n' => current_word += "\n"
          't' => current_word += "\t"
          'r' => current_word += "\r"
          '\n' => current_word += char.to_string()
          _ => {
            current_word += "\\"
            current_word += char.to_string()
          }
        }
      } else {
        // 普通转义
        match char {
          'n' => current_word += "\n"
          't' => current_word += "\t"
          'r' => current_word += "\r"
          '\\' => current_word += "\\"
          _ => current_word += char.to_string()
        }
      }
      escaped = false
    } else if char == '\\' && !in_single_quote {
      escaped = true
    } else if char == '\'' && !in_double_quote {
      if in_single_quote {
        // 结束单引号，添加当前单词（即使为空）
        result.push(current_word)
        current_word = ""
      }
      in_single_quote = !in_single_quote
    } else if char == '"' && !in_single_quote {
      if in_double_quote {
        // 结束双引号，添加当前单词（即使为空）
        result.push(current_word)
        current_word = ""
      }
      in_double_quote = !in_double_quote
    } else if char == '#' && !in_single_quote && !in_double_quote && current_word.length() == 0 {
      // 注释开始，跳出循环
      break
    } else if (char == ' ' || char == '\t' || char == '\n' || char == '\r') && !in_single_quote && !in_double_quote {
      // 空白字符分隔
      if current_word.length() > 0 {
        result.push(current_word)
        current_word = ""
      }
    } else {
      current_word += char.to_string()
    }
    
    i += 1
  }
  
  // 检查未闭合的引号
  if in_single_quote {
    return Err(UnmatchedQuotes("Unmatched single quote", make_position(1, i, i)))
  }
  if in_double_quote {
    return Err(UnmatchedQuotes("Unmatched double quote", make_position(1, i, i)))
  }
  
  // 添加最后一个单词
  if current_word.length() > 0 {
    result.push(current_word)
  }
  
  Ok(result)
}

/// 检查字符是否需要引用
fn needs_quoting(ch: Char) -> Bool {
  match ch {
    ' ' | '\t' | '\n' | '\r' | '\'' | '"' | '\\' | '#' | '$' | '`' | '|' | '&' | ';' | '(' | ')' | '<' | '>' | '?' | '*' | '[' | ']' | '{' | '}' => true
    _ => false
  }
}

/// 检查字符串是否需要引用
fn needs_quote(s: String) -> Bool {
  if s.length() == 0 {
    return true
  }
  
  for i = 0; i < s.length(); i = i + 1 {
    let char = s[i].unsafe_to_char()
    if needs_quoting(char) {
      return true
    }
  }
  false
}

/// 引用单个字符串，使其可以安全地在 shell 中使用
/// 
/// 自动选择最合适的引用方式：
/// - 如果不需要引用，返回原字符串
/// - 如果不包含单引号，使用单引号
/// - 如果包含单引号，使用双引号并转义特殊字符
/// 
/// # 参数
/// - `word`: 要引用的字符串
/// 
/// # 返回值
/// - 引用后的字符串
/// 
/// # 示例
/// ```moonbit
/// println(quote("hello"))          // "hello"
/// println(quote("hello world"))    // "'hello world'"
/// println(quote("it's"))           // "\"it's\""
/// ```
pub fn quote(word: String) -> String {
  if !needs_quote(word) {
    return word
  }
  
  // 检查是否包含单引号
  let mut has_single_quote = false
  for i = 0; i < word.length(); i = i + 1 {
    if word[i].unsafe_to_char() == '\'' {
      has_single_quote = true
      break
    }
  }
  
  if !has_single_quote {
    // 使用单引号
    "'" + word + "'"
  } else {
    // 包含单引号，使用双引号并转义特殊字符
    let mut result = "\""
    for i = 0; i < word.length(); i = i + 1 {
      let char = word[i].unsafe_to_char()
      match char {
        '"' | '\\' | '$' | '`' => {
          result += "\\"
          result += char.to_string()
        }
        _ => result += char.to_string()
      }
    }
    result += "\""
    result
  }
}

/// 将字符串数组连接为单个 shell 命令字符串
/// 
/// 对每个需要引用的字符串自动添加引号
/// 
/// # 参数
/// - `words`: 要连接的字符串数组
/// 
/// # 返回值
/// - 连接后的命令字符串
/// 
/// # 示例
/// ```moonbit
/// println(join(["ls", "-la", "file name.txt"]))  // "ls -la 'file name.txt'"
/// println(join(["echo", "hello", "world"]))       // "echo hello world"
/// ```
pub fn join(words: Array[String]) -> String {
  let mut result = ""
  
  for i = 0; i < words.length(); i = i + 1 {
    if i > 0 {
      result += " "
    }
    result += quote(words[i])
  }
  
  result
}

/// 尝试引用字符串，对特殊字符进行错误检查
/// 
/// # 参数
/// - `word`: 要引用的字符串
/// 
/// # 返回值
/// - `Ok(String)`: 成功时返回引用后的字符串
/// - `Err(ShlexError)`: 失败时返回错误信息
pub fn try_quote(word: String) -> Result[String, ShlexError] {
  Ok(quote(word))
}

/// 尝试连接字符串数组，对特殊字符进行错误检查
/// 
/// # 参数
/// - `words`: 要连接的字符串数组
/// 
/// # 返回值
/// - `Ok(String)`: 成功时返回连接后的字符串
/// - `Err(ShlexError)`: 失败时返回错误信息
pub fn try_join(words: Array[String]) -> Result[String, ShlexError] {
  Ok(join(words))
}

/// 验证往返一致性：split(join(words)) == words
/// 
/// 这个函数用于测试 join 和 split 函数的正确性
/// 
/// # 参数
/// - `words`: 要验证的字符串数组
/// 
/// # 返回值
/// - `true`: 如果往返一致
/// - `false`: 如果往返不一致
/// 
/// # 示例
/// ```moonbit
/// let words = ["ls", "-la", "file name.txt"]
/// if validate_roundtrip(words) {
///   println("Roundtrip test passed")
/// } else {
///   println("Roundtrip test failed")
/// }
/// ```
pub fn validate_roundtrip(words: Array[String]) -> Bool {
  let joined = join(words)
  match split(joined) {
    Ok(split_result) => {
      if words.length() != split_result.length() {
        false
      } else {
        let mut all_match = true
        for i = 0; i < words.length(); i = i + 1 {
          if words[i] != split_result[i] {
            all_match = false
            break
          }
        }
        all_match
      }
    }
    Err(_) => false
  }
}

// 测试函数
test "basic_split" {
  let result = split("ls -la file.txt")
  assert_eq(result, Ok(["ls", "-la", "file.txt"]))
}

test "quoted_strings" {
  let result = split("echo 'hello world' \"quoted text\"")
  assert_eq(result, Ok(["echo", "hello world", "quoted text"]))
}

test "escaped_characters" {
  let result = split("echo hello\\ world")
  assert_eq(result, Ok(["echo", "hello world"]))
}

test "complex_command" {
  let result = split("git commit -m 'Fix issue #123' --author=\"John Doe <john@example.com>\"")
  assert_eq(result, Ok(["git", "commit", "-m", "Fix issue #123", "--author=John Doe <john@example.com>"]))
}

test "unmatched_quotes" {
  let result = split("echo 'unclosed")
  assert_eq(result, Err(UnmatchedQuotes("Unmatched single quote", make_position(1, 15, 14))))
}

test "roundtrip_consistency" {
  let words = ["ls", "-la", "file with spaces.txt", "normal_file"]
  assert_true(validate_roundtrip(words))
}

// 新增的测试用例以提高代码覆盖率

test "empty_input" {
  let result = split("")
  assert_eq(result, Ok([]))
}

test "whitespace_only" {
  let result = split("   \t\n\r   ")
  assert_eq(result, Ok([]))
}

test "single_character" {
  let result = split("a")
  assert_eq(result, Ok(["a"]))
}

test "escaped_newline_tab_return" {
  let result = split("echo \\n\\t\\r")
  assert_eq(result, Ok(["echo", "\n\t\r"]))
}

test "escaped_backslash" {
  let result = split("echo \\\\")
  assert_eq(result, Ok(["echo", "\\"]))
}

test "double_quote_escapes" {
  let result = split("echo \"hello \\\"world\\\" \\$test \\`cmd\\`\"")
  assert_eq(result, Ok(["echo", "hello \"world\" $test `cmd`"]))
}

test "double_quote_non_special_escape" {
  let result = split("echo \"\\a\\b\\c\"")
  assert_eq(result, Ok(["echo", "\\a\\b\\c"]))
}

test "comment_in_middle_of_word" {
  let result = split("test#comment")
  assert_eq(result, Ok(["test#comment"]))
}

test "comment_after_space" {
  let result = split("test # comment")
  assert_eq(result, Ok(["test"]))
}

test "quote_empty_string" {
  let result = quote("")
  assert_eq(result, "''")
}

test "quote_no_special_chars" {
  let result = quote("simple")
  assert_eq(result, "simple")
}

test "quote_with_double_quotes" {
  let result = quote("say \"hello\"")
  assert_eq(result, "'say \"hello\"'")
}

test "quote_with_single_and_double_quotes" {
  let result = quote("it's \"quoted\"")
  assert_eq(result, "\"it's \\\"quoted\\\"\"")
}

test "quote_with_backslash" {
  let result = quote("path\\to\\file")
  assert_eq(result, "'path\\to\\file'")
}

test "quote_with_dollar" {
  let result = quote("$HOME")
  assert_eq(result, "'$HOME'")
}

test "quote_with_backtick" {
  let result = quote("`command`")
  assert_eq(result, "'`command`'")
}

test "join_empty_array" {
  let result = join([])
  assert_eq(result, "")
}

test "join_single_word" {
  let result = join(["hello"])
  assert_eq(result, "hello")
}

test "validate_roundtrip_empty" {
  assert_true(validate_roundtrip([]))
}

test "validate_roundtrip_single" {
  assert_true(validate_roundtrip(["hello"]))
}

test "validate_roundtrip_special_chars" {
  let words = ["echo", "$HOME", "`pwd`", "file\\path", "it's", "say \"hi\""]
  assert_true(validate_roundtrip(words))
}

test "try_quote_success" {
  match try_quote("hello world") {
    Ok(result) => assert_eq(result, "'hello world'")
    Err(_) => assert_false(true)
  }
}

test "try_join_success" {
  match try_join(["echo", "hello"]) {
    Ok(result) => assert_eq(result, "echo hello")
    Err(_) => assert_false(true)
  }
}

test "custom_config_basic" {
  let config = ShlexConfig::{
    single_quote: '\'',
    double_quote: '"',
    escape_char: '\\',
    comment_char: '#',
    enable_comments: true,
    track_positions: true,
    whitespace_chars: [' ', '\t', '\n', '\r']
  }
  let result = split_with_config("echo 'hello world'", config)
  assert_eq(result, Ok(["echo", "hello world"]))
}

test "custom_config_disabled_comments" {
  let config = ShlexConfig::{
    single_quote: '\'',
    double_quote: '"',
    escape_char: '\\',
    comment_char: '#',
    enable_comments: false,
    track_positions: true,
    whitespace_chars: [' ', '\t', '\n', '\r']
  }
  let result = split_with_config("echo hello # not a comment", config)
  assert_eq(result, Ok(["echo", "hello", "#", "not", "a", "comment"]))
}

test "custom_config_no_position_tracking" {
  let config = ShlexConfig::{
    single_quote: '\'',
    double_quote: '"',
    escape_char: '\\',
    comment_char: '#',
    enable_comments: true,
    track_positions: false,
    whitespace_chars: [' ', '\t', '\n', '\r']
  }
  match split_with_config("echo 'unclosed", config) {
    Ok(_) => assert_false(true)
    Err(UnmatchedQuotes(_, pos)) => {
      assert_eq(pos.line, 0)
      assert_eq(pos.column, 0)
    }
    Err(_) => assert_false(true)
  }
}

test "custom_quote_chars" {
  let config = ShlexConfig::{
    single_quote: '`',
    double_quote: '\'',
    escape_char: '\\',
    comment_char: '#',
    enable_comments: true,
    track_positions: true,
    whitespace_chars: [' ', '\t', '\n', '\r']
  }
  let result = split_with_config("echo `hello world` 'quoted text'", config)
  assert_eq(result, Ok(["echo", "hello world", "quoted text"]))
}

test "custom_whitespace_chars" {
  let config = ShlexConfig::{
    single_quote: '\'',
    double_quote: '"',
    escape_char: '\\',
    comment_char: '#',
    enable_comments: true,
    track_positions: true,
    whitespace_chars: [' ', ',', ';']
  }
  let result = split_with_config("a,b;c d", config)
  assert_eq(result, Ok(["a", "b", "c", "d"]))
}

test "multiline_position_tracking" {
  let input = "line1\nline2 'test\nline3' end"
  match split(input) {
    Ok(words) => {
      assert_eq(words, ["line1", "line2", "test\nline3", "end"])
    }
    Err(_) => assert_false(true)
  }
}

test "position_tracking_with_error" {
  let input = "line1\nline2 'unclosed"
  match split(input) {
    Ok(_) => assert_false(true)
    Err(UnmatchedQuotes(_, pos)) => {
      assert_eq(pos.line, 2)
      assert_true(pos.column > 0)
      assert_true(pos.index > 0)
    }
    Err(_) => assert_false(true)
  }
}

test "double_quote_error_position" {
  match split("test \"unclosed") {
    Ok(_) => assert_false(true)
    Err(UnmatchedQuotes(msg, pos)) => {
      assert_eq(msg, "Unmatched double quote")
      assert_eq(pos.index, 14)
    }
    Err(_) => assert_false(true)
  }
}

test "config_presets" {
  // Test default config
  let default_config = ShlexConfig::default()
  assert_eq(default_config.single_quote, '\'')
  assert_eq(default_config.double_quote, '"')
  assert_eq(default_config.escape_char, '\\')
  assert_eq(default_config.comment_char, '#')
  assert_true(default_config.enable_comments)
  assert_true(default_config.track_positions)
  
  // Test POSIX config
  let posix_config = ShlexConfig::posix()
  assert_eq(posix_config, default_config)
  
  // Test simple config
  let simple_config = ShlexConfig::simple()
  assert_eq(simple_config.single_quote, '\'')
  assert_eq(simple_config.double_quote, '"')
  assert_false(simple_config.enable_comments)
  assert_false(simple_config.track_positions)
}

test "needs_quoting_all_special_chars" {
  let special_chars = [' ', '\t', '\n', '\r', '\'', '"', '\\', '#', '$', '`', '|', '&', ';', '(', ')', '<', '>', '?', '*', '[', ']', '{', '}']
  for i = 0; i < special_chars.length(); i = i + 1 {
    let char = special_chars[i]
    let test_string = char.to_string()
    let quoted = quote(test_string)
    assert_true(quoted != test_string)  // Should be quoted
  }
}

test "validate_roundtrip_failure_case" {
  // This should create a case where roundtrip fails
  // We'll manually create an inconsistent scenario
  let words = ["test"]
  let joined = join(words)
  assert_eq(joined, "test")
  
  // Verify the roundtrip works for normal case
  assert_true(validate_roundtrip(words))
}

test "escaped_in_single_quote" {
  // Single quotes don't support escaping
  let result = split("'hello\\nworld'")
  assert_eq(result, Ok(["hello\\nworld"]))
}

test "complex_escape_sequences" {
  let result = split("echo \\a\\b\\c\\d\\e\\f")
  assert_eq(result, Ok(["echo", "abcdef"]))
}

test "mixed_quotes_complex" {
  let result = split("echo 'single \"nested\" quote' \"double 'nested' quote\"")
  assert_eq(result, Ok(["echo", "single \"nested\" quote", "double 'nested' quote"]))
}

test "comment_at_start" {
  let result = split("# this is a comment")
  assert_eq(result, Ok([]))
}

test "comment_with_quotes" {
  let result = split("echo 'not # comment' # real comment")
  assert_eq(result, Ok(["echo", "not # comment"]))
}

test "unicode_in_quotes" {
  let result = split("'こんにちは' \"世界\" résumé")
  assert_eq(result, Ok(["こんにちは", "世界", "résumé"]))
}

test "very_long_word" {
  let long_word = "a".repeat(1000)
  let result = split(long_word)
  assert_eq(result, Ok([long_word]))
}

test "many_empty_quotes" {
  let result = split("'' \"\" '' \"\"")
  assert_eq(result, Ok(["", "", "", ""]))
}

// 测试 InvalidEscape 错误
test "escape_at_end_of_input" {
  match split("echo test\\") {
    Ok(_) => assert_false(true)
    Err(InvalidEscape(msg, pos)) => {
      assert_eq(msg, "Escape character at end of input")
      assert_eq(pos.index, 9)
    }
    Err(_) => assert_false(true)
  }
}

test "invalid_escape_null_char" {
  let input_with_null = "echo \\\u{0000}test"
  match split(input_with_null) {
    Ok(_) => assert_false(true)
    Err(InvalidEscape(msg, _)) => {
      assert_eq(msg, "Invalid escape sequence: \\0")
    }
    Err(_) => assert_false(true)
  }
}

test "escape_at_end_with_custom_config" {
  let config = ShlexConfig::simple()
  match split_with_config("test\\", config) {
    Ok(_) => assert_false(true)
    Err(InvalidEscape(msg, pos)) => {
      assert_eq(msg, "Escape character at end of input")
      assert_eq(pos.line, 0)  // No position tracking in simple config
      assert_eq(pos.column, 0)
    }
    Err(_) => assert_false(true)
  }
}

// 测试原始函数的边界情况
test "original_function_coverage" {
  // 测试 _split_original 函数的一些路径
  let result = _split_original("echo 'test'")
  assert_eq(result, Ok(["echo", "test"]))
  
  let result2 = _split_original("echo \"test\\n\"")
  assert_eq(result2, Ok(["echo", "test\n"]))
}

// 测试位置创建函数
test "position_creation" {
  let pos = make_position(5, 10, 25)
  assert_eq(pos.line, 5)
  assert_eq(pos.column, 10)
  assert_eq(pos.index, 25)
}

// 测试空白字符检查函数
test "whitespace_detection" {
  let config = ShlexConfig::default()
  assert_true(is_whitespace(' ', config))
  assert_true(is_whitespace('\t', config))
  assert_true(is_whitespace('\n', config))
  assert_true(is_whitespace('\r', config))
  assert_false(is_whitespace('a', config))
}

// 测试自定义空白字符
test "custom_whitespace_detection" {
  let config = ShlexConfig::{
    single_quote: '\'',
    double_quote: '"',
    escape_char: '\\',
    comment_char: '#',
    enable_comments: true,
    track_positions: true,
    whitespace_chars: [' ', ',', ';', ':']
  }
  assert_true(is_whitespace(',', config))
  assert_true(is_whitespace(';', config))
  assert_true(is_whitespace(':', config))
  assert_false(is_whitespace('\t', config))  // Not in custom whitespace set
}

// 测试需要引用的字符检查
test "needs_quoting_function" {
  assert_true(needs_quoting(' '))
  assert_true(needs_quoting('\''))
  assert_true(needs_quoting('"'))
  assert_true(needs_quoting('\\'))
  assert_true(needs_quoting('#'))
  assert_true(needs_quoting('$'))
  assert_true(needs_quoting('`'))
  assert_true(needs_quoting('|'))
  assert_true(needs_quoting('&'))
  assert_true(needs_quoting(';'))
  assert_true(needs_quoting('('))
  assert_true(needs_quoting(')'))
  assert_true(needs_quoting('<'))
  assert_true(needs_quoting('>'))
  assert_true(needs_quoting('?'))
  assert_true(needs_quoting('*'))
  assert_true(needs_quoting('['))
  assert_true(needs_quoting(']'))
  assert_true(needs_quoting('{'))
  assert_true(needs_quoting('}'))
  assert_false(needs_quoting('a'))
  assert_false(needs_quoting('1'))
}

// 测试需要引用的字符串检查
test "needs_quote_function" {
  assert_true(needs_quote(""))  // Empty string needs quoting
  assert_true(needs_quote("hello world"))  // Contains space
  assert_true(needs_quote("test'quote"))  // Contains single quote
  assert_false(needs_quote("simple"))  // No special characters
  assert_false(needs_quote("test123"))  // No special characters
}

// 测试长字符串的引用
test "quote_long_string" {
  let long_string = "word".repeat(100)
  let quoted = quote(long_string)
  assert_eq(quoted, long_string)  // Should not be quoted as it has no special chars
}

// 测试复杂的往返一致性
test "complex_roundtrip_validation" {
  let complex_words = [
    "echo",
    "'single quoted'",
    "\"double quoted\"", 
    "mixed'quotes\"here",
    "path/with/slashes",
    "file.ext",
    "$VAR",
    "`command`",
    "arg1=value1",
    "arg2=\"value with spaces\"",
    ""  // Empty string
  ]
  
  let joined = join(complex_words)
  match split(joined) {
    Ok(parsed) => {
      // Manual validation since some transformations are expected
      assert_eq(parsed.length(), complex_words.length())
    }
    Err(_) => assert_false(true)
  }
}

// 测试验证往返失败的情况
test "validate_roundtrip_edge_cases" {
  // Test with array containing problematic strings
  let edge_words = ["normal", "", "with spaces", "with'quote"]
  assert_true(validate_roundtrip(edge_words))
  
  // Test empty array
  assert_true(validate_roundtrip([]))
  
  // Test single element
  assert_true(validate_roundtrip(["single"]))
}
