# CleanX — 无广告的 X(Twitter) 客户端（iOS / iPadOS）

一个用 SwiftUI + WKWebView 做的 X 客户端：内嵌 `x.com` 网页，注入 JS/CSS 把官方网页“改造”成你要的样子。**不需要 X 的 API**，用你自己的账号正常登录刷推。

## 功能

- **去广告**：隐藏 `Promoted` / 推广推文、时间线内嵌的“你可能喜欢 / Who to follow”推荐块。
- **自定义界面**：主题切换（跟随系统 / 深色 / 浅色 / 暗蓝），隐藏右侧推荐侧栏。
- **关键字屏蔽**：命中关键字的推文整条隐藏（支持直接写正则）。
- **DeepSeek 翻译**：每条推文下方有“翻译”按钮，调用你自己的 DeepSeek API Key 翻译。

## 目录结构

```
CleanX/
├── CleanX.xcodeproj/          Xcode 工程（双击打开）
├── CleanX/
│   ├── CleanXApp.swift        入口
│   ├── ContentView.swift      主界面 + 底部工具栏
│   ├── WebContainer.swift     WKWebView 封装 + 注入 + 翻译回调
│   ├── AppSettings.swift      设置（UserDefaults 持久化）
│   ├── DeepSeekService.swift  DeepSeek 翻译接口
│   ├── SettingsView.swift     设置面板
│   ├── InjectionScripts.swift 读取注入脚本
│   ├── Resources/
│   │   ├── inject.js          注入脚本（去广告/屏蔽/主题/翻译按钮）
│   │   └── inject.css         注入样式
│   └── Info.plist
└── README.md
```

---

## 一、你需要准备的环境

1. **一台 Mac**（本机即可）。
2. **Xcode**：在 Mac 的 App Store 搜 “Xcode” 安装（免费，约 10 GB，需要 macOS 14+；建议最新版）。
   - 注意：只装“Command Line Tools”是不够的，必须是完整 Xcode。
3. **一个 Apple ID**（免费即可）或 **Apple Developer 账号（$99/年）**：
   - 免费 Apple ID：能装到自己设备，但签名 7 天后要重新连电脑跑一次（重签），或手动在手机设置里“信任开发者”。
   - $99/年：签名有效期长，且能用 TestFlight 把 App 分享给最多 100 名内测用户。

## 二、打开并配置工程

1. 双击 `CleanX.xcodeproj`，用 Xcode 打开。
2. 左侧选中项目 `CleanX` → 选中 TARGETS 下的 `CleanX` → **Signing & Capabilities** 标签页：
   - 勾选 **Automatically manage signing**。
   - **Team** 选择你的 Apple ID（没登录就在 Xcode → Settings → Accounts 里先登录）。
   - 把 **Bundle Identifier** 改成你自己的，例如 `com.yourname.cleanx`（全局唯一，不要用示例的 `com.example.cleanx`，会和别人冲突）。
3. 顶部设备栏选你要运行的设备（iPhone/iPad 连上数据线后会显示）。

## 三、装到自己设备（侧载）

1. iPhone/iPad 用数据线连 Mac，首次连接在手机上点“信任”。
2. Xcode 顶部选择你的设备，按 **▶ Run**（或 Cmd+R）。
3. 第一次会报“未受信任的开发者”：手机 → 设置 → 通用 → VPN 与设备管理 → 点你的开发者 → **信任**。
4. 之后每次改代码再 Run 即可更新。免费账号 7 天到期后，重连 Mac 再 Run 一次即续期。

> 无线调试：Xcode → Window → Devices and Simulators → 勾选 “Connect via network”，之后可拔线。

## 四、用 TestFlight 分享给朋友（可选，需 $99/年账号）

1. 在工程里把 Bundle Identifier 保持全局唯一，Team 用付费账号，Build 一个 **Archive**（菜单 Product → Archive）。
2. 在 Organizer 里点 **Distribute App** → App Store Connect → Upload。
3. 到 [App Store Connect](https://appstoreconnect.apple.com) → 我的 App → 创建同名 App → TestFlight 标签页里添加内部/外部测试员（用邮箱邀请，最多 100 人）。
4. 受邀者在 iPhone 装 **TestFlight** App 后，用邀请链接安装。

> 说明：这一步只做 **TestFlight 内测**，不经过公开 App Store 审核；若要上架 App Store 公开分发，还需单独过审，且“网页套壳类 App”有被拒风险，此处不展开。

## 五、使用说明

1. 打开 App，首次会在内嵌网页里登录你的 X 账号（cookie 会记住，无需反复登录）。
2. 点底部 **齿轮** 打开设置：
   - **翻译**：填 DeepSeek API Key（在 https://platform.deepseek.com 申请）、目标语言（默认“简体中文”）。
   - **过滤**：开关“隐藏广告/推广”“隐藏侧边栏推荐”。
   - **关键字屏蔽**：添加关键字，可直接写正则，如 `(广告|抽奖)` 或 `spam`。
   - **外观**：选主题。
3. 设置实时生效（改完点“保存并应用”或“完成”）。
4. 底部工具栏：← 后退、→ 前进、↻ 刷新、🏠 回首页、⚙ 设置。

## 六、常见问题

- **翻译点了没反应 / 显示“未配置 API Key”**：在设置里填好 DeepSeek API Key。
- **翻译显示“翻译失败”**：检查 Key 是否正确、是否欠费；错误信息会直接显示在按钮位置。
- **广告又出现了**：X 前端 DOM 结构会不定期调整，见下方“维护”小节。

## 七、维护（重要）

本方案依赖 X 网页的结构，X 改版后可能失效。失效时重点看两个文件：

- `CleanX/Resources/inject.js`：广告识别（`placementTracking`、`socialContext`）、推文文本（`[data-testid="tweetText"]`）、`article` 选择器。
- `CleanX/Resources/inject.css`：侧栏（`sidebarColumn`）等选择器。

改法：用电脑浏览器打开 x.com，右键“检查”，找到对应元素的 `data-testid` / class，替换脚本里的选择器即可。

## 八、免责声明

- 本工程仅供**个人学习与自用**，用于在你自己登录的设备上改善浏览体验。
- 它不抓取、不分发 X 的任何数据，也不调用 X 的 API。
- 使用第三方客户端可能与 X 的服务条款冲突，请自行评估风险；作者不对账号封禁等后果负责。
