# NekoComic 开发计划

## 概述

NekoComic 是一个基于 Flutter 的模块化漫画阅读器应用，参考 Venera 项目架构设计。当前已完成基础框架搭建，需要继续完善功能以达到生产可用状态。

## 技术方案

| 维度 | 选择 | 理由 |
|------|------|------|
| 状态管理 | Provider | 轻量、Flutter 官方推荐 |
| 路由 | go_router | 声明式路由、支持深链接 |
| 网络 | Dio + RHttp | neko_core 已迁移 |
| 本地存储 | SQLite | neko_core 已迁移 |
| 包管理 | Melos | Monorepo 管理 |

## 功能差距分析

### 已完成 (neko-comic)
- [x] neko_core: 数据模型、存储、网络、同步
- [x] neko_source_js: JS 引擎、API、漫画源系统
- [x] neko_image: 图片加载、缓存
- [x] neko_reader: 阅读器组件
- [x] neko_ui: UI 组件库
- [x] app: 基础页面框架 (Home, Search, Favorites, Settings, Details, Reader)

### 待开发 (对比 Venera)

| 优先级 | 功能模块 | 说明 |
|--------|----------|------|
| P0 | **探索页 (Explore)** | 多源探索页面、Tab 切换 |
| P0 | **分类页 (Categories)** | 分类浏览、筛选 |
| P0 | **搜索结果页** | 搜索结果展示 |
| P1 | **漫画源管理** | 源的添加、启用/禁用、配置 |
| P1 | **历史记录页** | 阅读历史管理 |
| P1 | **本地漫画** | CBZ/EPUB/PDF 导入和阅读 |
| P1 | **下载管理** | 章节下载、进度跟踪 |
| P2 | **追更功能** | 收藏漫画更新检测 |
| P2 | **标签翻译** | EhTag 翻译数据库 |
| P2 | **评论功能** | 漫画评论展示 |
| P2 | **排行榜** | 各源排行榜 |
| P3 | **图片收藏** | 图片收藏夹 |
| P3 | **聚合搜索** | 多源同时搜索 |
| P3 | **WebView 登录** | 源登录验证 |
| P3 | **设置页面完善** | 更多设置项 |

## 实施步骤

### 步骤 1: 完善导航和首页
**目标**: 重构首页和导航，增加探索和分类入口
- 合并 `home_page.dart` 为多 Tab 结构
- 新增底部导航: 首页/探索/分类/我的
- 完善 `shell_scaffold.dart`

### 步骤 2: 探索页 (Explore)
**目标**: 实现多源探索页面
- 创建 `packages/neko_source_js/lib/comic_source/explore.dart`
- 创建 `app/lib/pages/explore/explore_page.dart`
- 实现 ExplorePageData 渲染

### 步骤 3: 分类页 (Categories)
**目标**: 实现分类浏览功能
- 创建 `packages/neko_source_js/lib/comic_source/category.dart`
- 创建 `app/lib/pages/categories/categories_page.dart`
- 创建 `app/lib/pages/categories/category_comics_page.dart`

### 步骤 4: 搜索增强
**目标**: 完善搜索功能
- 创建 `app/lib/pages/search/search_result_page.dart`
- 实现搜索结果分页加载
- 添加源过滤功能

### 步骤 5: 漫画源管理
**目标**: 实现源管理页面
- 创建 `app/lib/pages/sources/comic_source_page.dart`
- 实现源列表、添加源、启用/禁用
- 创建 JS 源加载和验证

### 步骤 6: 历史记录页
**目标**: 实现阅读历史
- 创建 `app/lib/pages/history/history_page.dart`
- 完善 `NekoHistoryManager` 方法
- 添加历史记录操作 (删除、清空)

### 步骤 7: 本地漫画
**目标**: 支持本地漫画文件
- 创建 `packages/neko_core/lib/utils/cbz.dart`
- 创建 `packages/neko_core/lib/utils/epub.dart`
- 创建 `app/lib/pages/local/local_comics_page.dart`

### 步骤 8: 下载管理
**目标**: 实现章节下载
- 创建 `packages/neko_core/lib/download/download_manager.dart`
- 创建 `app/lib/pages/downloads/downloading_page.dart`
- 实现下载队列、暂停/继续/取消

