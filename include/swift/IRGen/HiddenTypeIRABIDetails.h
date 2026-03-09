//===--- HiddenTypeIRABIDetails.h - ABI details for hidden types -*- C++ -*-===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//
//
/// \file
/// Defines data classes that describe the ABI layout of types whose
/// definitions are hidden (e.g., from @_implementationOnly imports).
/// These are serialized into swiftmodules in place of the AST
/// representation of a type when ABI details about a hidden type
/// need exporting.
//
//===----------------------------------------------------------------------===//

#ifndef SWIFT_IRGEN_HIDDENTYPEIRAABIDETAILS_H
#define SWIFT_IRGEN_HIDDENTYPEIRAABIDETAILS_H

#include "swift/AST/ASTAllocated.h"
#include "swift/AST/ReferenceCounting.h"
#include "swift/AST/Types.h"
#include "swift/SIL/SILTypeProperties.h"
#include "llvm/ADT/ArrayRef.h"
#include "llvm/Support/Casting.h"
#include <optional>
#include <vector>

namespace swift {
namespace irgen {

class HiddenTypeIRABIInfo : public ASTAllocated<HiddenTypeIRABIInfo> {
public:
  enum class Kind {
    LoadableStruct,
    AddressOnlyStruct,
    ReferenceType,
    ResilientStruct,
  };

private:
  Kind TheKind;

protected:
  HiddenTypeIRABIInfo(Kind kind) : TheKind(kind) {}

public:
  Kind getKind() const { return TheKind; }

  /// Whether this hidden type is trivially destroyable (no cleanup needed).
  /// Used by SIL type lowering to determine if the type can be treated
  /// as trivial rather than address-only.
  virtual bool isTriviallyDestroyable() const = 0;

  /// Returns the reference counting system used by this hidden type,
  /// or std::nullopt if the type does not have reference semantics.
  virtual std::optional<ReferenceCounting> getReferenceCountingSystem() const = 0;
};

/// ABI details for a loadable hidden struct type.
///
/// Stores everything needed to reconstruct a HiddenLoadableStructTypeInfo
/// without exposing TypeInfo internals. LLVM-specific values (storageType,
/// spareBits) are derived during TypeInfo construction and are not stored here.
class LoadableHiddenStructTypeIRABIInfo : public HiddenTypeIRABIInfo {
  std::vector<Type> FieldTypes;
  unsigned ExplosionSize;
  unsigned Size;
  unsigned Alignment;
  bool TriviallyDestroyable;
  bool BitwiseTakable;
  bool Copyable;
  bool FixedSize;
  bool ABIAccessible;
  SILTypeProperties TypeProperties;

public:
  LoadableHiddenStructTypeIRABIInfo(llvm::ArrayRef<Type> fieldTypes,
                                    unsigned explosionSize, unsigned size,
                                    unsigned alignment,
                                    bool triviallyDestroyable,
                                    bool bitwiseTakable, bool copyable,
                                    bool fixedSize, bool abiAccessible)
      : HiddenTypeIRABIInfo(Kind::LoadableStruct),
        FieldTypes(fieldTypes.begin(), fieldTypes.end()),
        ExplosionSize(explosionSize), Size(size), Alignment(alignment),
        TriviallyDestroyable(triviallyDestroyable),
        BitwiseTakable(bitwiseTakable), Copyable(copyable),
        FixedSize(fixedSize), ABIAccessible(abiAccessible) {}

  llvm::ArrayRef<Type> getFieldTypes() const { return FieldTypes; }
  unsigned getExplosionSize() const { return ExplosionSize; }
  unsigned getSize() const { return Size; }
  unsigned getAlignment() const { return Alignment; }
  bool isTriviallyDestroyable() const override { return TriviallyDestroyable; }
  std::optional<ReferenceCounting> getReferenceCountingSystem() const override {
    return std::nullopt;
  }
  bool isBitwiseTakable() const { return BitwiseTakable; }
  bool isCopyable() const { return Copyable; }
  bool isFixedSize() const { return FixedSize; }
  bool isABIAccessible() const { return ABIAccessible; }

  SILTypeProperties getSILTypeProperties() const { return TypeProperties; }
  void setSILTypeProperties(SILTypeProperties props) { TypeProperties = props; }

  static bool classof(const HiddenTypeIRABIInfo *info) {
    return info->getKind() == Kind::LoadableStruct;
  }
};

/// ABI details for a fixed-size, address-only hidden struct type.
class AddressOnlyHiddenStructTypeIRABIInfo : public HiddenTypeIRABIInfo {
  std::vector<Type> FieldTypes;
  unsigned Size;
  unsigned Alignment;
  bool TriviallyDestroyable;
  bool BitwiseTakable;
  bool Copyable;
  bool FixedSize;
  bool ABIAccessible;
  SILTypeProperties TypeProperties;

public:
  AddressOnlyHiddenStructTypeIRABIInfo(llvm::ArrayRef<Type> fieldTypes,
                                       unsigned size, unsigned alignment,
                                       bool triviallyDestroyable,
                                       bool bitwiseTakable, bool copyable,
                                       bool fixedSize, bool abiAccessible)
      : HiddenTypeIRABIInfo(Kind::AddressOnlyStruct),
        FieldTypes(fieldTypes.begin(), fieldTypes.end()),
        Size(size), Alignment(alignment),
        TriviallyDestroyable(triviallyDestroyable),
        BitwiseTakable(bitwiseTakable), Copyable(copyable),
        FixedSize(fixedSize), ABIAccessible(abiAccessible) {}

  llvm::ArrayRef<Type> getFieldTypes() const { return FieldTypes; }
  unsigned getSize() const { return Size; }
  unsigned getAlignment() const { return Alignment; }
  bool isTriviallyDestroyable() const override { return TriviallyDestroyable; }
  std::optional<ReferenceCounting> getReferenceCountingSystem() const override {
    return std::nullopt;
  }
  bool isBitwiseTakable() const { return BitwiseTakable; }
  bool isCopyable() const { return Copyable; }
  bool isFixedSize() const { return FixedSize; }
  bool isABIAccessible() const { return ABIAccessible; }

  SILTypeProperties getSILTypeProperties() const { return TypeProperties; }
  void setSILTypeProperties(SILTypeProperties props) { TypeProperties = props; }

  static bool classof(const HiddenTypeIRABIInfo *info) {
    return info->getKind() == Kind::AddressOnlyStruct;
  }
};

/// ABI details for a hidden reference type (class).
class HiddenReferenceTypeIRABIInfo : public HiddenTypeIRABIInfo {
  ReferenceCounting Refcounting;

public:
  HiddenReferenceTypeIRABIInfo(ReferenceCounting refcounting)
      : HiddenTypeIRABIInfo(Kind::ReferenceType),
        Refcounting(refcounting) {}

  ReferenceCounting getReferenceCounting() const { return Refcounting; }
  bool isTriviallyDestroyable() const override { return false; }
  std::optional<ReferenceCounting> getReferenceCountingSystem() const override {
    return Refcounting;
  }

  static bool classof(const HiddenTypeIRABIInfo *info) {
    return info->getKind() == Kind::ReferenceType;
  }
};

/// ABI details for a hidden resilient struct type.
class HiddenResilientStructTypeIRABIInfo : public HiddenTypeIRABIInfo {
  std::string MetadataAccessorName;
  bool Copyable;
  bool ABIAccessible;
  SILTypeProperties TypeProperties;

public:
  HiddenResilientStructTypeIRABIInfo(StringRef metadataAccessorName,
                                      bool copyable, bool abiAccessible)
      : HiddenTypeIRABIInfo(Kind::ResilientStruct),
        MetadataAccessorName(metadataAccessorName.str()),
        Copyable(copyable), ABIAccessible(abiAccessible) {}

  StringRef getMetadataAccessorName() const { return MetadataAccessorName; }
  void setMetadataAccessorName(StringRef name) {
    MetadataAccessorName = name.str();
  }
  bool isCopyable() const { return Copyable; }
  bool isABIAccessible() const { return ABIAccessible; }
  bool isTriviallyDestroyable() const override { return false; }
  std::optional<ReferenceCounting> getReferenceCountingSystem() const override {
    return std::nullopt;
  }

  SILTypeProperties getSILTypeProperties() const { return TypeProperties; }
  void setSILTypeProperties(SILTypeProperties props) { TypeProperties = props; }

  static bool classof(const HiddenTypeIRABIInfo *info) {
    return info->getKind() == Kind::ResilientStruct;
  }
};

} // end namespace irgen
} // end namespace swift

#endif // SWIFT_IRGEN_HIDDENTYPEIRAABIDETAILS_H
