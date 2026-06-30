// RUN: %empty-directory(%t)
// RUN: split-file %s %t

// RUN: mkdir -p %t/InternalModule
// RUN: mkdir -p %t/IntermediateModule

// RUN: %target-swift-frontend -enable-experimental-feature SafeImplementationOnly -emit-module -emit-module-path %t/InternalModule/Internal.swiftmodule %t/Internal.swift -parse-as-library -emit-object -o %t/InternalModule/Internal.o
// RUN: %target-swift-frontend -emit-module -emit-module-path %t/IntermediateModule/Intermediate.swiftmodule %t/Intermediate.swift -I %t/InternalModule -parse-as-library -enable-experimental-feature SafeImplementationOnly -emit-object -o %t/IntermediateModule/Intermediate.o

// RUN: %target-swift-frontend -enable-experimental-feature SafeImplementationOnly -emit-ir %t/Intermediate.swift -I %t/InternalModule -parse-as-library -o %t/Intermediate.ll
// RUN: %target-swift-frontend -enable-experimental-feature SafeImplementationOnly -emit-ir %t/Client.swift -I %t/IntermediateModule -parse-as-library -o %t/Client.ll

// RUN: %FileCheck %s --check-prefix=CHECK-INTERMEDIATE < %t/Intermediate.ll
// RUN: %FileCheck %s --check-prefix=CHECK-CLIENT < %t/Client.ll

// UNSUPPORTED: CPU=wasm32
// REQUIRES: swift_feature_SafeImplementationOnly

// This test catches a hidden-type analogue of SILType::getFieldType's
// AbstractionPattern handling.
//
// GenericValueField<Int64.Type>.value has:
//   original field pattern: T
//   substituted field type: Int64.Type
//
// A metatype substituted through an arbitrary generic value slot is represented
// as a thick metatype pointer. If hidden generic field lowering keeps only the
// substituted field type and drops the original field abstraction pattern, the
// client can incorrectly derive the thin Int64.Type convention for
// AbstractWrapper. That would make the client's declaration of acceptAbstract
// disagree with the intermediate module's definition.
//
// Full-definition lowering in the intermediate module passes AbstractWrapper
// as its hidden thick metatype pointer followed by its visible Int64.
// CHECK-INTERMEDIATE-DAG: define {{.*}}swiftcc i64 @"$s12Intermediate14acceptAbstract{{.*}}"(ptr {{%.*}}, i64 {{%.*}})

// Hidden-client lowering must derive the same public ABI from serialized
// hidden layout information.
// CHECK-CLIENT-DAG: declare swiftcc i64 @"$s12Intermediate14acceptAbstract{{.*}}"(ptr, i64)

//--- Internal.swift

public struct GenericValueField<T> {
  public var value: T

  public init(_ value: T) {
    self.value = value
  }
}

//--- Intermediate.swift

@_implementationOnly import Internal

public struct AbstractWrapper {
  private var hidden: GenericValueField<Int64.Type>
  public var visible: Int64

  public init(visible: Int64) {
    self.hidden = GenericValueField<Int64.Type>(Int64.self)
    self.visible = visible
  }
}

@inline(never)
public func acceptAbstract(_ w: AbstractWrapper) -> Int64 {
  return w.visible
}

public func makeAbstract() -> AbstractWrapper {
  return AbstractWrapper(visible: 1)
}

//--- Client.swift

import Intermediate

public func useAbstract(_ w: AbstractWrapper) -> Int64 {
  return acceptAbstract(w)
}

public func exercise() -> Int64 {
  return useAbstract(makeAbstract())
}
