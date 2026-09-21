# @oh-rn/react-native-gif for HarmonyOS

本项目基于 [react-native-gif](https://github.com/seavan/react-native-gif) 开发，为 React Native 鸿蒙（OpenHarmony）适配版本。

## 版本对应关系

| 鸿蒙适配包版本 | 社区基线版本 | 支持 RN 版本 | Autolink | 编译 API 版本 | 发布信息 |
| ------------ | ------------ | ------------ | -------- | ------------- | -------- |
| 1.0.3 | 1.0.3（https://github.com/seavan/react-native-gif） | 0.72+ | 是 | API12+ | https://gitcode.com/jojobiid/react-native-gif/releases |

npm 地址：`@oh-rn/react-native-gif`

## 安装

```bash
npm install @oh-rn/react-native-gif
# 或
yarn add @oh-rn/react-native-gif
```

## 使用

```tsx
import FLAnimatedImage, { MODES } from 'react-native-gif';

const source = { uri: 'https://example.com/animated.gif' };
const style = { width: 320, height: 240 };

// 远程 GIF（onLoadEnd 成功返回 size 宽高，失败返回空对象）
<FLAnimatedImage
  source={source}
  resizeMode="contain" // 'stretch' | 'contain' | 'cover'，默认 'contain'
  style={style}
  onFrameChange={(e) => {
    // 每推进一帧触发：e.nativeEvent = { currentFrameIndex, frameCount }
  }}
  onLoadEnd={(e) => {
    // 成功：e.nativeEvent.size = { width, height }；失败：空对象
  }}
/>

// 本地静态资源（require，经 asset:// 解析）
<FLAnimatedImage source={require('./loading.gif')} resizeMode="cover" />

// 直传 contentMode 数值（0=拉伸 1=等比适应 2=等比填满，与 iOS UIViewContentMode 对齐）
<FLAnimatedImage source={source} contentMode={MODES.cover} />
```

> import 时使用原库名 `'react-native-gif'`，而非鸿蒙包名 `@oh-rn/react-native-gif`（由 RNOH 的 `harmony.alias` 自动映射）。

**平台差异**：
- `MODES` 常量在 HarmonyOS 上为硬编码数值（`{stretch: 0, contain: 1, cover: 2}`，与 iOS `UIViewContentMode` 对齐）；iOS 侧仍取自 `NativeModules.RNFLAnimatedImageManager` 常量。
- 直传 `contentMode` 数值在 HarmonyOS 端生效（优先于 `resizeMode` 映射）；原库 iOS 端因 JSX 属性覆盖顺序实际忽略直传值。
- `onFrameChange` 由 Image Kit `ImageSource.getDelayTimeList()` 帧延迟表驱动定时上报（ArkUI `Image` 组件不提供组件级逐帧回调）。
- Android 端行为保留：`Platform.OS === 'android'` 时仍回退渲染 RN `<Image>`。

**权限要求**：
- 加载网络 GIF（`http://`/`https://`）需在宿主 `module.json5` 声明 `ohos.permission.INTERNET`（system_grant，无需动态申请）。

## Link

| 版本 | 是否支持 Autolink |
|------|------------------|
| 当前版本 | 是 |

如使用版本支持 Autolink 且工程已接入，可跳过手动配置。

<details>
<summary>Manual Link 配置</summary>

> **说明**：本模块需要同时在 C++ 侧和 ETS 侧注册 Package。

### 1. Overrides RN SDK

在工程根目录 `oh-package.json5` 添加：

```json
{
  "overrides": {
    "@rnoh/react-native-openharmony": "./react_native_openharmony"
  }
}
```

### 2. 引入原生端依赖

打开 `entry/oh-package.json5`，添加：

```json
"dependencies": {
  "@oh-rn/react-native-gif": "file:../../node_modules/@oh-rn/react-native-gif/harmony/gif.har"
}
```

执行 `ohpm install`。

### 3. 配置 CMakeLists

打开 `entry/src/main/cpp/CMakeLists.txt`，添加：

```cmake
set(OH_MODULES "${CMAKE_CURRENT_SOURCE_DIR}/../../../oh_modules")

add_subdirectory("${OH_MODULES}/@oh-rn/react-native-gif/src/main/cpp" ./gif)

target_link_libraries(rnoh_app PUBLIC gif)
```

### 4. 注册 Package（C++ 侧）

打开 `entry/src/main/cpp/PackageProvider.cpp`，添加：

```cpp
#include "GifPackage.h"

std::vector<std::shared_ptr<Package>> PackageProvider::getPackages(Package::Context ctx) {
    return {
        std::make_shared<GifPackage>(ctx),
    };
}
```

### 5. 注册 Package（ETS 侧）

打开 `entry/src/main/ets/RNPackagesFactory.ets`，添加：

```typescript
import { GifPackage } from '@oh-rn/react-native-gif/ts';

export function createRNPackages(ctx: RNPackageContext): RNPackage[] {
  return [
    new GifPackage(ctx),
  ];
}
```

</details>

## 属性 / API

| API | 描述 | 参数 | 返回值 | HarmonyOS 支持 |
|-----|------|------|--------|----------------|
| FLAnimatedImage | GIF 动图渲染组件（默认导出） | — | — | ✅ 完全支持 |
| source | 图片来源：远程 URL / 本地沙箱路径 / `require()` 静态资源 | `ImageSourcePropType` | — | ✅ 完全支持 |
| resizeMode | 缩放模式，默认 `'contain'`，映射 `contentMode` → ArkUI `objectFit` | `'stretch' \| 'contain' \| 'cover'` | — | ✅ 完全支持 |
| contentMode | 数值直传缩放模式（0=拉伸 1=等比适应 2=等比填满） | `number` | — | ✅ 完全支持（原库 iOS 端实际忽略，鸿蒙端使其生效） |
| style | 图片容器样式（宽高/背景/边框等 ViewProps 透传） | `ImageStyle` | — | ✅ 完全支持 |
| onFrameChange | 逐帧事件，GIF 每推进一帧触发一次 | 事件：`{currentFrameIndex, frameCount}` | — | ⚠️ 部分支持（定时驱动，见 API 说明） |
| onLoadEnd | 加载结束事件：成功带 `{size:{width,height}}`，失败为空对象 `{}` | 事件：`{size?}` | — | ✅ 完全支持 |
| MODES | 导出常量 `{stretch, contain, cover}` | — | `{stretch: 0, contain: 1, cover: 2}` | ✅ 完全支持 |

### 事件类型

| 类型名 | 字段 | 说明 | 来源 |
|--------|------|------|------|
| FLAnimatedImageFrameChangeEvent | nativeEvent: `{currentFrameIndex: number, frameCount: number}` | onFrameChange 回调事件类型，帧索引 0..N-1 循环 | 鸿蒙化新增导出 |
| FLAnimatedImageLoadEndEvent | nativeEvent: `{size?: {width?: number, height?: number}}` | onLoadEnd 回调事件类型，成功携带 size，失败为空对象 | 鸿蒙化新增导出 |
| OnFrameChangeEventData | `{currentFrameIndex: Int32, frameCount: Int32}` | Fabric Spec 层逐帧事件负载数据类型 | 鸿蒙化新增（src/specs/v1） |
| OnLoadEndEventData | `{size?: {width: Float, height: Float}}` | Fabric Spec 层加载结束事件负载数据类型 | 鸿蒙化新增（src/specs/v1） |
| RNFLCoverModes | `{ScaleToFill, ScaleAspectFit, ScaleAspectFill}` | 缩放模式常量形状类型（MODES 的类型） | 对齐原库 typedefs |

### 平台差异
- `src` 双路径加载语义与 iOS 对齐：远程 URL 拉取（Network Kit http，15s 超时）失败后回退按本地路径解析，再失败触发 `onLoadEnd({})` 空对象（不是不触发）；成功触发 `onLoadEnd({size:{width,height}})`（宽高来自 Image Kit `ImageSource.getImageInfo()`）。
- `src` 或 `contentMode` 变更会重新加载并再次触发 `onLoadEnd`（对齐 iOS setter → reloadImage 行为）；同 URL 的 `contentMode` 变更换档复用已下载的临时缓存文件，不重复拉网。
- `require()` 静态资源经 `asset://` 解析，直接以 `$rawfile` 渲染（与 RNOH 核心 `Image` 组件同款处理链路）。
- `onFrameChange` 实现方式：ArkUI `Image` 组件无组件级逐帧/当前帧索引回调（ImageAnimator 亦无按帧回调 API），由 `ImageSource.getFrameCount()` + `getDelayTimeList()`（毫秒）驱动定时链上报，帧索引 0..N-1 循环、GIF 延迟 0 按规范回退 100ms。事件序列与帧计数正确，但定时与 ArkUI 内部解码帧相位可能存在小幅累计漂移（`setTimeout` 精度所致）。静态图（frameCount≤1）不触发。

### 使用限制
- 网络源需宿主声明 `ohos.permission.INTERNET`。
- 本地路径仅支持应用沙箱内路径（`file://` 前缀会被剥除归一化后按沙箱路径解析）。

## 目录结构

```
react-native-gif/
├── src/                          # JS/TS 源码
│   ├── FLAnimatedImage.tsx       # 核心组件（三平台分发）
│   ├── typedefs.ts               # Props 类型与 MODES 常量
│   ├── index.ts                  # 包入口
│   └── specs/v1/                 # Fabric Codegen 规格
├── dist/                         # 构建产物（commonjs/module/typescript）
├── harmony/
│   ├── gif.har                   # 鸿蒙 HAR 包
│   └── gif/                      # 鸿蒙原生模块源码
│       ├── index.ets             # 包导出（GifPackage）
│       └── src/main/
│           ├── ets/              # RNFLAnimatedImage.ets / GifPackage.ets / generated
│           ├── cpp/              # C++ 侧（GifPackage.h / generated binder）
│           └── resources/
├── example/                      # 鸿蒙测试工程（App.tsx 六场景 demo + harmony 工程）
├── README.OpenHarmony_CN.md      # 鸿蒙化说明（支持特性/限制）
├── README.OpenSource             # 上游基线声明
├── CHANGELOG.md                  # 变更记录
├── COMMITTERS.md                 # 贡献者
├── LICENSE
└── package.json
```

## 快速验证（运行 Example）

### 前置条件

| 依赖 | 版本要求 |
|------|----------|
| Node.js | >= 18 |
| DevEco Studio | 5.0+ / 6.0+ |
| HarmonyOS SDK | API 12+ |

### 运行步骤

**1. 克隆仓库**

```bash
git clone <仓库地址>
cd <仓库目录>
```

**2. 安装依赖并构建**

```bash
npm install --legacy-peer-deps
npm pack           # 生成 tgz 包（会自动触发 prepare 构建 JS 产物）
```

**3. 进入 example 目录，安装依赖**

```bash
cd example
npm install --legacy-peer-deps
```

**4. 生成 JS Bundle**

```bash
npm run dev
```

产物：`harmony/entry/src/main/resources/rawfile/bundle.harmony.js`

**5. 用 DevEco Studio 打开鸿蒙工程**

- 打开 DevEco Studio
- 选择 `example/harmony` 目录
- 等待 Sync 完成

**6. 编译并运行 HAP**

在 DevEco Studio 中点击运行按钮，将 HAP 安装到设备/模拟器。

> **注意**：Example 中已预置插件依赖和 Package 注册，无需手动配置 Link。

## 约束与限制

### 兼容性

- RNOH: 0.72+（验证版本：0.72.139，@react-native-oh/react-native-harmony）
- HarmonyOS SDK: API 12+（验证于 API 24）
- DevEco Studio: 5.0+（验证于 6.1.1）
- 真机验证设备：HarmonyOS 手机（SN 4DT0224919000576）

## 遗留问题

- `onFrameChange` 的时间驱动为并行定时链，事件序列与帧计数正确，但与 ArkUI `Image` 内部解码帧的绝对相位可能有小幅累计漂移（平台无组件级逐帧回调 API，已查证 ArkUI `Image`/`ImageAnimator` 文档）。
- 直传 `contentMode` 数值在鸿蒙端生效；原库 iOS 端因 JSX 属性覆盖顺序实际忽略直传值（`typedefs.ts` 又将其声明为公开 prop，鸿蒙端按声明使其可配置）。不传时行为与原库逐字节一致。

## 贡献代码

欢迎通过 Issue 与 Pull Request 参与贡献：https://gitcode.com/jojobiid/react-native-gif

- 提交 Issue：https://gitcode.com/jojobiid/react-native-gif/issues
- 提交 PR：fork 仓库后基于 main 分支开发，PR 目标为 main 分支

## 开源协议

本项目基于 MIT License 开发，原库版权见 [LICENSE](./LICENSE) 文件；上游社区版本：https://github.com/seavan/react-native-gif （MIT License）。