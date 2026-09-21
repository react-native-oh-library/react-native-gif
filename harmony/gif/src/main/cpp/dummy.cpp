/**
 * Copyright (c) 2026 Huawei Technologies Co., Ltd.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */
// 占位源文件：纯 ArkTS Fabric 组件的 codegen C++ 胶水均为头文件（模板内联实现），
// 无任何 .cpp 时 file(GLOB) 为空 → add_library(gif) 报 No SOURCES（见 lessons: cmake-no-sources-dummy）。
// C++ 侧注册实际由 GifPackage.h（继承 RNOHGeneratedPackage）在消费端编译时实例化。
