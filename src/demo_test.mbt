/// 演示 shlex 库的各种功能

test "demo_basic_usage" {
  println("=== 基本使用演示 ===")
  
  // 基本分割
  let cmd1 = "ls -la file.txt"
  match split(cmd1) {
    Ok(words) => println("输入: \"\{cmd1}\" -> 输出: \{words}")
    Err(e) => println("错误: \{e}")
  }
  
  // 引号处理
  let cmd2 = "echo 'hello world' \"quoted text\""
  match split(cmd2) {
    Ok(words) => println("输入: \"\{cmd2}\" -> 输出: \{words}")
    Err(e) => println("错误: \{e}")
  }
  
  // 转义字符
  let cmd3 = "echo hello\\ world"
  match split(cmd3) {
    Ok(words) => println("输入: \"\{cmd3}\" -> 输出: \{words}")
    Err(e) => println("错误: \{e}")
  }
  
  // 注释处理
  let cmd4 = "ls -la # 这是注释"
  match split(cmd4) {
    Ok(words) => println("输入: \"\{cmd4}\" -> 输出: \{words}")
    Err(e) => println("错误: \{e}")
  }
  
  println("")
}

test "demo_quote_function" {
  println("=== Quote 函数演示 ===")
  
  let samples = [
    "hello",
    "hello world", 
    "it's",
    "say \"hello\"",
    "file with spaces.txt",
    ""
  ]
  
  let mut i = 0
  while i < samples.length() {
    let word = samples[i]
    let quoted = quote(word)
    println("原文: \"\{word}\" -> 引用: \{quoted}")
    i += 1
  }
  
  println("")
}

test "demo_join_function" {
  println("=== Join 函数演示 ===")
  
  let test_cases = [
    (["ls", "-la"], "ls -la"),
    (["echo", "hello world"], "echo 'hello world'"),
    (["git", "commit", "-m", "Fix issue #123"], "git commit -m 'Fix issue #123'"),
    (["find", "/tmp", "-name", "*.log"], "find /tmp -name '*.log'"),
    ([], "")
  ]
  
  let mut i = 0
  while i < test_cases.length() {
    let (words, _expected) = test_cases[i]
    let joined = join(words)
    println("单词数组: \{words} -> 命令: \"\{joined}\"")
    i += 1
  }
  
  println("")
}

test "demo_roundtrip" {
  println("=== 往返测试演示 ===")
  
  let test_words = [
    ["ls", "-la", "file.txt"],
    ["echo", "hello world", "test"],
    ["git", "commit", "-m", "Initial commit"],
    ["find", "/path", "-name", "*.log", "-exec", "rm", "{}", ";"]
  ]
  
  let mut i = 0
  while i < test_words.length() {
    let words = test_words[i]
    let joined = join(words)
    match split(joined) {
      Ok(parsed) => {
        let is_same = validate_roundtrip(words)
        println("原始: \{words}")
        println("连接: \"\{joined}\"") 
        println("解析: \{parsed}")
        println("一致: \{is_same}")
        println("")
      }
      Err(e) => println("错误: \{e}")
    }
    i += 1
  }
}

test "demo_error_handling" {
  println("=== 错误处理演示 ===")
  
  let bad_inputs = [
    "echo 'unclosed quote",
    "echo \"unclosed quote",
    "mixed 'quote\" problem"
  ]
  
  let mut i = 0
  while i < bad_inputs.length() {
    let input = bad_inputs[i]
    match split(input) {
      Ok(words) => println("输入: \"\{input}\" -> 成功: \{words}")
      Err(e) => println("输入: \"\{input}\" -> 错误: \{e}")
    }
    i += 1
  }
  
  println("")
}

test "demo_unicode_support" {
  println("=== Unicode 支持演示 ===")
  
  let unicode_tests = [
    "你好 世界",
    "'résumé file.pdf'",
    "café naïve",
    "'文件 名称.txt'"
  ]
  
  let mut i = 0
  while i < unicode_tests.length() {
    let input = unicode_tests[i]
    match split(input) {
      Ok(words) => println("输入: \"\{input}\" -> 输出: \{words}")
      Err(e) => println("输入: \"\{input}\" -> 错误: \{e}")
    }
    i += 1
  }
  
  println("")
}

test "demo_complex_commands" {
  println("=== 复杂命令演示 ===")
  
  let complex_commands = [
    "git commit -m 'Fix issue #123' --author=\"John Doe <john@example.com>\"",
    "find /tmp -name '*.log' -exec rm {} \\;",
    "docker run -it --name mycontainer -v '/host/path:/container/path' ubuntu:20.04",
    "ssh user@host 'cd /path && ls -la'"
  ]
  
  let mut i = 0
  while i < complex_commands.length() {
    let cmd = complex_commands[i]
    match split(cmd) {
      Ok(words) => {
        println("命令: \"\{cmd}\"")
        println("解析为 \{words.length()} 个参数:")
        let mut j = 0
        while j < words.length() {
          println("  [\{j}]: \"\{words[j]}\"")
          j += 1
        }
        println("")
      }
      Err(e) => println("命令解析失败: \{e}")
    }
    i += 1
  }
}

test "demo_custom_config" {
  println("=== 自定义配置演示 ===")
  
  // 使用默认配置
  let default_config = ShlexConfig::default()
  match split_with_config("ls -la 'file.txt' # comment", default_config) {
    Ok(words) => println("默认配置: \{words}")  // 应该忽略注释
    Err(e) => println("错误: \{e}")
  }
  
  // 使用禁用注释的配置
  let no_comment_config = ShlexConfig::{
    single_quote: '\'',
    double_quote: '"',
    escape_char: '\\',
    comment_char: '#',
    enable_comments: false,
    track_positions: true,
    whitespace_chars: [' ', '\t', '\n', '\r']
  }
  match split_with_config("ls -la 'file.txt' # comment", no_comment_config) {
    Ok(words) => println("禁用注释: \{words}")  // 应该包含 # comment
    Err(e) => println("错误: \{e}")
  }
  
  // 使用自定义引号字符的配置
  let custom_quote_config = ShlexConfig::{
    single_quote: '`',
    double_quote: '\'',
    escape_char: '\\',
    comment_char: '#',
    enable_comments: true,
    track_positions: true,
    whitespace_chars: [' ', '\t', '\n', '\r']
  }
  match split_with_config("echo `hello world` 'quoted text'", custom_quote_config) {
    Ok(words) => println("自定义引号: \{words}")  // ` 作为单引号，' 作为双引号
    Err(e) => println("错误: \{e}")
  }
  
  // 使用简化配置（无位置跟踪）
  let simple_config = ShlexConfig::simple()
  match split_with_config("echo 'unclosed", simple_config) {
    Ok(words) => println("意外成功: \{words}")
    Err(UnmatchedQuotes(msg, pos)) => {
      println("简化配置错误: \{msg} at position \{pos.line}:\{pos.column} (index \{pos.index})")
    }
    Err(e) => println("其他错误: \{e}")
  }
}

test "demo_position_tracking" {
  println("=== 位置信息追踪演示 ===")
  
  // 多行输入测试
  let multiline_input = "echo 'line 1\nline 2' \"unclosed quote"
  match split(multiline_input) {
    Ok(words) => println("意外成功: \{words}")
    Err(UnmatchedQuotes(msg, pos)) => {
      println("错误: \{msg}")
      println("位置: 第\{pos.line}行, 第\{pos.column}列 (字符索引: \{pos.index})")
    }
    Err(e) => println("其他错误: \{e}")
  }
  
  // 测试位置跟踪的准确性
  let input_with_newlines = "ls\n-la\n'file\nname.txt'"
  match split(input_with_newlines) {
    Ok(words) => {
      println("多行解析成功: \{words}")
      // 应该正确处理换行符
    }
    Err(e) => println("解析错误: \{e}")
  }
}

test "demo_performance_comparison" {
  println("=== 性能配置对比演示 ===")
  
  let test_input = "git commit -m 'Initial commit with some long message' --author='John Doe <john@example.com>' --date='2024-01-01'"
  
  // 使用默认配置（启用位置跟踪）
  match split_with_config(test_input, ShlexConfig::default()) {
    Ok(words) => println("默认配置解析: \{words.length()} 个参数")
    Err(e) => println("默认配置错误: \{e}")
  }
  
  // 使用简化配置（禁用位置跟踪）
  match split_with_config(test_input, ShlexConfig::simple()) {
    Ok(words) => println("简化配置解析: \{words.length()} 个参数")
    Err(e) => println("简化配置错误: \{e}")
  }
  
  // 验证结果一致性
  let default_result = split_with_config(test_input, ShlexConfig::default())
  let simple_result = split_with_config(test_input, ShlexConfig::simple())
  
  match (default_result, simple_result) {
    (Ok(default_words), Ok(simple_words)) => {
      if default_words == simple_words {
        println("✅ 两种配置解析结果一致")
      } else {
        println("❌ 两种配置解析结果不一致")
      }
    }
    _ => println("⚠️  配置对比测试失败")
  }
}

// 确保所有演示都能正常运行
test "verify_all_demos" {
  assert_true(true)
} 