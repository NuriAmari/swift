// RUN: %empty-directory(%t)
// RUN: split-file %s %t

// RUN: mkdir -p %t/InternalModule
// RUN: mkdir -p %t/IntermediateModule

// RUN: %target-swift-frontend -enable-experimental-feature SafeImplementationOnly -emit-module -emit-module-path %t/InternalModule/Internal.swiftmodule %t/Internal.swift -parse-as-library -emit-object -o %t/InternalModule/Internal.o
// RUN: %target-swift-frontend -emit-module -emit-module-path %t/IntermediateModule/Intermediate.swiftmodule %t/Intermediate.swift -I %t/InternalModule -parse-as-library -enable-experimental-feature SafeImplementationOnly -emit-object -o %t/IntermediateModule/Intermediate.o

// RUN: %target-swift-frontend -enable-experimental-feature SafeImplementationOnly -emit-ir %t/Intermediate.swift -I %t/InternalModule -parse-as-library -o %t/Intermediate.ll
// RUN: %target-swift-frontend -enable-experimental-feature SafeImplementationOnly -emit-ir %t/Client.swift -I %t/IntermediateModule -o %t/Client.ll

// RUN: %FileCheck %s --check-prefix=CHECK-CLIENT < %t/Client.ll
// RUN: %FileCheck %s --check-prefix=CHECK-INTERMEDIATE < %t/Intermediate.ll

// UNSUPPORTED: CPU=wasm32
// REQUIRES: swift_feature_SafeImplementationOnly

// When the client specializes Wrapper<Int64>, it can compute the fixed layout:
// GenericInternal<Int64> contains a single Int64, and Wrapper<Int64> contains
// GenericInternal<Int64> followed by an Int64.
// CHECK-CLIENT-DAG: [[HIDDEN:%Ts5Int64V_22s8Internal07GenericA0VXHg]] = type <{ %Ts5Int64V }>
// CHECK-CLIENT-DAG: %T12Intermediate7WrapperVys5Int64VG = type <{ [[HIDDEN]], %Ts5Int64V }>

// Wrapper<Int64> has a fixed loadable layout in the client, so local uses of
// that specialization should pass it directly as its two Int64 fields.
// CHECK-CLIENT-DAG: call swiftcc i64 @"$s6Client17copyAndGetVisibleys5Int64V12Intermediate7WrapperVyADGF"(i64 {{%.*}}, i64 {{%.*}})

// makeWrapper is generic — Wrapper<T> contains a hidden field whose size
// depends on T, so Wrapper<T> is non-fixed and must be passed indirectly.
// The client's declaration must match the intermediate's definition.
// CHECK-CLIENT-DAG: declare swiftcc void @"$s12Intermediate11makeWrapperyAA0C0VyxGxlF"(ptr noalias sret(%swift.opaque), ptr noalias, ptr)
// CHECK-CLIENT-LABEL: define hidden swiftcc i64 @"$s6Client17copyAndGetVisibleys5Int64V12Intermediate7WrapperVyADGF"(i64 {{%.*}}, i64 {{%.*}})
// CHECK-INTERMEDIATE: define {{.*}}swiftcc void @"$s12Intermediate11makeWrapperyAA0C0VyxGxlF"(ptr noalias sret(%swift.opaque) %0, ptr noalias %1, ptr %T)

// The generic struct GenericInternal is from an @_implementationOnly module.
// The intermediate module's Wrapper is itself generic and forwards its type
// parameter to the hidden field. The layout of the hidden field depends on
// the client's choice of T, so a fixed hidden type representation is not
// possible.

//--- Internal.swift

public struct GenericInternal<T> {
  public var value: T

  public init(_ value: T) {
    self.value = value
  }
}

//--- Intermediate.swift

@_implementationOnly import Internal

public struct Wrapper<T> {
  private var hidden: GenericInternal<T>
  public var visible: Int64 = 1
  public init(_ value: T) {
    self.hidden = GenericInternal<T>(value)
  }
}

public func makeWrapper<T>(_ value: T) -> Wrapper<T> {
  return Wrapper<T>(value)
}

//--- Client.swift

import Intermediate

func copyAndGetVisible(_ w: Wrapper<Int64>) -> Int64 {
  var copy = w
  return copy.visible
}

var s = makeWrapper(Int64(42))
assert(s.visible == 1)
assert(copyAndGetVisible(s) == 1)
