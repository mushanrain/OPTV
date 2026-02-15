Opt+V 剪贴板历史（SwiftUI 独立版）

功能特性
- 全局快捷键：Option+V 呼出面板，单击即粘贴
- 智能分类：文本 / 链接 / 代码 / 图片
- 毛玻璃面板：NSVisualEffectView（SwiftUI 包裹），原生质感
- 多屏定位：在鼠标所在屏幕附近弹出
- 隐私本地：历史 JSON + 图片 PNG 存储到 App Support
 - 偏好设置：开机自启、菜单栏图标、主题、历史容量/保留期、自定义全局快捷键、权限检查

如何集成到 Xcode（推荐）
1) 打开 Xcode，新建 macOS → App，产品名建议 “OptV”。
2) 关闭 Xcode，将本目录下所有 `.swift` 文件拷贝到你的工程（例如放入 `App/` 分组）。
3) 在目标的 “Signing & Capabilities” 中保持默认（无需额外权限），但运行时需要在“系统设置 → 隐私与安全性 → 辅助功能”里为应用勾选授权，否则无法发送粘贴快捷键。
4) 重新打开工程，编译运行。首次运行按提示到“辅助功能”授予权限。

使用说明
- Option+V：打开面板（若首次可能需要回到“系统设置”授权）。
- 单击条目：自动写入剪贴板并切回之前应用，发送 ⌘V 粘贴。
- 输入搜索：支持标题与副文本匹配。
- Shift+Delete：在面板中删除选中项（可在代码中改键）。
 - 设置窗口：菜单栏图标“📋”→ 设置…，或应用激活时按 Command+, 打开设置。

存储位置
- 历史库：`~/Library/Application Support/OptV/history.json`
- 图片目录：`~/Library/Application Support/OptV/images/`

自定义
- 修改热键：在“设置 → 全局快捷键”中配置，或改 `HotKeyManager.swift`
- 历史长度：在“设置 → 历史与存储”中配置，或改 `HistoryStore.maxItems`
- UI 行数/宽度/缩略图：见 `ContentView.swift` 与 `PanelController.swift`

已知限制
- 发送 ⌘V 需要“辅助功能”权限；若未授权，将无法自动粘贴。
- 真正的“系统毛玻璃”已启用，但不同材质在深色/浅色模式视觉略有差异，可在 `PanelController.swift` 中调整 `material`。
