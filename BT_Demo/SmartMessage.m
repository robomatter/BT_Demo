/*-----------------------------------------------------------------------------*/
/*    SmartMessage.m                                                           */
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

#import <Foundation/Foundation.h>
#import "SmartLink.h"
#import "SmartMessage.h"
#import "VexCDCMessage.h"
#import "RobotCOpcodes.h"

@interface SmartMessage()

@property (strong, nonatomic)  NSMutableData *message;

@end

@implementation SmartMessage

/*-----------------------------------------------------------------------------*/
/** @brief Initialize message with Vex CDC header                              */
/*-----------------------------------------------------------------------------*/
-(id)initWithVexCDCMessageHeader:(char)msgID
{
    char   VexCDCHeader[] = CDC_HEADER;

    // Set the CDC message ID
    VexCDCHeader[4] = msgID;

    // create new private object
    self.message = [NSMutableData dataWithBytes:VexCDCHeader length:sizeof(VexCDCHeader) ];
    
    return self;
}

/*-----------------------------------------------------------------------------*/
/** @brief Initialize message with VEX "start program" command                 */
/*-----------------------------------------------------------------------------*/
-(id)initWithVexCDCStartProgram:(NSUInteger)slot
{
    char cmd[] = { 0x01, slot };
    
    self = [self initWithVexCDCMessageHeader:CDC_PLAY_PROGRAM];
    [self.message appendBytes:cmd length:sizeof(cmd)];
    self.expectedReplyLength = CDC_GEN_ACK_CMDLEN;
    
    return self;
}

/*-----------------------------------------------------------------------------*/
/** @brief Initialize message with VEX "stop program" command                  */
/*-----------------------------------------------------------------------------*/
-(id)initWithVexCDCStopProgram
{
    self = [self initWithVexCDCMessageHeader:CDC_STOP_PROGRAM];
    self.expectedReplyLength = CDC_GEN_ACK_CMDLEN;
    
    return self;
}

/*-----------------------------------------------------------------------------*/
/** @brief Initialize message with VEX "get port info" command                 */
/*-----------------------------------------------------------------------------*/
-(id)initWithVexCDCGetPortInfo:(NSUInteger)port
{
    char cmd[] = { 0x01, port };
    
    self = [self initWithVexCDCMessageHeader:CMD_GET_COMPONENTS];
    [self.message appendBytes:cmd length:sizeof(cmd)];
    self.expectedReplyLength = 7;
    
    return self;
}

/*-----------------------------------------------------------------------------*/
/** @brief Initialize message with ROBOTC header                               */
/*-----------------------------------------------------------------------------*/
-(id)initWithRobotCMessageHeader
{
    char  RobotCHeader[] = ROBOTC_HEADER;
    
    // Create the VEX header
    self = [self initWithVexCDCMessageHeader:CDC_WRITE_FIFO_BUFR ];
    
    // Append the RC header leaving the length at 0
    [self.message appendBytes:RobotCHeader length:sizeof(RobotCHeader)];
    
    return self;
}

/*-----------------------------------------------------------------------------*/
/** @brief Initialize message with ROBOTC command                              */
/*-----------------------------------------------------------------------------*/
-(id)initWithRobotCCommand:(NSData *)cmd
{
    // Create the ROBOTC header
    self = [self initWithRobotCMessageHeader];

    // max command length of 255 bytes
    if( cmd.length > 255 )
        return nil;

    // Get pointer to our raw data
    char *p = (char *)self.message.mutableBytes;

    // update the robotc packet length
    p[5] = cmd.length + 5;
    
    // Add the data length
    p[9] = cmd.length + 1;

    // Add the message data
    [self.message appendData:cmd ];

    // calculate checksum
    UInt8 databytes[cmd.length];
    [cmd getBytes:databytes length:sizeof(databytes)];
    
    uint checksum = 0;
    for (int i=0; i<cmd.length; i++) {
        checksum += databytes[i];
    }
    UInt8 checksumByte[] = {(UInt8)(0xFF & checksum)};

    // Append checksum to message
    [self.message appendBytes:checksumByte length:sizeof(checksumByte)];
    
    // success
    return self;
}

/*-----------------------------------------------------------------------------*/
/** @brief Initialize message with ROBOTC "alive" command                      */
/*-----------------------------------------------------------------------------*/
-(id)initWithRobotCAlive
{
    char b[] = { opcdAlive };
    
    NSData *cmd = [NSData dataWithBytes:b length:sizeof(b) ];

    self = [self initWithRobotCCommand:cmd];
    self.expectedReplyLength = 2;
    
    return self;
}

/*-----------------------------------------------------------------------------*/
/** @brief Initialize message with ROBOTC "user message" command               */
/*-----------------------------------------------------------------------------*/
-(id) initWithRobotCUserMessage:(NSData *)msg
{
    char b[] = { opcdUsrMsgFunctions, usgMsgFcn_RecieveUserMsg };
    
    NSMutableData *cmd = [NSMutableData dataWithBytes:b length:sizeof(b) ];
    [cmd appendData:msg];
    
    self = [self initWithRobotCCommand:cmd];
    self.expectedReplyLength = 2;
    
    return self;
}

/*-----------------------------------------------------------------------------*/
/** @brief Initialize message with ROBOTC "user message request" command       */
/*-----------------------------------------------------------------------------*/
-(id)initWithRobotCUserMessageReq
{
    char b[] = { opcdUsrMsgFunctions, usgMsgFcn_RequestUsrMsg };
    
    NSData *cmd = [NSData dataWithBytes:b length:sizeof(b) ];
    
    self = [self initWithRobotCCommand:cmd];
    self.expectedReplyLength = 44;
    
    return self;
}

/*-----------------------------------------------------------------------------*/
/** @brief send message on the given SmartLink                                 */
/*-----------------------------------------------------------------------------*/
-(bool)sendMessageOnLink:(SmartLink *)link;
{
    if( self.message == nil )
        return false;

    [link sendMessage:self.message waitForReply:false forMs:0 withReplyLength:0 withTxCallback:nil];
    
    return true;
}

/*-----------------------------------------------------------------------------*/
/** @brief send message on the given SmartLink with a callback for tx complete */
/*-----------------------------------------------------------------------------*/
-(bool)sendMessageOnLink:(SmartLink *)link  withTxCallback:(TxDataCallback)callback;
{
    if( self.message == nil )
        return false;
    
    [link sendMessage:self.message waitForReply:true forMs:5000 withReplyLength:self.expectedReplyLength  withTxCallback:callback];
    
    return true;
}


@end
