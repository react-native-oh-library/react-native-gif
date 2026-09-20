/**
 * Copyright (c) 2026 Huawei Technologies Co., Ltd.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */
import {
  NativeModules,
  Platform,
  ImageSourcePropType,
  ImageStyle,
} from "react-native";

/** 缩放模式常量形状（与 iOS UIViewContentMode 数值对齐：0=拉伸 1=等比适应 2=等比填满） */
export interface RNFLCoverModes {
  ScaleToFill: number;
  ScaleAspectFit: number;
  ScaleAspectFill: number;
}

// iOS 侧常量来自 RNFLAnimatedImageManager 的 constantsToExport；
// 鸿蒙侧不存在该原生常量模块（NativeModules.RNFLAnimatedImageManager 为
// undefined），直接使用与 iOS UIViewContentMode 完全对齐的数值：
// ScaleToFill = 0, ScaleAspectFit = 1, ScaleAspectFill = 2。
// 注：stock RN 的 PlatformOSType 不含 'harmony'（RNOH 运行时才有），比较前转 string。
const platformOS = Platform.OS as string;
const managerConstants: RNFLCoverModes =
  platformOS === "harmony"
    ? { ScaleToFill: 0, ScaleAspectFit: 1, ScaleAspectFill: 2 }
    : ((NativeModules.RNFLAnimatedImageManager ||
        {}) as RNFLCoverModes);

export const MODES = {
  stretch: managerConstants.ScaleToFill,
  contain: managerConstants.ScaleAspectFit,
  cover: managerConstants.ScaleAspectFill
};

/** onFrameChange 回调事件类型：GIF 每推进一帧触发，帧索引 0..N-1 循环 */
export interface FLAnimatedImageFrameChangeEvent {
  nativeEvent: {
    currentFrameIndex: number;
    frameCount: number;
  };
}

/** onLoadEnd 回调事件类型：成功携带图片宽高 size，失败为空对象 */
export interface FLAnimatedImageLoadEndEvent {
  nativeEvent: {
    size?: { width?: number; height?: number };
  };
}

/** FLAnimatedImage 组件 Props */
export interface FLAnimatedImageProps {
  contentMode?: number;
  source: ImageSourcePropType;
  resizeMode?: keyof typeof MODES;
  style?: ImageStyle;
  onFrameChange?: (event: FLAnimatedImageFrameChangeEvent) => void;
  onLoadEnd?: (event: FLAnimatedImageLoadEndEvent) => void;
}
