/*-----------------------------------------------------------------------------*/
/*    SmartController.m                                                        */
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

#import <Foundation/Foundation.h>

#import "SmartController.h"
#import "RobotCOpcodes.h"

@interface SmartController()

@property (strong, nonatomic) SmartLink     *MyLink;
@property (nonatomic)         NSUInteger     state;
@property (nonatomic, assign) id             delagate;

@end


@implementation SmartController

/*-----------------------------------------------------------------------------*/
/** @brief Initialize controller and connect to given ssn                      */
/*-----------------------------------------------------------------------------*/
- (id)init:(UInt32)ssn withDelagate:(id<SmartControllerDelegate>)delagate;
{
    self.delagate  = delagate;
    self.MyLink = [[SmartLink alloc] Start:ssn updateRate:100 withJoystick:false withData:true withDelagate:self];
    
    return self;
}

/*-----------------------------------------------------------------------------*/
/** @brief Stop controller                                                     */
/*-----------------------------------------------------------------------------*/
- (void) Stop
{
    if( self.MyLink != nil) {
        [self.MyLink Stop];
    }
}

/*-----------------------------------------------------------------------------*/
/** @brief A transmit timeout has occured                                      */
/*-----------------------------------------------------------------------------*/
- (void)transmitTimeout
{
    NSLog(@"controller: transmit timeout");

    // No further action in this demo
}

/*-----------------------------------------------------------------------------*/
/** @brief A receive timeout has occured                                       */
/*-----------------------------------------------------------------------------*/
- (void)receiveTimeout
{
    NSLog(@"controller: receive timeout");

    // No further action in this demo
}

/*-----------------------------------------------------------------------------*/
/** @brief Joystick connection status has changed                              */
/*-----------------------------------------------------------------------------*/
- (void)joystickStatus:(BOOL)status
{
    if(status)
        NSLog(@"Joystick connected");
    else
        NSLog(@"Joystick disconnected");

    // Pass to owner
    if(self.delagate != nil && [self.delagate respondsToSelector:@selector(joystickStatus:)])
        [self.delagate joystickStatus:status];
}

/*-----------------------------------------------------------------------------*/
/** @brief Data link connection status has changed                             */
/*-----------------------------------------------------------------------------*/
- (void)dataStatus:(BOOL)status
{
    if(status)
        NSLog(@"Data connected");
    else
        NSLog(@"Data disconnected");
    
    // Pass to owner
    if(self.delagate != nil && [self.delagate respondsToSelector:@selector(dataStatus:)])
        [self.delagate dataStatus:status];
}

/*-----------------------------------------------------------------------------*/
/** @brief Send a ROBOTC "alive" command to the VexIQ                          */
/*-----------------------------------------------------------------------------*/
- (void) sendAliveCommand
{
    SmartMessage *m = [[SmartMessage alloc] initWithRobotCAlive ];
    
    TxDataCallback callback = ^void (bool status, NSData *data){
        if( status )
            NSLog(@"we are alive");
        else
            NSLog(@"no or bad response");
    };
    
    if( m != nil ) {
        [m sendMessageOnLink:self.MyLink withTxCallback:callback];
    }
}


/*-----------------------------------------------------------------------------*/
/** @brief Send a ROBOTC "user message" command to the VexIQ                   */
/*-----------------------------------------------------------------------------*/
- (void) robotcUserMessageSend:(NSData *)msg withReply:(bool)reply
{
    SmartMessage *m = [[SmartMessage alloc] initWithRobotCUserMessage:msg ];
    
    TxDataCallback callback = ^void (bool status, NSData *data){
        if( status ) {
            NSLog(@"user message sent");
          
            // This user message may be part of some protocol that needs a reply
            if( reply )
                [self robotcUserMessageRequest];
        }
        else
            NSLog(@"no or bad response");
    };
    
    if( m != nil ) {
        [m sendMessageOnLink:self.MyLink withTxCallback:callback];
    }
}

/*-----------------------------------------------------------------------------*/
/** @brief Send a ROBOTC "user message request" command to the VexIQ           */
/*-----------------------------------------------------------------------------*/
- (void) robotcUserMessageRequest
{
    SmartMessage *m = [[SmartMessage alloc] initWithRobotCUserMessageReq ];
    
    TxDataCallback callback = ^void (bool status, NSData *data){
        if( status ) {
            NSLog(@"user message received");
          
            const char *bytes = [data bytes];
            UInt8 messageType = (~bytes[0] & 0xFF);
          
            if( messageType == opcdUsrMsgFunctions && bytes[1] == usgMsgFcn_RequestUsrMsg) {
                if( bytes[2] != 0 ) {
                    // User message from
                    NSLog(@"User message data was available");
                  
                    // Pass payload to owner
                    if(self.delagate != nil && [self.delagate respondsToSelector:@selector(userMessage:)]) {
                        NSData *payload = [data subdataWithRange:NSMakeRange(3, (int)data.length - 4)];
                        [self.delagate userMessage:payload];
                    }
                }
            }
        }
        else
          NSLog(@"no or bad response");
    };
    
    if( m != nil ) {
        [m sendMessageOnLink:self.MyLink withTxCallback:callback];
    }
}

/*-----------------------------------------------------------------------------*/
/** @brief Send a VEX "start program" command to the VexIQ                     */
/*-----------------------------------------------------------------------------*/
- (void) vexSendStartUserProgram:(int)slot
{
    SmartMessage *m = [[SmartMessage alloc] initWithVexCDCStartProgram:slot ];
    
    TxDataCallback callback = ^void (bool status, NSData *data){
        if( status )
            NSLog(@"program started");
        else
            NSLog(@"no or bad response");
    };
    
    if( m != nil ) {
        [m sendMessageOnLink:self.MyLink withTxCallback:callback];
    }
}

/*-----------------------------------------------------------------------------*/
/** @brief Send a VEX "stop program" command to the VexIQ                      */
/*-----------------------------------------------------------------------------*/
- (void) vexSendStopUserProgram
{
    SmartMessage *m = [[SmartMessage alloc] initWithVexCDCStopProgram ];
  
    TxDataCallback callback = ^void (bool status, NSData *data){
      if( status )
          NSLog(@"program stopped");
      else
          NSLog(@"no or bad response");
    };
  
    if( m != nil ) {
        [m sendMessageOnLink:self.MyLink withTxCallback:callback];
    }
}


@end