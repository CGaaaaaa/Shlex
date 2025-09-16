# Shlex - MoonBit Shell风格词法分析库

<div align="right">
  <strong>语言:</strong> 
  <a href="README.md">English</a> | 中文
</div>

[![License](https://img.shields.io/badge/license-Apache%202.0%20OR%20MIT-blue.svg)](LICENSE)
[![MoonBit](https://img.shields.io/badge/MoonBit-0.1.0-orange.svg)](https://www.moonbitlang.com/)

一个用MoonBit实现的shell风格的词法分析库，专为解析和处理类似shell命令的字符串而设计，具有高性能和完整的Unicode支持。

## 功能特性

- **字符串分割**: 将shell风格的命令字符串分割为单词数组
- **引号处理**: 支持单引号和双引号，保留引号内的空格
- **转义字符**: 支持反斜杠转义序列
- **注释支持**: 自动忽略 `#` 后的注释内容
- **错误处理**: 详细的错误信息，包括位置信息
- **字符串重组**: 将单词数组重新组合为shell命令
- **Unicode支持**: 完整的多语言字符支持
- **性能优化**: 高效的解析算法，适合处理大量数据
- **高测试覆盖率**: 98.4%的代码覆盖率，确保可靠性

## 安装

```bash
moon add moonbit/shlex
```

## 快速开始

```moonbit
import { split, quote, join } from "moonbit/shlex"

// 基本分割
split("ls -la file.txt") // Ok(["ls", "-la", "file.txt"])

// 引号处理
split("echo 'hello world'") // Ok(["echo", "hello world"])
split("git commit -m \"Initial commit\"") // Ok(["git", "commit", "-m", "Initial commit"])

// 转义字符
split("echo hello\\ world") // Ok(["echo", "hello world"])

// 注释处理
split("ls -la # 列出文件") // Ok(["ls", "-la"])

// 单词引用
quote("hello world") // "'hello world'"
quote("it's") // "\"it's\""

// 字符串重组
join(["ls", "-la", "file name.txt"]) // "ls -la 'file name.txt'"
```

## API 文档

### 核心函数

#### `split(input: String) -> Result[Array[String], ShlexError]`

将字符串按照shell语法分割为单词数组。

**参数:**
- `input`: 要分割的字符串

**返回值:**
- `Ok(Array[String])`: 成功时返回单词数组
- `Err(ShlexError)`: 失败时返回错误信息

**错误:**
- `UnmatchedQuotes`: 当遇到未匹配的引号时
- `InvalidEscape`: 当遇到无效的转义序列时

**性能:**
- 时间复杂度: O(n)，其中n是输入字符串长度
- 空间复杂度: O(m)，其中m是输出单词数量

**示例:**
```moonbit
// 基本分割
split("ls -la file.txt") // Ok(["ls", "-la", "file.txt"])

// 引号处理
split("echo 'hello world'") // Ok(["echo", "hello world"])

// 错误处理
split("echo 'unclosed") // Err(UnmatchedQuotes("Unmatched single quote", position))
```

#### `quote(word: String) -> String`

为字符串添加适当的引号，使其在shell中安全使用。

**参数:**
- `word`: 需要引用的字符串

**返回值:**
- `String`: 引用后的字符串

**性能:**
- 时间复杂度: O(n)，其中n是字符串长度
- 空间复杂度: O(n)

**示例:**
```moonbit
quote("hello") // "hello"
quote("hello world") // "'hello world'"
quote("it's") // "\"it's\""
quote("say \"hello\"") // "'say \"hello\"'"
```

#### `join(words: Array[String]) -> String`

将单词数组连接为单个shell命令字符串。

**参数:**
- `words`: 要连接的单词数组

**返回值:**
- `String`: 连接后的命令字符串

**性能:**
- 时间复杂度: O(n*m)，其中n是单词数量，m是平均单词长度
- 空间复杂度: O(n*m)

**示例:**
```moonbit
join(["ls", "-la", "file name.txt"]) // "ls -la 'file name.txt'"
join(["echo", "hello", "world"]) // "echo hello world"
```

### 高级配置

#### `split_with_config(input: String, config: ShlexConfig) -> Result[Array[String], ShlexError]`

使用自定义配置选项分割字符串。

**配置选项:**
```moonbit
pub struct ShlexConfig {
  pub enable_comments: Bool        // 启用注释处理 (默认: true)
  pub track_positions: Bool        // 跟踪错误位置 (默认: true)
  pub single_quote: Char          // 单引号字符 (默认: '\'')
  pub double_quote: Char          // 双引号字符 (默认: '"')
  pub escape_char: Char           // 转义字符 (默认: '\\')
  pub comment_char: Char          // 注释字符 (默认: '#')
  pub whitespace_chars: String    // 空白字符 (默认: " \t\n\r")
}
```

### 实用函数

#### `validate_roundtrip(words: Array[String]) -> Bool`

验证 `split(join(words)) == words` 是否成立。

**参数:**
- `words`: 要验证的单词数组

**返回值:**
- `Bool`: 如果往返一致返回true，否则返回false

**性能:**
- 时间复杂度: O(n*m)，其中n是单词数量，m是平均单词长度

### 错误类型

#### `ShlexError`

```moonbit
pub enum ShlexError {
  /// 未匹配的引号错误
  /// 
  /// # 参数
  /// - `message`: 错误描述信息
  /// - `position`: 错误位置信息
  UnmatchedQuotes(String, Position)
  
  /// 无效转义序列错误
  /// 
  /// # 参数
  /// - `message`: 错误描述信息
  /// - `position`: 错误位置信息
  InvalidEscape(String, Position)
}

pub struct Position {
  pub line: Int     // 行号 (从1开始)
  pub column: Int   // 列号 (从1开始)
  pub index: Int    // 字符索引 (从0开始)
}
```

## 错误处理

当输入包含未匹配的引号或无效的转义序列时，会返回详细的错误信息：

```moonbit
match split("echo 'unclosed quote") {
  Ok(words) => println("单词: \{words}")
  Err(UnmatchedQuotes(msg, pos)) => 
    println("错误: \{msg} 在第\{pos.line}行, 第\{pos.column}列")
  Err(InvalidEscape(msg, pos)) => 
    println("转义错误: \{msg} 在位置\{pos.index}")
}
```

## 使用示例

### 基本使用

```moonbit
// 解析命令行参数
let cmd = "git commit -m 'Fix issue #123' --author='John Doe <john@example.com>'"
match split(cmd) {
  Ok(words) => {
    println("命令: \{words[0]}")
    println("参数: \{words[1..]}")
  }
  Err(e) => println("解析错误: \{e}")
}

// 构建安全的命令
let args = ["find", "/tmp", "-name", "*.log", "-exec", "rm", "{}", ";"]
let safe_cmd = join(args)
println("安全命令: \{safe_cmd}")
```

### 高级使用

```moonbit
// 命令行解析器
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
        return Err("空命令")
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
    Err(e) => Err("解析错误: " + e.to_string())
  }
}
```

### Unicode支持

```moonbit
// 多语言支持
split("你好 世界") // Ok(["你好", "世界"])
split("'résumé file.pdf'") // Ok(["résumé file.pdf"])
split("café naïve") // Ok(["café", "naïve"])

// 复杂Unicode处理
let unicode_cmd = "find /path -name '文件*.txt' -type f"
match split(unicode_cmd) {
  Ok(words) => println("Unicode解析成功: \{words}")
  Err(e) => println("错误: \{e}")
}
```

## 性能特性

- **高效解析**: 单次遍历算法，时间复杂度O(n)
- **内存优化**: 流式处理，避免不必要的字符串复制
- **Unicode优化**: 原生Unicode支持，无需额外转换
- **错误恢复**: 快速错误检测和报告
- **高覆盖率**: 98.4%测试覆盖率确保可靠性

## 兼容性

这个库在功能和行为上与以下实现保持兼容：

- **Python `shlex`** - 在POSIX模式下的行为
- **Rust `shlex`** - API设计和功能特性
- **GNU Bash** - 基本的词法分析规则

### 主要差异

1. **不支持** 变量展开 (`$VAR`, `${VAR}`)
2. **不支持** 命令替换 (`` `cmd` ``, `$(cmd)`)
3. **不支持** 通配符展开 (`*`, `?`, `[...]`)
4. **不支持** 波浪号展开 (`~`, `~user`)

这些限制确保了库的轻量级和安全性，同时满足大多数词法分析需求。

## 设计理念

这个库遵循POSIX shell的词法分析规则，特别适用于：

- 命令行工具的参数解析
- 配置文件的命令行格式解析
- 需要处理shell风格字符串的应用程序
- 需要安全处理用户输入的场合

## 测试

```bash
# 运行所有测试
moon test

# 运行特定测试
moon test --filter "basic_split"

# 检查测试覆盖率
moon coverage test
moon coverage report
```

## 项目结构

```
src/
├── lib.mbt          # 主要实现和基本测试
├── types.mbt        # 类型定义和错误处理
└── lib_test.mbt     # 全面的测试套件

.github/
└── workflows/       # CI/CD配置
```

## 注意事项

- 单引号内不支持转义（符合POSIX shell标准）
- 双引号内的转义支持有限
- 注释字符 `#` 在引号内会被当作普通字符处理
- 空字符串和只包含空白字符的字符串会返回空数组

## 许可证

本项目采用Apache-2.0 OR MIT双重许可证。

## 贡献

欢迎提交Issue和Pull Request！请确保：

1. 添加适当的测试用例
2. 更新相关文档
3. 遵循现有的代码风格
4. 确保所有测试通过

## 致谢

本库的设计和实现参考了：

- [Python shlex模块](https://docs.python.org/3/library/shlex.html)
- [Rust shlex库](https://github.com/comex/rust-shlex)
- [POSIX Shell语法规范](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html) 