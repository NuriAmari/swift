#import "forward-declarations.h"

@interface ForwardDeclaredInterface : NSObject
- (id)init;
- (void)doSomething;
@end

@implementation ForwardDeclaredInterface
- (id)init {
  return [super init];
}
- (void)doSomething {
  NSLog(@"ForwardDeclaredInterface doing something!");
}
@end

@protocol ForwardDeclaredProtocol
- (void)doSomethingElse;
@end

@interface TypeConformingToForwardDeclaredProtocol
    : NSObject <ForwardDeclaredProtocol>
- (id)init;
- (void)doSomethingElse;
@end

@implementation TypeConformingToForwardDeclaredProtocol
- (id)init {
  return [super init];
}
- (void)doSomethingElse {
  NSLog(@"ForwardDeclaredProtocol doing something else!");
}
@end

@implementation Bar
- (id)init {
  return [super init];
}
- (NSObject<ForwardDeclaredProtocol> *)methodReturningForwardDeclaredProtocol {
  return [[TypeConformingToForwardDeclaredProtocol alloc] init];
}
- (ForwardDeclaredInterface *)methodReturningForwardDeclaredInterface {
  return [[ForwardDeclaredInterface alloc] init];
}
- (void)methodTakingAForwardDeclaredProtocolAsAParameter:
    (id<ForwardDeclaredProtocol>)param1 {
  [param1 doSomethingElse];
}
- (void)methodTakingAForwardDeclaredInterfaceAsAParameter:
            (ForwardDeclaredInterface *)param1
                                               andAnother:
                                                   (ForwardDeclaredInterface *)
                                                       param2 {
  [param1 doSomething];
  [param2 doSomething];
}
@end

// TODO: Remove all Complete stuff that isn't strictly required, mostly we are
// writting tests against the header

@interface TypeConformingToCompleteProtocol : NSObject <CompleteProtocol>
- (id)init;
- (void)doSomethingOnlyCompleteProtocolConformersCan;
@end

@implementation TypeConformingToCompleteProtocol
- (id)init {
  return [super init];
}
- (void)doSomethingOnlyCompleteProtocolConformersCan {
  NSLog(@"Doing something only complete protocol conformers can!");
}
@end

@implementation CompleteInterface
- (id)init {
  return [super init];
}
- (void)doSomethingOnlyCompleteInterfaceChildrenCan {
  NSLog(@"Doing something only complete interface children can!");
}
@end

@implementation Foo
- (NSObject<CompleteProtocol> *)methodReturningCompleteProtocol {
  return [[TypeConformingToCompleteProtocol alloc] init];
}
- (CompleteInterface *)methodReturningCompleteInterface {
  return [[CompleteInterface alloc] init];
}
- (void)methodTakingACompleteProtocolAsAParameter:(id<CompleteProtocol>)param1 {
  [param1 doSomethingOnlyCompleteProtocolConformersCan];
}
- (void)methodTakingACompleteInterfaceAsAParameter:(CompleteInterface *)param1
                                        andAnother:(CompleteInterface *)param2 {
  [param1 doSomethingOnlyCompleteInterfaceChildrenCan];
  [param2 doSomethingOnlyCompleteInterfaceChildrenCan];
}
@end

ForwardDeclaredInterface *CFunctionReturningAForwardDeclaredInterface() {
  return [[ForwardDeclaredInterface alloc] init];
}

void CFunctionTakingAForwardDeclaredInterfaceAsAParameter(
    ForwardDeclaredInterface *param1) {
  [param1 doSomething];
}

NSObject<ForwardDeclaredProtocol> *
CFunctionReturningAForwardDeclaredProtocol() {
  return [[TypeConformingToForwardDeclaredProtocol alloc] init];
}

void CFunctionTakingAForwardDeclaredProtocolAsAParameter(
    id<ForwardDeclaredProtocol> param1) {
  [param1 doSomethingElse];
}

CompleteInterface *CFunctionReturningACompleteInterface() {
  return [[CompleteInterface alloc] init];
}

void CFunctionTakingACompleteInterfaceAsAParameter(CompleteInterface *param1) {
  [param1 doSomethingOnlyCompleteInterfaceChildrenCan];
}

NSObject<CompleteProtocol> *CFunctionReturningACompleteProtocol() {
  return [[TypeConformingToCompleteProtocol alloc] init];
}

void CFunctionTakingACompleteProtocolAsAParameter(id<CompleteProtocol> param1) {
  [param1 doSomethingOnlyCompleteProtocolConformersCan];
}
