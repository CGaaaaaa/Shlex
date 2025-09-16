///|
/// 位置信息，用于错误定位和调试
pub struct Position {
  /// 行号（从1开始）
  line : Int
  /// 列号（从1开始）  
  column : Int
  /// 字符索引（从0开始）
  index : Int
} derive(Show, Eq)

///|
/// Shlex 错误类型
pub enum ShlexError {
  /// 未匹配的引号错误
  /// 
  /// # 参数
  /// - `message`: 错误描述信息
  /// - `position`: 错误发生的位置
  UnmatchedQuotes(String, Position)
  /// 非法的转义序列
  ///
  /// # 参数  
  /// - `message`: 错误描述信息
  /// - `position`: 错误发生的位置
  InvalidEscape(String, Position)
} derive(Show, Eq)

///|
/// 词法分析器配置
pub struct ShlexConfig {
  /// 单引号字符
  single_quote : Char
  /// 双引号字符
  double_quote : Char
  /// 转义字符
  escape_char : Char
  /// 注释字符
  comment_char : Char
  /// 是否启用注释处理
  enable_comments : Bool
  /// 是否启用位置跟踪
  track_positions : Bool
  /// 自定义空白字符集合
  whitespace_chars : Array[Char]
} derive(Show, Eq)

///|
/// 创建默认配置
pub fn ShlexConfig::default() -> ShlexConfig {
  {
    single_quote: '\'',
    double_quote: '"',
    escape_char: '\\',
    comment_char: '#',
    enable_comments: true,
    track_positions: true,
    whitespace_chars: [' ', '\t', '\n', '\r'],
  }
}

///|
/// 创建POSIX兼容的配置
pub fn ShlexConfig::posix() -> ShlexConfig {
  ShlexConfig::default()
}

///|
/// 创建简化配置（禁用注释和位置跟踪以提高性能）
pub fn ShlexConfig::simple() -> ShlexConfig {
  {
    single_quote: '\'',
    double_quote: '"',
    escape_char: '\\',
    comment_char: '#',
    enable_comments: false,
    track_positions: false,
    whitespace_chars: [' ', '\t', '\n', '\r'],
  }
}

///|
/// 结果类型别名，便于使用
pub typealias Result[T, ShlexError] as ShlexResult[T]
