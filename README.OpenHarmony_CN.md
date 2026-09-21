# react-native-gif for OpenHarmony（鸿蒙）

本库基于 [seavan/react-native-gif](https://github.com/seavan/react-native-gif) v1.0.3 适配，为 React Native 鸿蒙（RNOH）提供 GIF 动图渲染组件 `FLAnimatedImage`：支持远程 URL、本地沙箱路径、`require()` 静态资源三种图片来源，`resizeMode`/`contentMode` 缩放模式，以及 `onLoadEnd` / `onFrameChange` 事件。

## 版本对应关系

| 鸿蒙适配包版本 | 原始库版本 | 支持 RN 版本 | Autolink | 编译 API 版本 |
| -------------- | ---------- | ------------ | -------- | ------------- |
| 1.0.3 | 1.0.3 | 0.72+ | 是 | API 12+ |

## 安装

```bash
npm install @oh-rn/react-native-gif
```

> import 时使用原库名 `'react-native-gif'`，而非鸿蒙包名 `@oh-rn/react-native-gif`（由 RNOH 的 `harmony.alias` 自动映射）。

## Link

| 版本 | 是否支持 Autolink |
| ---- | ----------------- |
| 0.72+ | 是 |

如工程已接入 Autolink，可跳过手动配置。手动 Link（C++ 侧 GifPackage + ETS 侧 GifPackage 双注册、oh-package.json5、CMakeLists）见 [README.md](./README.md) 的 Manual Link 章节。

## 支持特性

| 特性 | 说明 |
| ---- | ---- |
| FLAnimatedImage 组件 | 默认导出，GIF 动图渲染（ArkUI Fabric 组件） |
| source：远程 URL | http/https，Network Kit 拉取（15s 超时），失败回退本地路径语义 |
| source：本地沙箱路径 | `file://` 前缀剥除、URI 解码归一化后按沙箱路径解析 |
| source：require() 静态资源 | `asset://` → `$rawfile`（与 RNOH 核心 Image 同款链路） |
| resizeMode | `stretch` / `contain` / `cover`，默认 `contain`，经 MODES 映射 contentMode → ArkUI objectFit |
| contentMode | 数值直传（0=拉伸 1=等比适应 2=等比填满，对齐 iOS UIViewContentMode），优先于 resizeMode |
| onLoadEnd 事件 | 成功 `{size:{width,height}}`（宽高来自 Image Kit `getImageInfo()`）；失败 `{}` 空对象 |
| onFrameChange 事件 | `{currentFrameIndex, frameCount}`，由 `getFrameCount()` + `getDelayTimeList()`（毫秒）驱动定时链上报，帧索引 0..N-1 循环 |
| MODES 常量 | `{stretch: 0, contain: 1, cover: 2}` |
| 动态换图 / 换模式 | `src` 或 `contentMode` 变更重新加载并再次触发 onLoadEnd；同 URL 换 contentMode 复用已下载临时文件 |

## 不支持 / 限制

| 项 | 说明 |
| -- | ---- |
| onFrameChange 帧相位 | ArkUI `Image` 无组件级逐帧回调，定时链与解码帧相位可能小幅累计漂移（setTimeout 精度所致）；事件序列与帧计数正确 |
| 网络图片缓存 | 无磁盘/内存缓存，临时文件随组件卸载删除（对齐原库 iOS dataWithContentsOfURL 行为） |
| 静态图逐帧事件 | frameCount ≤ 1 不触发 onFrameChange（对齐设计） |
| Android 平台 | 回退渲染 RN `<Image>`（保持原库行为） |
| iOS 平台 | 保留原库旧架构链路；新架构（RN 0.76+）下 MODES 常量不可用，未验证 |
| 网络权限 | 加载网络 GIF 需宿主 `module.json5` 声明 `ohos.permission.INTERNET`（system_grant） |
| 本地路径范围 | 仅支持应用沙箱内路径 |

## 使用示例

```tsx
import FLAnimatedImage, { MODES } from 'react-native-gif';

// 远程 GIF（onLoadEnd 成功返回 size 宽高，失败返回空对象）
<FLAnimatedImage
  source={{ uri: 'https://example.com/animated.gif' }}
  resizeMode="contain" // 'stretch' | 'contain' | 'cover'，默认 'contain'
  style={{ width: 320, height: 240 }}
  onFrameChange={(e) => {
    // e.nativeEvent = { currentFrameIndex, frameCount }
  }}
  onLoadEnd={(e) => {
    // 成功：e.nativeEvent.size = { width, height }；失败：空对象
  }}
/>

// 本地静态资源（require，经 asset:// 解析）
<FLAnimatedImage source={require('./loading.gif')} resizeMode="cover" />

// 直传 contentMode 数值（0=拉伸 1=等比适应 2=等比填满）
<FLAnimatedImage source={source} contentMode={MODES.cover} />
```

完整 API 属性表与平台差异说明见 [README.md](./README.md)。

## 快速验证（Example）

```bash
npm install --legacy-peer-deps   # 库根目录
npm pack
cd example
npm install --legacy-peer-deps
npm run dev                       # 产物 harmony/entry/src/main/resources/rawfile/bundle.harmony.js
```

用 DevEco Studio 打开 `example/harmony`，运行 HAP。Example 覆盖 6 个场景：远程 GIF（逐帧/加载事件）、resizeMode 三模式切换、静态 PNG、本地 require() 资源、无效 URL 加载失败、本地路径不存在加载失败。

## 约束与限制

- RNOH：0.72+
- HarmonyOS SDK：API 12+
- DevEco Studio：5.0+

## 开源协议

本项目基于 [MIT License](https://github.com/seavan/react-native-gif/blob/master/LICENSE) 开发，原库版权见 [LICENSE](./LICENSE)。鸿蒙适配部分遵循同一 MIT 协议。
