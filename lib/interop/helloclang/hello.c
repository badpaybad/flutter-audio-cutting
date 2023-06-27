// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <stdio.h>
#include "hello.h"

int main()
{
    //hello_world();
    printf("main() from C\n");
    return 0;
}

// Note:
// ---only on Windows---
// Every function needs to be exported to be able to access the functions by dart.
// Refer: https://stackoverflow.com/q/225432/8608146
// check file hello.def
void hello_world()
{
    printf("Hello World\n");
}

int sum(int a, int b)
{
    printf("c called sum\n");
    return a + b;
}
