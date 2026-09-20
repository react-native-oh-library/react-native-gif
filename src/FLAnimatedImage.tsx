/**
 * Copyright (c) 2026 Huawei Technologies Co., Ltd.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */
import React, { Component, ComponentType } from "react";
import {
  Platform,
  Image,
  requireNativeComponent,
} from "react-native";
import RNFLAnimatedImageNativeComponent from "./specs/v1/RNFLAnimatedImageNativeComponent";
import { FLAnimatedImageProps, MODES } from "./typedefs";

// iOS 旧架构组件按需懒加载：harmony（新架构）运行时不求值 requireNativeComponent
let RNFLAnimatedImageLegacy: ComponentType<any> | null = null;

class FLAnimatedImage extends Component<FLAnimatedImageProps> {
  static defaultProps = {
    resizeMode: "contain"
  };

  render() {
    if (Platform.OS === "android") {
      // 保持原库行为：全部 props 透传给 RN Image（cast 仅为绕过 onLoadEnd 事件类型差异）
      return <Image {...(this.props as any)} />;
    }
    const contentMode =
      this.props.contentMode !== undefined
        ? this.props.contentMode
        : MODES[this.props.resizeMode || "contain"];
    const source = Image.resolveAssetSource(this.props.source) || {
      uri: undefined,
      width: undefined,
      height: undefined
    };
    const src = source.uri;
    if ((Platform.OS as string) === "harmony") {
      return (
        <RNFLAnimatedImageNativeComponent
          {...this.props}
          src={src}
          contentMode={contentMode}
        />
      );
    }
    if (!RNFLAnimatedImageLegacy) {
      RNFLAnimatedImageLegacy = requireNativeComponent("RNFLAnimatedImage");
    }
    const RNFLAnimatedImage = RNFLAnimatedImageLegacy;
    return (
      <RNFLAnimatedImage {...this.props} src={src} contentMode={contentMode} />
    );
  }
}

export default FLAnimatedImage;
