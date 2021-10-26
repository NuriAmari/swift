#include <Foundation.h>

@class Foo;
@class Baz;

@interface Bar : NSObject
- (Baz *)baz;
- (int)doSomethingWithFoo:(Foo *)foo andBaz:(Baz *)baz;
@end
