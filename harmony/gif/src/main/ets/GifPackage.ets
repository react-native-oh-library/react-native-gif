/**
 * Copyright (c) 2026 Huawei Technologies Co., Ltd.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */
/**
 * react-native-gif 鸿蒙侧 RNPackage：
 * - createDescriptorWrapperFactoryByDescriptorType 注册 RNFLAnimatedImage 的 Descriptor 工厂
 *   （缺此项 Fabric 组件不渲染，见 lessons: fabric-descriptor-factory-missing）；
 * - createWrappedCustomRNComponentBuilderByComponentNameMap 提供组件 Builder，
 *   供 example 侧 arkTsComponentNames 路由。
 */

import {
  RNOHPackage,
  ComponentBuilderContext,
} from '@rnoh/react-native-openharmony';
import type {
  DescriptorWrapperFactoryByDescriptorTypeCtx,
  DescriptorWrapperFactoryByDescriptorType,
} from '@rnoh/react-native-openharmony/ts';
import { RNC } from './generated';
import { RNFLAnimatedImage } from './RNFLAnimatedImage';

@Builder
export function buildRNFLAnimatedImage(ctx: ComponentBuilderContext) {
  RNFLAnimatedImage({ ctx: ctx.rnComponentContext, tag: ctx.tag })
}

export class GifPackage extends RNOHPackage {
  createDescriptorWrapperFactoryByDescriptorType(
    _ctx: DescriptorWrapperFactoryByDescriptorTypeCtx
  ): DescriptorWrapperFactoryByDescriptorType {
    const result: DescriptorWrapperFactoryByDescriptorType = {};
    result[RNC.RNFLAnimatedImage.NAME] = (dctx) =>
      new RNC.RNFLAnimatedImage.DescriptorWrapper(dctx.descriptor);
    return result;
  }

  createWrappedCustomRNComponentBuilderByComponentNameMap(): Map<string, WrappedBuilder<[ComponentBuilderContext]>> {
    return new Map<string, WrappedBuilder<[ComponentBuilderContext]>>().set(
      RNFLAnimatedImage.NAME,
      wrapBuilder(buildRNFLAnimatedImage)
    );
  }
}
