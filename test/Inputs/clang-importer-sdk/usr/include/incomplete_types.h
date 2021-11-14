#include <Foundation.h>

@class ForwardDeclaredInterface;
@protocol ForwardDeclaredProtocol;

@interface Bar : NSObject
@property id<ForwardDeclaredProtocol> propertyUsingAForwardDeclaredProtocol;
@property ForwardDeclaredInterface* propertyUsingAForwardDeclaredInterface;
- (NSObject<ForwardDeclaredProtocol> *) methodReturningForwardDeclaredProtocol;
- (ForwardDeclaredInterface *) methodReturningForwardDeclaredInterface;
- (int)methodTakingAForwardDeclaredProtocolAsAParameter:(id<ForwardDeclaredProtocol>)param1;
- (int)methodTakingAForwardDeclaredInterfaceAsAParameter:(ForwardDeclaredInterface *)param1 andAnother:(ForwardDeclaredInterface *)param2;
@end

ForwardDeclaredInterface* CFunctionReturningAForwardDeclaredInterface();
void CFunctionTakingAForwardDeclaredInterfaceAsAParameter(ForwardDeclaredInterface* param1);

NSObject<ForwardDeclaredProtocol> *CFunctionReturningAForwardDeclaredProtocol();
void CFunctionTakingAForwardDeclaredProtocolAsAParameter(id<ForwardDeclaredProtocol> param1);
