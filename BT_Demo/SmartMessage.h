/*-----------------------------------------------------------------------------*/
/*    SmartMessage.h                                                           */
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

#ifndef _SmartMessage_h
#define _SmartMessage_h

@interface SmartMessage : NSObject

-(id)initWithVexCDCMessageHeader:(char)msgID;
-(id)initWithVexCDCStartProgram:(NSUInteger)slot;
-(id)initWithVexCDCStopProgram;
-(id)initWithVexCDCGetPortInfo:(NSUInteger)port;

-(id)initWithRobotCMessageHeader;
-(id)initWithRobotCCommand:(NSData *)cmd;
-(id)initWithRobotCAlive;
-(id)initWithRobotCUserMessage:(NSData *)msg;
-(id)initWithRobotCUserMessageReq;

-(bool)sendMessageOnLink:(SmartLink *)link;
-(bool)sendMessageOnLink:(SmartLink *)link  withTxCallback:(TxDataCallback)callback;

@property (nonatomic)  UInt16  expectedReplyLength;

@end


#endif
