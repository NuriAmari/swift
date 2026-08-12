// RUN: %target-swift-frontend %s -O -emit-ir -module-name test | %FileCheck %s

public final class Reference {}

public struct POD {
  public var a: Int
  public var b: Int
  public var c: Int
  public var d: Int
  public var e: Int
  public var f: Int
}

public struct Mixed {
  public var pod: POD
  public var reference: Reference
}

public func assignWithCopy(_ destination: inout Mixed, _ source: Mixed) {
  destination = source
}

public func assignWithTake(_ destination: inout Mixed,
                           _ source: consuming Mixed) {
  destination = source
}

// The assignWithCopy witness should memcpy the 48 byte POD field instead of assigning
// each of its fields, retain the source reference, and release the reference
// previously held by the destination.

// CHECK-LABEL: define internal {{.*}}ptr @"$s4test5MixedVwca"
// CHECK: call void @llvm.memcpy.p0.p0.i64({{.*}}i64 48, i1 false)
// CHECK: call ptr @swift_retain
// CHECK: call void @swift_release
// CHECK: ret ptr

// The assignWithTake should also memcopy,  but the witness transfers
//the source reference rather than retaining it, and only releases the reference displaced at the destination.

// CHECK-LABEL: define internal {{.*}}ptr @"$s4test5MixedVwta"
// CHECK: call void @llvm.memcpy.p0.p0.i64({{.*}}i64 48, i1 false)
// CHECK: call void @swift_release
// CHECK: ret ptr
