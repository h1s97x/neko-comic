# NekoComic 架构设计

## 1. 项目概述

### 1.1 项目背景

NekoComic 是基于 Venera 核心能力重新设计的漫画阅读器，采用 **核心层 + Packages** 的模块化架构。

**核心设计理念**：
- 模块化：将核心功能拆分为独立 Packages
- 可扩展：保留 JS 漫画源插件系统
- 跨平台：支持 Android, iOS, Windows, Linux, macOS

### 1.2 项目来源

- **Venera**: https://github.com/venera-app/venera (停止维护)
- 核心能力参考自 Venera，架构重新设计

---

## 2. 整体架构

```
┌─────────────────────────────────────────────────────────────┐
│                        NekoComic App                         │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │  neko_core   │  │   neko_ui   │  │ neko_reader  │      │
│  │   (核心层)    │  │   (UI组件)  │  │   (阅读器)   │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
│                                                             │
│  ┌──────────────┐  ┌──────────────┐                        │
│  │neko_source_js│  │ neko_image   │                        │
│  │  (JS漫画源)   │  │  (图片处理)  │                        │
│  └──────────────┘  └──────────────┘                        │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 3. Package 依赖关系

```
app (主应用)
    ├── neko_ui
    │     └── flutter
    ├── neko_reader
    │     └── flutter
    ├── neko_source_js
    │     ├── flutter_qjs
    │     ├── neko_core
    │     │     ├── dio
    │     │     ├── sqlite3
    │     │     └── crypto
    │     └── neko_image
    └── neko_image
          └── flutter
```

---

## 4. Package 详细设计

### 4.1 neko_core (核心层)

**职责**: 漫画数据结构、存储、网络、同步

**核心模块**:
- `comic/` - 数据模型定义
- `storage/` - SQLite、收藏、历史
- `network/` - HTTP 客户端、Cloudflare 绕过
- `sync/` - WebDAV 同步

### 4.2 neko_source_js (JS 漫画源)

**职责**: JavaScript 引擎封装、漫画源加载、JS API 实现

**核心模块**:
- `js_engine.dart` - JS 引擎封装
- `js_pool.dart` - 引擎池管理
- `api/` - JS API (Network, Html, Convert, Utils)

**JS API 兼容性**: 保持与 Venera 兼容

### 4.3 neko_reader (阅读器)

**职责**: 漫画阅读界面、手势控制、阅读布局

**核心模块**:
- `reader.dart` - 阅读器主组件
- `layouts/` - 多种布局 (LTR, RTL, Vertical, Webtoon)
- `controls/` - 控制面板

### 4.4 neko_ui (UI 组件)

**职责**: 可复用 UI 组件、漫画卡片、网格、骨架屏

**核心模块**:
- `comic/` - 漫画卡片、网格、列表
- `loading/` - 骨架屏组件
- `layout/` - 响应式布局

### 4.5 neko_image (图片处理)

**职责**: 图片加载、缓存、预加载

**核心模块**:
- `image_loader.dart` - 图片加载器
- `cache/` - 缓存管理
- `providers/` - 图片来源

---

## 5. 迁移计划

### Phase 1: neko_core
- [ ] 创建目录结构
- [ ] 迁移数据模型
- [ ] 迁移存储功能
- [ ] 迁移网络功能

### Phase 2: neko_source_js
- [ ] JS 引擎封装
- [ ] JS API 实现
- [ ] 漫画源加载器

### Phase 3: neko_image
- [ ] 图片加载器
- [ ] 缓存管理
- [ ] 预加载功能

### Phase 4: neko_reader
- [ ] 阅读器组件
- [ ] 多种布局
- [ ] 手势控制

### Phase 5: neko_ui
- [ ] UI 组件库
- [ ] 骨架屏
- [ ] 响应式布局

### Phase 6: app
- [ ] 主应用整合
- [ ] 页面开发
- [ ] 测试

---

## 6. 技术选型

| 组件 | 技术 |
|------|------|
| 框架 | Flutter 3.41.4 |
| 包管理 | Melos |
| JS 引擎 | flutter_qjs (fork) |
| HTTP | dio |
| 数据库 | sqlite3 |
| 加密 | crypto, pointycastle |
