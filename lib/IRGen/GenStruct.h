//===--- GenStruct.h - Swift IR generation for structs ----------*- C++ -*-===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2017 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//
//
//  This file provides the private interface to the struct-emission code.
//
//===----------------------------------------------------------------------===//

#ifndef SWIFT_IRGEN_GENSTRUCT_H
#define SWIFT_IRGEN_GENSTRUCT_H

#include "swift/AST/Types.h"
#include "swift/IRGen/HiddenTypeIRABIDetails.h"
#include <optional>

namespace llvm {
  class Constant;
}

namespace swift {
  class CanType;
  class SILType;
  class VarDecl;

namespace irgen {
  class Address;
  class Explosion;
  class IRGenFunction;
  class IRGenModule;
  class MemberAccessStrategy;
  class TypeInfo;

  Address projectPhysicalStructMemberAddress(IRGenFunction &IGF,
                                             Address base,
                                             SILType baseType,
                                             VarDecl *field);
  void projectPhysicalStructMemberFromExplosion(IRGenFunction &IGF,
                                                SILType baseType,
                                                Explosion &base,
                                                VarDecl *field,
                                                Explosion &out);

  /// Return the constant offset of the given stored property in a struct,
  /// or return None if the field does not have fixed layout.
  llvm::Constant *emitPhysicalStructMemberFixedOffset(IRGenModule &IGM,
                                                      SILType baseType,
                                                      VarDecl *field);

  /// Return a strategy for accessing the given stored struct property.
  ///
  /// This API is used by RemoteAST.
  MemberAccessStrategy
  getPhysicalStructMemberAccessStrategy(IRGenModule &IGM,
                                        SILType baseType, VarDecl *field);

  const TypeInfo *getPhysicalStructFieldTypeInfo(IRGenModule &IGM,
                                                 SILType baseType,
                                                 VarDecl *field);

  /// Returns the index of the element in the llvm struct type which represents
  /// \p field in \p baseType.
  ///
  /// Returns None if \p field has an empty type and therefore has no
  /// corresponding element in the llvm type.
  std::optional<unsigned> getPhysicalStructFieldIndex(IRGenModule &IGM,
                                                      SILType baseType,
                                                      VarDecl *field);

  /// Create TypeInfo for a hidden value type from serialized ABI info.
  /// Lowers field types, runs StructLayout, and directly constructs
  /// a HiddenLoadableStructTypeInfo.
  const TypeInfo *createTypeInfoFromABIInfo(IRGenModule &IGM,
                                            CanHiddenTypeLayoutInfoType type,
                                            const LoadableHiddenStructTypeIRABIInfo &abiInfo);

  /// Create TypeInfo for a hidden resilient struct type from serialized
  /// ABI info. Constructs a HiddenResilientStructTypeInfo that stores the
  /// metadata accessor name for value witness calls.
  const TypeInfo *createResilientTypeInfoFromABIInfo(
      IRGenModule &IGM,
      const HiddenResilientStructTypeIRABIInfo &abiInfo);

  /// Create TypeInfo for a hidden fixed-size, address-only struct type
  /// from serialized ABI info. Lowers field types, runs StructLayout, and
  /// constructs a HiddenFixedStructTypeInfo.
  const TypeInfo *createAddressOnlyTypeInfoFromABIInfo(
      IRGenModule &IGM,
      CanHiddenTypeLayoutInfoType type,
      const AddressOnlyHiddenStructTypeIRABIInfo &abiInfo);
} // end namespace irgen
} // end namespace swift

#endif
