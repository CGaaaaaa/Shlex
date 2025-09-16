# Contributing to MoonBit Shlex

感谢您对 MoonBit Shlex 项目的贡献兴趣！我们欢迎各种形式的贡献，包括但不限于：

- 报告 bug
- 提出新功能建议
- 提交代码修复和改进
- 改进文档
- 添加测试用例

## 开发环境设置

### 前提条件

- MoonBit 编译器和工具链
- Git

### 克隆仓库

```bash
git clone https://github.com/moonbitlang/shlex.git
cd shlex
```

### 运行测试

```bash
# 运行所有测试
moon test

# 运行特定测试
moon test --filter "basic_split"

# 详细输出
moon test --verbose
```

### 构建项目

```bash
# 构建项目
moon build

# 检查语法和类型
moon check
```

## 贡献流程

### 1. 创建 Issue

在开始编码之前，请先创建一个 Issue 来描述：
- 要修复的 bug
- 要添加的功能
- 要改进的地方

### 2. Fork 和分支

1. Fork 这个仓库
2. 创建一个功能分支：
   ```bash
   git checkout -b feature/your-feature-name
   ```

### 3. 编写代码

- 遵循项目的编码规范
- 添加适当的测试
- 确保所有测试通过
- 添加必要的文档

### 4. 提交更改

```bash
git add .
git commit -m "feat: add your feature description"
```

提交信息格式：
- `feat:` 新功能
- `fix:` bug 修复
- `docs:` 文档更新
- `test:` 测试相关
- `refactor:` 代码重构
- `perf:` 性能优化

### 5. 创建 Pull Request

1. 推送到您的 fork：
   ```bash
   git push origin feature/your-feature-name
   ```
2. 创建 Pull Request
3. 填写 PR 模板中的信息

## 编码规范

### 代码风格

- 使用 2 个空格缩进
- 函数名使用 snake_case
- 类型名使用 PascalCase
- 常量使用 UPPER_SNAKE_CASE

### 文档

- 为公共 API 添加文档注释
- 使用 `///` 进行文档注释
- 包含使用示例
- 说明参数和返回值

示例：
```moonbit
/// 将字符串按照 shell 语法分割为单词数组
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
///   Ok(words) => println(words)
///   Err(e) => println("Error: \{e}")
/// }
/// ```
pub fn split(input: String) -> Result[Array[String], ShlexError] {
  // 实现...
}
```

### 测试

- 为新功能添加测试
- 确保测试覆盖边界情况
- 使用描述性的测试名称
- 添加错误情况的测试

示例：
```moonbit
test "split_basic_command" {
  let result = split("ls -la file.txt")
  assert_eq(result, Ok(["ls", "-la", "file.txt"]))
}

test "split_quoted_strings" {
  let result = split("echo 'hello world'")
  assert_eq(result, Ok(["echo", "hello world"]))
}

test "split_unmatched_quotes" {
  let result = split("echo 'unclosed")
  match result {
    Err(UnmatchedQuotes(_, _)) => () // 期望的错误
    _ => abort("Expected UnmatchedQuotes error")
  }
}
```

## 性能考虑

- 避免不必要的字符串复制
- 使用高效的算法
- 考虑大输入的情况
- 添加性能基准测试

## 兼容性

- 保持与 Python shlex 的行为兼容
- 保持与 Rust shlex 的 API 兼容
- 遵循 POSIX shell 语法规范
- 维护向后兼容性

## 发布流程

1. 更新版本号 (`moon.mod.json`)
2. 更新 CHANGELOG.md
3. 确保所有测试通过
4. 创建 release tag
5. 发布到 mooncakes.io

## 问题和支持

- 通过 GitHub Issues 报告 bug
- 通过 GitHub Discussions 提问
- 查看现有的 Issues 和 PRs 避免重复

## 行为准则

我们致力于为每个人提供友好、安全和欢迎的环境。请：

- 使用友好和包容的语言
- 尊重不同的观点和经验
- 优雅地接受建设性批评
- 专注于对社区最有利的事情
- 对其他社区成员表示同理心

## 许可证

通过贡献代码，您同意您的贡献将在与项目相同的许可证下授权（Apache-2.0 OR MIT）。

---

再次感谢您的贡献！🎉 