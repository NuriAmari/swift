// RUN: %empty-directory(%t)
// RUN: %target-clang %S/Inputs/custom-modules/ForwardDeclarations/forward-declarations.m -c -o %t/forward-declarations.o
// RUN: %target-build-swift -I %S/Inputs/custom-modules/ForwardDeclarations %s -Xlinker -framework -Xlinker Foundation -Xlinker %t/forward-declarations.o -o %t/a.out
// RUN: %target-run %t/a.out 2>&1 | %FileCheck %s

// REQUIRES: executable_test
// REQUIRES: OS=macosx

import ForwardDeclarations

// Interfaces
let bar = Bar()!
let a = bar.methodReturningForwardDeclaredInterface()!
// CHECK: ForwardDeclaredInterface doing something!
// CHECK: ForwardDeclaredInterface doing something!
bar.methodTakingAForwardDeclaredInterface(asAParameter: a, andAnother: a)
bar.propertyUsingAForwardDeclaredInterface = a
_ = CFunctionReturningAForwardDeclaredInterface()
// CHECK: ForwardDeclaredInterface doing something!
CFunctionTakingAForwardDeclaredInterfaceAsAParameter(a)

// Protocols
let b = bar.methodReturningForwardDeclaredProtocol()!
// CHECK: ForwardDeclaredProtocol doing something else!
bar.methodTakingAForwardDeclaredProtocol(asAParameter: b)
bar.propertyUsingAForwardDeclaredProtocol = b
_ = CFunctionReturningAForwardDeclaredProtocol()
// CHECK: ForwardDeclaredProtocol doing something else!
CFunctionTakingAForwardDeclaredProtocolAsAParameter(b)
