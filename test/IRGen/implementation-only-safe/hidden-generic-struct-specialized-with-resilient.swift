// Tests that a hidden generic struct specialized with a resilient type
// produces a non-fixed layout that goes through the VWT.

// RUN: %empty-directory(%t)
// RUN: split-file %s %t

// RUN: mkdir -p %t/ResilientModule
// RUN: mkdir -p %t/InternalModule
// RUN: mkdir -p %t/IntermediateModule

// Compile resilient module with library evolution.
// RUN: %target-swift-frontend -enable-experimental-feature SafeImplementationOnly -emit-module -emit-module-path %t/ResilientModule/Resilient.swiftmodule %t/Resilient.swift -parse-as-library -emit-object -o %t/ResilientModule/Resilient.o -enable-library-evolution -module-name Resilient

// Internal module wraps a resilient type in a generic struct.
// RUN: %target-swift-frontend -enable-experimental-feature SafeImplementationOnly -emit-module -emit-module-path %t/InternalModule/Internal.swiftmodule %t/Internal.swift -I %t/ResilientModule -parse-as-library -emit-object -o %t/InternalModule/Internal.o -module-name Internal

// Intermediate module uses the generic struct specialized with the resilient type.
// RUN: %target-swift-frontend -emit-module -emit-module-path %t/IntermediateModule/Intermediate.swiftmodule %t/Intermediate.swift -I %t/InternalModule -I %t/ResilientModule -parse-as-library -enable-experimental-feature SafeImplementationOnly -emit-object -o %t/IntermediateModule/Intermediate.o -module-name Intermediate

// Emit IR for Intermediate.
// RUN: %target-swift-frontend -enable-experimental-feature SafeImplementationOnly -emit-ir %t/Intermediate.swift -I %t/InternalModule -I %t/ResilientModule -parse-as-library -o %t/Intermediate.ll

// Client imports Intermediate and Resilient (a public dependency of Intermediate).
// RUN: %target-swift-frontend -enable-experimental-feature SafeImplementationOnly -emit-ir %t/Client.swift -I %t/IntermediateModule -I %t/ResilientModule -o %t/Client.ll
// RUN: %FileCheck %s < %t/Client.ll
// RUN: %FileCheck --check-prefix=CHECK-INTERMEDIATE %s < %t/Intermediate.ll

// Build and run.
// RUN: %target-build-swift -Xfrontend -enable-experimental-feature -Xfrontend SafeImplementationOnly %t/Client.swift -I %t/IntermediateModule -I %t/ResilientModule %t/ResilientModule/Resilient.o %t/InternalModule/Internal.o %t/IntermediateModule/Intermediate.o -o %t/client-executable
// RUN: %target-run %t/client-executable

// UNSUPPORTED: CPU=wasm32
// REQUIRES: executable_test
// REQUIRES: swift_feature_SafeImplementationOnly

//--- Resilient.swift

public struct ResilientPOD {
  public var x: Int64 = 42
  public init() {}
}

//--- Internal.swift

import Resilient

public struct GenericWrapper<T> {
  public var value: T
  public var extra: Int64 = 7

  public init(_ value: T) {
    self.value = value
  }

  public func getValue() -> T { return value }
  public func getExtra() -> Int64 { return extra }
}

//--- Intermediate.swift

@_implementationOnly import Internal
import Resilient

public struct PublicWrapper {
  private var hidden: GenericWrapper<ResilientPOD> = GenericWrapper(ResilientPOD())
  public var visible: Int64 = 99

  public init() {}

  public func getHiddenValue() -> Int64 {
    return hidden.getValue().x
  }

  public func getHiddenExtra() -> Int64 {
    return hidden.getExtra()
  }
}

public func makePublicWrapper() -> PublicWrapper {
  return PublicWrapper()
}

//--- Client.swift

import Intermediate

var w = makePublicWrapper()
assert(w.visible == 99)
assert(w.getHiddenValue() == 42)
assert(w.getHiddenExtra() == 7)

// The hidden generic struct specialized with a resilient type makes
// PublicWrapper non-fixed. It must be returned indirectly via sret.
// CHECK: declare swiftcc void @"$s12Intermediate17makePublicWrapperAA0cD0VyF"(ptr noalias sret(%swift.opaque))
// CHECK-INTERMEDIATE: define {{.*}}swiftcc void @"$s12Intermediate17makePublicWrapperAA0cD0VyF"(ptr noalias sret(%swift.opaque) %0)
