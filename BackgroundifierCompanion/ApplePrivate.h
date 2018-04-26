//
//  ApplePrivate.h
//  BackgroundifierCompanion
//
//  Created by Alexei Baboulevitch on 2018-4-22.
//  Copyright © 2018 Alexei Baboulevitch. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSStatusBarWindow
@end

int _CGSDefaultConnection(void);
id CGSCopyManagedDisplaySpaces(int conn);

CGDirectDisplayID CGSGetDisplayForUUID(CFStringRef displayUUID);
CFDictionaryRef DesktopPictureCopyDisplayForSpace(CGDirectDisplayID display, int unused, CFStringRef spaceUUID);
void DesktopPictureSetDisplayForSpace(CGDirectDisplayID display, CFDictionaryRef settings, int unused1, int unused2, CFStringRef spaceUUID);
