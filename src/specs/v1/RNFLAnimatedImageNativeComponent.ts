/**
 * Copyright (c) 2026 Huawei Technologies Co., Ltd.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */
/**
 * RNFLAnimatedImage Fabric Spec（新架构）。
 *
 * 由旧架构 `requireNativeComponent("RNFLAnimatedImage")` 手写转换而来：
 * - 组件名必须保持 `RNFLAnimatedImage`，与 ArkTS 侧 RNC.RNFLAnimatedImage.NAME、
 *   C++ 侧 ComponentDescriptor 的注册名完全一致；
 * - 原生 props 对齐 iOS ViewManager（src: string / contentMode: number）与
 *   两个直接事件（onFrameChange / onLoadEnd）。
 */
import type { ViewProps } from "react-native/Libraries/Components/View/ViewPropTypes";
import type { HostComponent } from "react-native";
import codegenNativeComponent from "react-native/Libraries/Utilities/codegenNativeComponent";
import type {
  Int32,
  Float,
  DirectEventHandler,
} from "react-native/Libraries/Types/CodegenTypes";

export type OnFrameChangeEventData = Readonly<{
  currentFrameIndex: Int32;
  frameCount: Int32;
}>;

export type OnLoadEndEventData = Readonly<{
  // 事件负载里的嵌套结构必须内联声明（codegen 不解析命名类型别名）
  size?: { width: Float; height: Float };
}>;

export interface NativeProps extends ViewProps {
  /** 图片地址：远程 URL 或本地（沙箱）路径 */
  src?: string;
  /** 缩放模式数值，语义对齐 iOS UIViewContentMode（0=拉伸 1=等比适应 2=等比填满） */
  contentMode?: Int32;
  /** 每推进一帧触发一次 */
  onFrameChange?: DirectEventHandler<OnFrameChangeEventData>;
  /** 加载结束触发：成功带 size；失败为空对象（与原库一致） */
  onLoadEnd?: DirectEventHandler<OnLoadEndEventData>;
}

export default codegenNativeComponent<NativeProps>(
  "RNFLAnimatedImage"
) as HostComponent<NativeProps>;
