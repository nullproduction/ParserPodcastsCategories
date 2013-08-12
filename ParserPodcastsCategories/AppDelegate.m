//
//  AppDelegate.m
//

#import "AppDelegate.h"
#import "Parser.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    Parser *parser = [[Parser alloc] init];
    [parser start];
    return YES;
}
							
@end
