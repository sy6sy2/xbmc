/*
 *  Copyright (C) 2019- Team Kodi
 *  This file is part of Kodi - https://kodi.tv
 *
 *  SPDX-License-Identifier: GPL-2.0-or-later
 *  See LICENSES/README.md for more information.
 */

#import <Foundation/Foundation.h>

@interface TVOSLibInputSettings : NSObject

@property(nonatomic) bool siriRemoteIdleTimer;
@property(nonatomic) int siriRemoteIdleTime;
@property(nonatomic) int siriRemoteHorizontalSensitivity;
@property(nonatomic) int siriRemoteVerticalSensitivity;
@property(nonatomic) int siriRemoteHorizontalSwipeMinVelocity;
@property(nonatomic) int siriRemoteVerticalSwipeMinVelocity;

@end
