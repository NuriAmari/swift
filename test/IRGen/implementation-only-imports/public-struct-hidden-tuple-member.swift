// RUN: %empty-directory(%t)
// RUN: split-file %s %t

// RUN: mkdir -p %t/InternalModule
// RUN: mkdir -p %t/IntermediateModule

// RUN: %target-swift-frontend -emit-module -emit-module-path %t/InternalModule/Internal.swiftmodule %t/Internal.swift -parse-as-library -emit-object -o %t/InternalModule/Internal.o
// RUN: %target-swift-frontend -emit-module -emit-module-path %t/IntermediateModule/Intermediate.swiftmodule %t/Intermediate.swift -I %t/InternalModule -parse-as-library -emit-object -o %t/IntermediateModule/Intermediate.o
// RUN: %target-swift-frontend -emit-ir %t/Intermediate.swift -I %t/InternalModule -o %t/Intermediate.ll
// RUN: %target-swift-frontend -emit-ir %t/Client.swift -I %t/IntermediateModule -o %t/Client.ll
// RUN: %FileCheck %s --check-prefix=INTERMEDIATE < %t/Intermediate.ll
// RUN: %FileCheck %s --check-prefix=CLIENT < %t/Client.ll
// RUN: %target-build-swift %t/Client.swift -I %t/IntermediateModule  %t/InternalModule/Internal.o %t/IntermediateModule/Intermediate.o -o %t/client-executable
// RUN: %target-run %t/client-executable

// REQUIRES: executable_test

//--- Internal.swift

public struct TuplePOD {
  public var pair: (Int64, Int64) = (10, 20)

  public init() {}
}

//--- Intermediate.swift

@_implementationOnly import Internal

public struct PublicWrapper {
  private var hidden: TuplePOD = TuplePOD()
  public var visible: Int64 = 2

  public func getHiddenFirst() -> Int64 {
    return hidden.pair.0
  }

  public func getHiddenSecond() -> Int64 {
    return hidden.pair.1
  }

  public init() {}
}

public func makePublicWrapper() -> PublicWrapper {
  return PublicWrapper()
}

//--- Client.swift

import Intermediate

var s = makePublicWrapper()
assert(s.visible == 2)
assert(s.getHiddenFirst() == 10)
assert(s.getHiddenSecond() == 20)

// Verify that the client has a correct type representation for PublicWrapper.
// The hidden TuplePOD field should be lowered to a struct containing the
// tuple (Int64, Int64), and the visible Int64 field should follow it.
// CLIENT: %T12Intermediate13PublicWrapperV = type <{ %hidden_struct, %Ts5Int64V }>
// CLIENT: %hidden_struct = type <{ <{ %Ts5Int64V, %Ts5Int64V }> }>

// Verify that the calling conventions for makePublicWrapper match between
// the intermediate module and the client module.
// INTERMEDIATE: define {{.*}}swiftcc { i64, i64, i64 } @"$s12Intermediate17makePublicWrapperAA0cD0VyF"()
// CLIENT: declare {{.*}}swiftcc { i64, i64, i64 } @"$s12Intermediate17makePublicWrapperAA0cD0VyF"()
