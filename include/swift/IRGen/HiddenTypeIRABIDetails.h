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
#include "swift/AST/GenericSignature.h"
#include "swift/AST/ReferenceCounting.h"
#include "swift/AST/Types.h"
#include "swift/SIL/SILTypeProperties.h"
#include "llvm/ADT/ArrayRef.h"
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
    NonFixedStruct,
    GenericStruct,
  };

private:
  Kind TheKind;
  std::string MangledTypeName;
  SILTypeProperties TypeProperties;

protected:
  HiddenTypeIRABIInfo(Kind kind) : TheKind(kind) {}

public:
  Kind getKind() const { return TheKind; }

  StringRef getMangledTypeName() const { return MangledTypeName; }
  void setMangledTypeName(StringRef name) { MangledTypeName = name.str(); }

  SILTypeProperties getSILTypeProperties() const { return TypeProperties; }
  void setSILTypeProperties(SILTypeProperties props) { TypeProperties = props; }

  virtual std::optional<ReferenceCounting> getReferenceCountingSystem() const {
    return std::nullopt;
  }

  std::string getMetadataAccessorName() const {
    return MangledTypeName + "Ma";
  }

protected:
  ~HiddenTypeIRABIInfo() {}
};

/// Intermediate base class for concrete (not generic) hidden nominal types.
class HiddenNominalTypeIRABIInfo : public HiddenTypeIRABIInfo {
protected:
  HiddenNominalTypeIRABIInfo(Kind kind) : HiddenTypeIRABIInfo(kind) {}

public:
  static bool classof(const HiddenTypeIRABIInfo *info) {
    switch (info->getKind()) {
    case Kind::LoadableStruct:
    case Kind::AddressOnlyStruct:
    case Kind::ReferenceType:
    case Kind::ResilientStruct:
    case Kind::NonFixedStruct:
      return true;
    case Kind::GenericStruct:
      return false;
    }
  }

protected:
  ~HiddenNominalTypeIRABIInfo() {}
};

/// ABI details for a hidden struct type (loadable, address-only, or non-fixed).
class HiddenStructTypeIRABIInfo : public HiddenNominalTypeIRABIInfo {
  std::vector<Type> FieldTypes;

public:
  const bool Copyable;
  bool IsKnownABIAccessible = false;

  HiddenStructTypeIRABIInfo(Kind kind, llvm::ArrayRef<Type> fieldTypes,
                            bool copyable,
                            bool isKnownABIAccessible = false)
      : HiddenNominalTypeIRABIInfo(kind),
        FieldTypes(fieldTypes.begin(), fieldTypes.end()),
        Copyable(copyable),
        IsKnownABIAccessible(isKnownABIAccessible) {}

  llvm::ArrayRef<Type> getFieldTypes() const { return FieldTypes; }

  static bool classof(const HiddenTypeIRABIInfo *info) {
    return info->getKind() == Kind::LoadableStruct ||
           info->getKind() == Kind::AddressOnlyStruct ||
           info->getKind() == Kind::NonFixedStruct;
  }

protected:
  ~HiddenStructTypeIRABIInfo() {}
};

/// ABI details for a hidden reference type (class).
class HiddenReferenceTypeIRABIInfo : public HiddenNominalTypeIRABIInfo {
public:
  const ReferenceCounting Refcounting;

  HiddenReferenceTypeIRABIInfo(ReferenceCounting refcounting)
      : HiddenNominalTypeIRABIInfo(Kind::ReferenceType),
        Refcounting(refcounting) {}

  std::optional<ReferenceCounting> getReferenceCountingSystem() const override {
    return Refcounting;
  }

  static bool classof(const HiddenTypeIRABIInfo *info) {
    return info->getKind() == Kind::ReferenceType;
  }

protected:
  ~HiddenReferenceTypeIRABIInfo() {}
};

/// ABI details for a hidden resilient struct type.
class HiddenResilientStructTypeIRABIInfo : public HiddenNominalTypeIRABIInfo {
public:
  const bool Copyable;
  bool IsKnownABIAccessible = false;

  HiddenResilientStructTypeIRABIInfo(bool copyable, bool isKnownABIAccessible = false)
      : HiddenNominalTypeIRABIInfo(Kind::ResilientStruct),
        Copyable(copyable),
        IsKnownABIAccessible(isKnownABIAccessible) {}

  static bool classof(const HiddenTypeIRABIInfo *info) {
    return info->getKind() == Kind::ResilientStruct;
  }

protected:
  ~HiddenResilientStructTypeIRABIInfo() {}
};

/// Intermediate base class for hidden generic types whose layout depends on
/// generic substitution.
class HiddenGenericTypeIRABIInfo : public HiddenTypeIRABIInfo {
protected:
  HiddenGenericTypeIRABIInfo(Kind kind) : HiddenTypeIRABIInfo(kind) {}

public:
  static bool classof(const HiddenTypeIRABIInfo *info) {
    switch (info->getKind()) {
    case Kind::GenericStruct:
      return true;
    default:
      return false;
    }
  }
protected:
  ~HiddenGenericTypeIRABIInfo() {}
};

/// ABI details for a hidden generic struct type. Stores field types that may
/// contain GenericTypeParamType references. The actual layout is determined
/// after generic substitution at type conversion time.
class HiddenGenericStructTypeIRABIInfo : public HiddenGenericTypeIRABIInfo {
  CanGenericSignature GenericSig;
  std::vector<Type> FieldTypes;

public:
  HiddenGenericStructTypeIRABIInfo(CanGenericSignature genericSig,
                                   llvm::ArrayRef<Type> fieldTypes)
      : HiddenGenericTypeIRABIInfo(Kind::GenericStruct),
        GenericSig(genericSig),
        FieldTypes(fieldTypes.begin(), fieldTypes.end()) {}

  CanGenericSignature getGenericSignature() const { return GenericSig; }
  llvm::ArrayRef<Type> getFieldTypes() const { return FieldTypes; }

  SmallVector<Type, 4> getSubstitutedFieldTypes(
      const HiddenTypeLayoutInfoType *hiddenType) const {
    SmallVector<ArrayRef<Type>, 4> argsReversed;
    const HiddenTypeLayoutInfoType *cur = hiddenType;
    while (cur) {
      if (auto *bg = dyn_cast<HiddenBoundGenericTypeLayoutInfoType>(cur))
        argsReversed.push_back(bg->getGenericArgs());
      Type parent = cur->getParent();
      cur = parent
                ? dyn_cast<HiddenTypeLayoutInfoType>(parent.getPointer())
                : nullptr;
    }
    SmallVector<ArrayRef<Type>, 4> argsByDepth;
    for (auto it = argsReversed.rbegin(), end = argsReversed.rend();
         it != end; ++it)
      argsByDepth.push_back(*it);

    auto substFn = [&](SubstitutableType *type) -> Type {
      if (auto *gp = dyn_cast<GenericTypeParamType>(type)) {
        unsigned depth = gp->getDepth();
        unsigned index = gp->getIndex();
        if (depth < argsByDepth.size() &&
            index < argsByDepth[depth].size())
          return argsByDepth[depth][index];
      }
      return Type();
    };
    auto conformanceFn = LookUpConformanceInModule();

    SmallVector<Type, 4> result;
    for (auto fieldType : FieldTypes)
      result.push_back(fieldType.subst(substFn, conformanceFn));
    return result;
  }

  static bool classof(const HiddenTypeIRABIInfo *info) {
    return info->getKind() == Kind::GenericStruct;
  }

protected:
  ~HiddenGenericStructTypeIRABIInfo() {}
};

} // end namespace irgen
} // end namespace swift

#endif // SWIFT_IRGEN_HIDDENTYPEIRAABIDETAILS_H
