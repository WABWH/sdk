// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/malloc_hooks.h"

#include "vm/globals.h"

#if defined(TARGET_ARCH_MIPS)

namespace dart {

const intptr_t kSkipCount = 5;

}  // namespace dart

#endif  // defined(TARGET_ARCH_MIPS)
