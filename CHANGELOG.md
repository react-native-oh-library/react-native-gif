# Changelog

本文件记录 @oh-rn/react-native-gif（react-native-gif 鸿蒙化适配）的全部重要变更。

格式参照 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/)，版本遵循 [SemVer](https://semver.org/lang/zh-CN/)。

## [1.0.3] - 2026-09-14

基于上游社区版本 [seavan/react-native-gif 1.0.3](https://github.com/seavan/react-native-gif) 的鸿蒙化首次适配。

### 新增

- 鸿蒙（RNOH 0.72+）平台支持：以 Fabric 新架构实现 `RNFLAnimatedImage` 原生组件（ArkTS + C++ Codegen 胶水），支持 Autolink。
- `source` 三种图片来源：远程 URL（Network Kit 拉流，失败回退本地路径）、应用沙箱路径、`require()` 静态资源（`asset://` → `$rawfile`）。
- `resizeMode`（stretch/contain/cover，默认 contain）与 `contentMode` 数值直传（对齐 iOS UIViewContentMode，鸿蒙端生效）。
- `onLoadEnd` 事件：成功回传 `{size:{width,height}}`，失败回传空对象（对齐 iOS 双路径语义）。
- `onFrameChange` 逐帧事件：由 Image Kit `getFrameCount()`/`getDelayTimeList()`（毫秒）驱动定时链上报 `{currentFrameIndex, frameCount}`。
- 事件类型导出：`FLAnimatedImageFrameChangeEvent`、`FLAnimatedImageLoadEndEvent` 等（见 README「事件类型」）。
- 示例工程 `example/`：六场景 demo（远程 GIF、resizeMode 切换、静态 PNG、本地 require、无效 URL 失败、本地路径不存在失败）。

### 兼容

- RNOH 0.72+，HarmonyOS SDK API 12+，DevEco Studio 5.0+。
- Android 平台保持原库行为（回退 RN `<Image>`）；iOS 平台保留原库旧架构链路。

### 已知限制

- ArkUI `Image` 无组件级逐帧回调，`onFrameChange` 为帧延迟表驱动的定时链实现，与解码帧相位可能存在小幅累计漂移（事件序列与帧计数正确）。
- 网络图片无磁盘/内存缓存，临时文件随组件卸载删除（对齐原库 iOS 行为）。
