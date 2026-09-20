/**
 * Copyright (c) 2026 Huawei Technologies Co., Ltd.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */
#ifndef GIFPACKAGE_H
#define GIFPACKAGE_H

#pragma once

#include "generated/RNOHGeneratedPackage.h"

namespace rnoh {
class GifPackage : public RNOHGeneratedPackage {
  public:
    using Super = RNOHGeneratedPackage;
    using Super::Super;
};
} // namespace rnoh
#endif //GIFPACKAGE_H
