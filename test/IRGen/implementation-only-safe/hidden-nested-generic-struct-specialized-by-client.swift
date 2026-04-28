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

// The hidden field is a nested generic type, Outer<T>.Inner<T>. When the
// client specializes Wrapper<Int64>, the hidden nested type should have a fixed
// layout containing both the substituted outer generic argument and the nested
// generic argument.
// CHECK-CLIENT-DAG: [[HIDDEN:%Ts5Int64V_17s8Internal5OuterVXHgAB_0bcD8V5InnerVXHb]] = type <{ %Ts5Int64V, %Ts5Int64V }>
// CHECK-CLIENT-DAG: %T12Intermediate7WrapperVys5Int64VG = type <{ [[HIDDEN]], %Ts5Int64V }>

// Wrapper<Int64> should be passed directly as the two hidden Int64 fields plus
// the visible Int64 field. The generic makeWrapper<T> entry point remains
// indirect because Wrapper<T> still depends on an unknown T.
// CHECK-CLIENT-DAG: call swiftcc i64 @"$s6Client17copyAndGetVisibleys5Int64V12Intermediate7WrapperVyADGF"(i64 {{%.*}}, i64 {{%.*}}, i64 {{%.*}})
// CHECK-CLIENT-DAG: declare swiftcc void @"$s12Intermediate11makeWrapperyAA0C0VyxGxlF"(ptr noalias sret(%swift.opaque), ptr noalias, ptr)
// CHECK-CLIENT-LABEL: define hidden swiftcc i64 @"$s6Client17copyAndGetVisibleys5Int64V12Intermediate7WrapperVyADGF"(i64 {{%.*}}, i64 {{%.*}}, i64 {{%.*}})
// CHECK-INTERMEDIATE: define {{.*}}swiftcc void @"$s12Intermediate11makeWrapperyAA0C0VyxGxlF"(ptr noalias sret(%swift.opaque) %0, ptr noalias %1, ptr %T)

//--- Internal.swift

public struct Outer<T> {
  public struct Inner<U> {
    public var outer: T
    public var inner: U

    public init(_ outer: T, _ inner: U) {
      self.outer = outer
      self.inner = inner
    }
  }
}

//--- Intermediate.swift

@_implementationOnly import Internal

public struct Wrapper<T> {
  private var hidden: Outer<T>.Inner<T>
  public var visible: Int64 = 1

  public init(_ value: T) {
    self.hidden = Outer<T>.Inner<T>(value, value)
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
