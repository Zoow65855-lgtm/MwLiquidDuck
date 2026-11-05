# MwLiquidDuck — MiniWin 云 Mac 构建仓

这个仓库只有一个用途：用 GitHub Actions 的 macOS 机器
（云 Mac）编译 MiniWin 的 Swift 液态玻璃桥。

MiniWin 的构建机是 Linux，没有 Swift 工具链；而微信
液态底栏要与 Plove 完全一致，玻璃本体必须是 SwiftUI
的 `Color.clear.glassEffect(...)` 托管视图（逆向规格
GLASS-SWIFT-SPEC），只能在 Mac 上编译。

- `bridge/MWGlassBridge.swift` — 桥源码（胶囊玻璃视图
  + 托管表面 + 创建/深色 C 桥，与 Plove 同构）。
- `.github/workflows/build-glass-bridge.yml` — 推送
  `bridge/**` 或手动触发时构建，产出
  `dist/libMWGlassBridge.a`（arm64 / iOS 目标），以
  base64 + sha256 回存到 `dist/`。
- MiniWin 构建侧取回该静态库，链入 MiniWinCmp.dylib；
  设备端 iOS 提供 Swift/SwiftUI 运行时。
