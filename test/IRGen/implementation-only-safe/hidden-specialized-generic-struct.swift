// RUN: %empty-directory(%t)
// RUN: split-file %s %t

// RUN: mkdir -p %t/InternalModule
// RUN: mkdir -p %t/IntermediateModule

// RUN: %target-swift-frontend -enable-experimental-feature SafeImplementationOnly -emit-module -emit-module-path %t/InternalModule/Internal.swiftmodule %t/Internal.swift -parse-as-library -emit-object -o %t/InternalModule/Internal.o
// RUN: %target-swift-frontend -emit-module -emit-module-path %t/IntermediateModule/Intermediate.swiftmodule %t/Intermediate.swift -I %t/InternalModule -parse-as-library -enable-experimental-feature SafeImplementationOnly -emit-object -o %t/IntermediateModule/Intermediate.o

// RUN: %target-swift-frontend -enable-experimental-feature SafeImplementationOnly -emit-ir %t/Client.swift -I %t/IntermediateModule -o %t/Client.ll
// RUN: %target-swift-frontend -enable-experimental-feature SafeImplementationOnly -emit-ir %t/Intermediate.swift -I %t/InternalModule -parse-as-library -o %t/Intermediate.ll

// RUN: %FileCheck %s --check-prefix=CHECK-CLIENT < %t/Client.ll
// RUN: %FileCheck %s --check-prefix=CHECK-INTERMEDIATE < %t/Intermediate.ll

// UNSUPPORTED: CPU=wasm32
// REQUIRES: swift_feature_SafeImplementationOnly

// The client reconstructs GenericInternal<Int64> as a single-field struct
// wrapping Int64, and Wrapper as {hidden, visible}.
// CHECK-CLIENT-DAG: [[HIDDEN:%Ts5Int64V_22s8Internal07GenericA0VXHg]] = type <{ %Ts5Int64V }>
// CHECK-CLIENT-DAG: %T12Intermediate7WrapperV = type <{ [[HIDDEN]], %Ts5Int64V }>

// The intermediate module sees the same layout.
// CHECK-INTERMEDIATE-DAG: %T8Internal07GenericA0Vys5Int64VG = type <{ %Ts5Int64V }>
// CHECK-INTERMEDIATE-DAG: %T12Intermediate7WrapperV = type <{ %T8Internal07GenericA0Vys5Int64VG, %Ts5Int64V }>

// makeWrapper returns Wrapper exploded as a pair of i64.
// The client's declaration must match the intermediate's definition.
// CHECK-CLIENT: declare swiftcc { i64, i64 } @"$s12Intermediate11makeWrapperAA0C0VyF"()
// CHECK-INTERMEDIATE: define {{.*}}swiftcc { i64, i64 } @"$s12Intermediate11makeWrapperAA0C0VyF"()

//--- Internal.swift

public struct GenericInternal<T> {
  public var value: T

  public init(_ value: T) {
    self.value = value
  }
}

//--- Intermediate.swift

@_implementationOnly import Internal

public struct Wrapper {
  private var hidden: GenericInternal<Int64> = GenericInternal<Int64>(42)
  public var visible: Int64 = 1
  public init() {}
}

public func makeWrapper() -> Wrapper {
  return Wrapper()
}

//--- Client.swift

import Intermediate

func copyAndGetVisible(_ w: Wrapper) -> Int64 {
  var copy = w
  return copy.visible
}

var s = makeWrapper()
assert(s.visible == 1)
assert(copyAndGetVisible(s) == 1)
