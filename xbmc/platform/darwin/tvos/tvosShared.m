/*
 *  Copyright (C) 2010-2018 Team Kodi
 *  This file is part of Kodi - https://kodi.tv
 *
 *  SPDX-License-Identifier: GPL-2.0-or-later
 *  See LICENSES/README.md for more information.
 */

#import <Foundation/Foundation.h>

@interface tvosShared : NSObject
+ (NSString *)getSharedID;
+ (NSURL *)getSharedURL;
+ (BOOL) IsTVOSSandboxed;
+ (BOOL)isJailbroken;
@end

@implementation tvosShared : NSObject
+ (NSString *)getSharedID {
  NSString *bundleID;
  NSBundle *bundle = [NSBundle mainBundle];
  if ([[bundle.bundleURL pathExtension] isEqualToString:@"appex"]) { // We're in a extension
    // Peel off two directory levels - Kodi.app/PlugIns/MY_APP_EXTENSION.appex
    bundle = [NSBundle bundleWithURL:[[bundle.bundleURL URLByDeletingLastPathComponent] URLByDeletingLastPathComponent]];
    bundleID = bundle.bundleIdentifier;
  } else {
    bundleID = [NSBundle mainBundle].bundleIdentifier;
  }
  return [@"group." stringByAppendingString:bundleID];
}

+ (NSURL *)getSharedURL {
  #define JAILBROKEN_SHARED_FOLDER @"/var/mobile/Library/Caches"
  if ([self isJailbroken])
  {
    return [[NSURL fileURLWithPath:JAILBROKEN_SHARED_FOLDER] URLByAppendingPathComponent:[self getSharedID]];
  }
  else
  {
        NSFileManager* fileManager = [NSFileManager defaultManager];
        NSURL *sharedUrl = [fileManager containerURLForSecurityApplicationGroupIdentifier:[self getSharedID]];
        sharedUrl = [sharedUrl URLByAppendingPathComponent:@"Library" isDirectory:TRUE];
        sharedUrl = [sharedUrl URLByAppendingPathComponent:@"Caches" isDirectory:TRUE];
        return sharedUrl;
  }
}

+ (BOOL) IsTVOSSandboxed
{
  static int ret = -1;
  if (ret == -1)
  {
    NSBundle *bundle = [NSBundle mainBundle];
    if ([[bundle.bundleURL pathExtension] isEqualToString:@"appex"]) { // We're in a extension
      // Peel off two directory levels - Kodi.app/PlugIns/MY_APP_EXTENSION.appex
      bundle = [NSBundle bundleWithURL:[[bundle.bundleURL URLByDeletingLastPathComponent] URLByDeletingLastPathComponent]];
    }

    ret = 1;// default to "sandboxed"

    // we re NOT sandboxed if we are installed in /var/mobile/Applications with greeng0blin jailbreak
    if ([[bundle executablePath] containsString:@"/var/mobile/Applications/"])
    {
      ret = 0;
    }
  }
  return ret == 1;
}

+ (BOOL)isJailbroken {
  return ![self IsTVOSSandboxed];
}

@end