# VaporNote 💧

极简水生风格笔记应用，灵感来自 OPPO ColorOS 设计语言。

## 功能特性

- **四合一编辑** — 文字、清单、涂鸦、图片插入
- **水生设计语言** — 平滑物理回弹动效，清新灵动界面
- **ColorOS 风格圆角卡片流** — 主页瀑布流布局
- **长按卡片浮起选中** — 批量删除操作
- **侧滑分类菜单** — 快速切换笔记分类
- **顶部导航栏随滚动透明化** — 无边界沉浸感
- **本地持久化存储** — SQLite 数据库，离线可用
- **卡片颜色自定义** — 6 种水色调主题

## GitHub Actions 构建

### 配置 Secrets

在仓库 `Settings → Secrets and variables → Actions` 中添加以下 Secret：

| Secret 名称 | 值 |
|------------|-----|
| `KEYSTORE_BASE64` | 见下方 keystore base64 内容 |
| `KEY_STORE_PASSWORD` | `VaporNote2024!` |
| `KEY_PASSWORD` | `VaporNote2024!` |
| `KEY_ALIAS` | `vapornote` |

### 发布 Release

1. 进入 GitHub 仓库 → **Actions** → **Build & Release VaporNote APK**
2. 点击 **Run workflow**
3. 输入 Tag（如 `v1.0.0`）
4. 点击 **Run workflow** 开始构建
5. 构建完成后自动创建 Release，下载 `VaporNote-v1.0.0-arm64.apk`

## 本地开发

```bash
flutter pub get
flutter pub run flutter_launcher_icons
flutter run
```

## 技术栈

- Flutter 3.24+
- Provider (状态管理)
- SQLite / sqflite (本地存储)
- signature (涂鸦画板)
- image_picker (图片选择)
- flutter_staggered_animations (列表动画)
