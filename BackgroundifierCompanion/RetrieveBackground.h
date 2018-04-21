//
//  RetrieveBackground.h
//  BackgroundifierCompanion
//
//  Created by Alexei Baboulevitch on 2018-4-21.
//  Copyright © 2018 Alexei Baboulevitch. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RetrieveBackground : NSObject
+(NSString*) backgroundForDesktop:(NSUInteger)desktop screen:(NSUInteger)screen;
@end
