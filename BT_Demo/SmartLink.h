/*-----------------------------------------------------------------------------*/
/*    SmartLink.h                                                              */
/*                                                                             */
/*    Created by James Pearman on 9/4/15.                                      */
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
#ifndef _SmartLink_h
#define _SmartLink_h

#import "SmartRadio.h"

typedef void (^TxDataCallback)(bool status, NSData *data);

@protocol SmartLinkDelegate

@optional

-(void)transmitTimeout;
-(void)receiveTimeout;
-(void)joystickStatus:(BOOL)status;
-(void)dataStatus:(BOOL)status;

@end

@interface SmartLink : SmartRadio <SmartRadioDelegate>

- (id)   Start:(UInt32)ssn updateRate:(UInt32)rate withJoystick:(BOOL)enableJoystick withData:(BOOL)enableData withDelagate:(id<SmartLinkDelegate>)delagate;
- (void) Stop;

- (void) sendMessage:(NSData *)message waitForReply:(bool)wait forMs:(int)ms withReplyLength:(int)replyLength withTxCallback:(TxDataCallback)callback;

- (void) decodeReceiveCDCPortData:(NSData *)data forPort:(NSUInteger)port;

@property (strong, nonatomic)   NSMutableArray         *portinfo;

@end

#endif
