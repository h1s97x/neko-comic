# 开发指南

## 1. 环境准备

### 1.1 安装依赖

```bash
# Flutter SDK
# https://flutter.dev/docs/get-started/install

# Melos (包管理)
dart pub global activate melos

# Rust (部分 native 依赖需要)
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

### 1.2 环境变量

```bash
export PATH="$PATH:$HOME/.pub-cache/bin"
```

---

## 2. 项目结构

```
neko-comic/
├── packages/           # 所有 Package
│   ├── neko_core/      # 核心层
│   ├── neko_source_js/ # JS 漫画源
│   ├── neko_image/     # 图片处理
│   ├── neko_reader/    # 阅读器
│   └── neko_ui/        # UI 组件
├── app/                # 主应用
├── doc/                # 文档
└── melos.yaml          # Melos 配置
```

---

## 3. 日常开发

### 3.1 初始化项目

```bash
# 使用 melos 引导所有包
melos bootstrap

# 或使用 flutter
flutter pub get
```

### 3.2 代码分析

```bash
melos analyze
```

### 3.3 运行测试

```bash
melos test
```

### 3.4 构建应用

```bash
# Android
melos build:app

# 或者直接构建
cd app
flutter build apk --release
```

---

## 4. Package 开发规范

### 4.1 命名规范

| 类型 | 规范 | 示例 |
|------|------|------|
| Package 目录 | snake_case | `neko_core`, `neko_source_js` |
| Dart 文件 | snake_case | `comic_card.dart` |
| 类名 | PascalCase | `class ComicReader` |
| 私有成员 | `_underscore` | `_internalState` |

### 4.2 代码导出

每个 Package 必须提供统一入口：

```dart
// neko_core.dart
library neko_core;

export 'comic/models.dart';
export 'storage/database.dart';
export 'network/client.dart';
```

### 4.3 错误处理

```dart
class NekoException implements Exception {
  final String message;
  final int? code;

  NekoException(this.message, {this.code});
}
```

---

## 5. Git 工作流

### 5.1 分支命名

```
feature/xxx          # 新功能
fix/xxx              # 修复
docs/xxx             # 文档
refactor/xxx         # 重构
```

### 5.2 提交规范

```
feat: 添加新功能
fix: 修复 bug
docs: 更新文档
refactor: 重构代码
test: 添加测试
chore: 构建/工具变动
```

---

## 6. 发布流程

### 6.1 版本号规范

使用语义化版本 `MAJOR.MINOR.PATCH`

- MAJOR: 不兼容的 API 变更
- MINOR: 向后兼容的功能
- PATCH: 向后兼容的修复

### 6.2 发布检查清单

- [ ] 所有测试通过
- [ ] 代码分析无警告
- [ ] 更新 CHANGELOG
- [ ] 更新版本号
- [ ] 打标签
