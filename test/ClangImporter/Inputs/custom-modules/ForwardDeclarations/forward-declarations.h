#import <Foundation/Foundation.h>

@class ForwardDeclaredInterface;
@protocol ForwardDeclaredProtocol;

@interface Bar : NSObject
@property id<ForwardDeclaredProtocol> propertyUsingAForwardDeclaredProtocol;
@property ForwardDeclaredInterface *propertyUsingAForwardDeclaredInterface;
- (id)init;
- (NSObject<ForwardDeclaredProtocol> *)methodReturningForwardDeclaredProtocol;
- (ForwardDeclaredInterface *)methodReturningForwardDeclaredInterface;
- (void)methodTakingAForwardDeclaredProtocolAsAParameter:
    (id<ForwardDeclaredProtocol>)param1;
- (void)methodTakingAForwardDeclaredInterfaceAsAParameter:
            (ForwardDeclaredInterface *)param1
                                               andAnother:
                                                   (ForwardDeclaredInterface *)
                                                       param2;
@end

ForwardDeclaredInterface *CFunctionReturningAForwardDeclaredInterface();
void CFunctionTakingAForwardDeclaredInterfaceAsAParameter(
    ForwardDeclaredInterface *param1);

NSObject<ForwardDeclaredProtocol> *CFunctionReturningAForwardDeclaredProtocol();
void CFunctionTakingAForwardDeclaredProtocolAsAParameter(
    id<ForwardDeclaredProtocol> param1);

@interface CompleteInterface : NSObject
- (id)init;
- (void)doSomethingOnlyCompleteInterfaceChildrenCan;
@end
@protocol CompleteProtocol
- (void)doSomethingOnlyCompleteProtocolConformersCan;
@end

@interface Foo : NSObject
@property id<CompleteProtocol> propertyUsingACompleteProtocol;
@property CompleteInterface *propertyUsingACompleteInterface;
- (NSObject<CompleteProtocol> *)methodReturningCompleteProtocol;
- (CompleteInterface *)methodReturningCompleteInterface;
- (void)methodTakingACompleteProtocolAsAParameter:(id<CompleteProtocol>)param1;
- (void)methodTakingACompleteInterfaceAsAParameter:(CompleteInterface *)param1
                                        andAnother:(CompleteInterface *)param2;
@end

CompleteInterface *CFunctionReturningACompleteInterface();
void CFunctionTakingACompleteInterfaceAsAParameter(CompleteInterface *param1);

NSObject<CompleteProtocol> *CFunctionReturningACompleteProtocol();
void CFunctionTakingACompleteProtocolAsAParameter(id<CompleteProtocol> param1);
