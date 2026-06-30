// RUN: %empty-directory(%t)
// RUN: split-file %s %t

// RUN: mkdir -p %t/InternalModule
// RUN: mkdir -p %t/IntermediateModule

// RUN: %target-swift-frontend -enable-experimental-feature SafeImplementationOnly -emit-module -emit-module-path %t/InternalModule/Internal.swiftmodule %t/Internal.swift -parse-as-library -emit-object -o %t/InternalModule/Internal.o
// RUN: %target-swift-frontend -emit-module -emit-module-path %t/IntermediateModule/Intermediate.swiftmodule %t/Intermediate.swift -I %t/InternalModule -parse-as-library -enable-experimental-feature SafeImplementationOnly -emit-object -o %t/IntermediateModule/Intermediate.o

// RUN: %target-swift-frontend -enable-experimental-feature SafeImplementationOnly -emit-ir %t/Client.swift -I %t/IntermediateModule -parse-as-library -o %t/Client.ll

// RUN: %FileCheck %s --check-prefix=CHECK-CLIENT < %t/Client.ll

// UNSUPPORTED: CPU=wasm32
// REQUIRES: swift_feature_SafeImplementationOnly

// When the client uses Wrapper<T> generically without specializing T, the
// hidden field's layout cannot be determined at compile time. Operations
// on Wrapper<T> must go through value witness functions, obtaining the
// metadata for Wrapper<T> and using the value witness table to perform
// copies.

// copyAndGetVisible takes Wrapper<T> indirectly (ptr) and receives T's metadata.
// CHECK-CLIENT: define {{.*}}swiftcc i64 @"$s6Client17copyAndGetVisibleys5Int64V12Intermediate7WrapperVyxGlF"(ptr noalias %0, ptr %T)

// It fetches Wrapper<T>'s metadata by passing T's metadata to the accessor.
// CHECK-CLIENT: call swiftcc %swift.metadata_response @"$s12Intermediate7WrapperVMa"(i64 0, ptr %T)

// It fetches GenericInternal<T>'s metadata by passing T's metadata to the
// hidden type's accessor, so that the value witness table can be used for
// copy and destroy.
// CHECK-CLIENT: call swiftcc %swift.metadata_response @"$s8Internal07GenericA0VMa"(i64 0, ptr %T)

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

//--- Client.swift

import Intermediate

public func copyAndGetVisible<T>(_ w: Wrapper<T>) -> Int64 {
  var copy = w
  return copy.visible
}
