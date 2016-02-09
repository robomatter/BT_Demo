/*-----------------------------------------------------------------------------*/
/*    SmartController.h                                                        */
/*                                                                             */
/*    Created by James Pearman on 9/5/15.                                      */
/*    Copyright (c) 2015 robomatter. All rights reserved.                      */
/*-----------------------------------------------------------------------------*/
/*    This file is part of the robomatter BT_Demo code for the VexIQ           */
/*                                                                             */
/*    BT_Demo is free software: you can redistribute it and/or modify          */
/*    it under the terms of the GNU General Public License as published by     */
/*    the Free Software Foundation, either version 3 of the License, or        */
/*    (at your option) any later version.                                      */
/*                                                                             */
/*    BT_Demo is distributed in the hope that it will be useful,               */
/*    but WITHOUT ANY WARRANTY; without even the implied warranty of           */
/*    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the            */
/*    GNU General Public License for more details.                             */
/*                                                                             */
/*    You should have received a copy of the GNU General Public License        */
/*    along with this program.  If not, see <http://www.gnu.org/licenses/>.    */
/*-----------------------------------------------------------------------------*/

#ifndef _SmartController_h
#define _SmartController_h

#import "SmartLink.h"
#import "SmartMessage.h"

@protocol SmartControllerDelegate

@optional

- (void) joystickStatus:(BOOL)status;
- (void) dataStatus:(BOOL)status;
- (void) userMessage:(NSData *)msg;

@end

@interface SmartController : NSObject <SmartLinkDelegate>

- (id)   init:(UInt32)ssn  withDelagate:(id<SmartControllerDelegate>)delagate;
- (void) Stop;

- (void) robotcUserMessageSend:(NSData *)msg withReply:(bool)reply;
- (void) robotcUserMessageRequest;

- (void) vexSendStartUserProgram:(int)slot;
- (void) vexSendStopUserProgram;

@end

#endif
