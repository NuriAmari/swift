// RUN: not %target-swift-frontend(mock-sdk: %clang-importer-sdk) -enable-experimental-clang-importer-diagnostics -typecheck %s 2>&1 | %FileCheck %s --strict-whitespace

import incomplete_types

let bar = Bar()
_ = bar.baz()
// CHECK: incomplete_types.h:{{[0-9]+}}:1: error: method 'baz' not imported
// CHECK-NEXT: - (Baz *)baz;
// CHECK-NEXT: ^
// CHECK-NEXT: incomplete_types.h:{{[0-9]+}}:1: note: return type not imported
// CHECK-NEXT: - (Baz *)baz;
// CHECK-NEXT: ^
// CHECK-NEXT: incomplete_types.h:{{[0-9]+}}:1: note: type 'Baz' is incomplete
// CHECK-NEXT: - (Baz *)baz;
// CHECK-NEXT: ^
// CHECK-NEXT: incomplete_types.h:{{[0-9]+}}:1: note: type 'Baz' forward declared here
// CHECK-NEXT: @class Baz;
// CHECK-NEXT: ^
// CHECK-NEXT: experimental_diagnostics_incomplete_types.swift:6:9: error: value of type 'Bar' has no member 'baz'
// CHECK-NEXT: _ = bar.baz()
// CHECK-NEXT:     ~~~ ^~~

_ = bar.doSomethingWithFoo(nil, andBaz: nil)
// CHECK:     incomplete_types.h:{{[0-9]+}}:1: error: method 'doSomethingWithFoo:andBaz:' not imported
// CHECK-NEXT: - (int)doSomethingWithFoo:(Foo *)foo andBaz:(Baz *)baz;
// CHECK-NEXT: ^
// CHECK-NEXT: incomplete_types.h:{{[0-9]+}}:28: note: parameter 'foo' not imported
// CHECK-NEXT: - (int)doSomethingWithFoo:(Foo *)foo andBaz:(Baz *)baz;
// CHECK-NEXT:                            ^
// CHECK-NEXT: incomplete_types.h:{{[0-9]+}}:28: note: type 'Foo' is incomplete
// CHECK-NEXT: - (int)doSomethingWithFoo:(Foo *)foo andBaz:(Baz *)baz;
// CHECK-NEXT:                            ^
// CHECK-NEXT: incomplete_types.h:{{[0-9]+}}:1: note: type 'Foo' forward declared here
// CHECK-NEXT: @class Foo;
// CHECK-NEXT: ^
// CHECK-NEXT: experimental_diagnostics_incomplete_types.swift:{{[0-9]+}}:9: error: value of type 'Bar' has no member 'doSomethingWithFoo'
// CHECK-NEXT: _ = bar.doSomethingWithFoo(nil, andBaz: nil)
// CHECK-NEXT:     ~~~ ^~~~~~~~~~~~~~~~~~
