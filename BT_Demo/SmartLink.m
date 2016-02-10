/*-----------------------------------------------------------------------------*/
/*    SmartLink.m                                                              */
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

@interface SmartLink()

typedef enum _tTimeoutType {
    kTimeoutTypeUndefined,
    kTimeoutTypeTransmit,
    kTimeoutTypeReceive
} tTimeoutType;

@property (nonatomic) tTimeoutType                      timeoutType;
@property (strong, nonatomic) NSTimer                  *timeoutTimer;
@property (nonatomic) BOOL                              tmInitialized;
@property (nonatomic, assign) id                        tmDelagate;
@property (nonatomic) BOOL                              waitForReply;
@property (nonatomic) int16_t                           waitForReplyTime;

@property (strong, nonatomic)   TxDataCallback          TxCallback;
@property (nonatomic)           NSUInteger              expectedReplyLength;
@property (nonatomic)           NSUInteger              currentReplyLength;
@property (strong, nonatomic)   NSMutableData          *receivedData;

@end

@implementation SmartLink

/*-----------------------------------------------------------------------------*/
/** @brief Start communications                                                */
/*-----------------------------------------------------------------------------*/
- (id)Start:(UInt32)ssn updateRate:(UInt32)rate withJoystick:(BOOL)enableJoystick withData:(BOOL)enableData withDelagate:(id<SmartLinkDelegate>)delagate;
{
    NSLog(@"Smart Link Start with SSN %d", (unsigned int)ssn);

    self.tmDelagate  = delagate;
    self.timeoutType = kTimeoutTypeUndefined;
  
    return( [super Start:ssn updateRate:rate withJoystick:enableJoystick withData:enableData withDelagate:(id)self] );
}

/*-----------------------------------------------------------------------------*/
/** @brief Stop communications                                                 */
/*-----------------------------------------------------------------------------*/
- (void) Stop
{
  [super Stop];
}

/*-----------------------------------------------------------------------------*/
/** @brief received some data from the VexIQ                                   */
/*-----------------------------------------------------------------------------*/
-(void)userTxData:(NSData*)data
{
    NSLog(@"receive data");
    [self stopTimeoutTimer];

    self.currentReplyLength += data.length;
  
    if( self.receivedData != nil ) {
        // copy the received data
        [self.receivedData appendData:data];
      
        if( self.currentReplyLength >= self.expectedReplyLength ) {
            // All data is received
            [self decodeReceivedPacket:self.receivedData];
        }
        else {
            // More to come - restart timeout
            [self startTimerWithMs:self.waitForReplyTime andType:kTimeoutTypeReceive];
        }
    }
}

/*-----------------------------------------------------------------------------*/
/** @brief message send complete                                               */
/*-----------------------------------------------------------------------------*/
-(void)userTxDataComplete
{
    NSLog(@"transmit complete");
    [self stopTimeoutTimer];
    
    if( self.waitForReply ) {
        [self startTimerWithMs:self.waitForReplyTime andType:kTimeoutTypeReceive];
    }
}

/*-----------------------------------------------------------------------------*/
/** @brief callback when joystick connection status changes                    */
/*-----------------------------------------------------------------------------*/
- (void)joystickConnectionStatusUpdate:(BOOL)status
{
    if(self.tmDelagate != nil && [self.tmDelagate respondsToSelector:@selector(joystickStatus:)])
        [self.tmDelagate joystickStatus:status];
}

/*-----------------------------------------------------------------------------*/
/** @brief callback when data connection status changes                        */
/*-----------------------------------------------------------------------------*/
- (void)dataConnectionStatusUpdate:(BOOL)status
{
    if(self.tmDelagate != nil && [self.tmDelagate respondsToSelector:@selector(dataStatus:)])
        [self.tmDelagate dataStatus:status];
}

/*-----------------------------------------------------------------------------*/
/** @brief Send message                                                        */
/*-----------------------------------------------------------------------------*/
-(void)sendMessage:(NSData *)message waitForReply:(bool)wait forMs:(int)ms withReplyLength:(int)replyLength withTxCallback:(TxDataCallback)callback
{
    // should we expect a reply
    // in other workds, should we start the receive data timeout after transmit
    // is complete
    self.waitForReply = wait;
    self.waitForReplyTime  = ms;
    self.expectedReplyLength = replyLength;
    self.currentReplyLength = 0;
    
    // create object for receive data
    self.receivedData = [[NSMutableData alloc] initWithCapacity:0];
    
    // Notification callback when transaction is complete
    self.TxCallback = callback;

    // Start transmit timeout and send message
    [self startTimerWithMs:250 andType:kTimeoutTypeTransmit];
    [self sendUserData:message];
}


/*-----------------------------------------------------------------------------*/
/** @brief Start timeout timer                                                 */
/*-----------------------------------------------------------------------------*/
- (void)startTimerWithMs:(int16_t)ms andType:(tTimeoutType)type
{
    [self stopTimeoutTimer];
    
    // set type of timeout
    self.timeoutType = type;
    
    // updateRate is in mS
    double timeoutTime = (double)ms / 1000.00;
    
    self.timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:timeoutTime
                                                         target:self
                                                       selector:@selector(timeoutCallback:)
                                                       userInfo:nil
                                                        repeats:NO];
    // Timer is initialized
    self.tmInitialized = true;
}

/*-----------------------------------------------------------------------------*/
/** @brief Stop timeout timer                                                  */
/*-----------------------------------------------------------------------------*/
- (void)stopTimeoutTimer
{
    if (self.timeoutTimer != nil) {
        [self.timeoutTimer invalidate];
        self.timeoutTimer = nil;
        self.tmInitialized = false;
    }
}

/*-----------------------------------------------------------------------------*/
/** @brief message timeout                                                     */
/*-----------------------------------------------------------------------------*/
-(void) timeoutCallback:(NSTimer *)timer
{
    [self stopTimeoutTimer];

    if( self.timeoutType == kTimeoutTypeTransmit ) {
        NSLog(@"Transmit timeout");
        self.timeoutType = kTimeoutTypeUndefined;

        // Callback here
        if(self.tmDelagate != nil && [self.tmDelagate respondsToSelector:@selector(transmitTimeout)]) {
            [self.tmDelagate transmitTimeout];
        }
    }
    if( self.timeoutType == kTimeoutTypeReceive ) {
        NSLog(@"Receive Timeout");
        self.timeoutType = kTimeoutTypeUndefined;
        
        // Callback here
        if(self.tmDelagate != nil && [self.tmDelagate respondsToSelector:@selector(receiveTimeout)]) {
            [self.tmDelagate receiveTimeout];
        
        // We may be waiting for data
        if(self.TxCallback != nil)
            self.TxCallback(false, nil);
        }
    }
    
}

/*-----------------------------------------------------------------------------*/
/** @brief decode VEX CDC packet                                               */
/*-----------------------------------------------------------------------------*/
- (bool) decodeReceiveCDCPacket:(NSData *)data
{
    bool    cdcStatus = false;
    // Check packet
    if( data.length >= 5 ) {
        UInt8 bytes[data.length];
        [data getBytes:bytes length:sizeof(bytes)];
   
        // check header
        if( bytes[0] == CDC_REPLY_HEADER1 && bytes[1] == CDC_REPLY_HEADER2 ) {
            // Good header - find the function
            UInt8 function = bytes[2];
            
            switch(function) {
                case CDC_GEN_ACK:
                    // check ack byte
                    if( bytes[3] == 1 && bytes[4] == CDC_RESPONSE_ACK )
                        cdcStatus = true;
                    break;
                    
                case CMD_GET_COMPONENTS:
                    // Unfortunately the reply does not include the port number
                    // so we need the calling class to call the decode function
                    cdcStatus = true;
                    break;
                    
                default:
                    cdcStatus = true;
                    break;
            }
        }
    }
  
    return  cdcStatus;
}

/*-----------------------------------------------------------------------------*/
/** @brief decode VEX CDC received port data                                   */
/*-----------------------------------------------------------------------------*/
- (void) decodeReceiveCDCPortData:(NSData *)data forPort:(NSUInteger)port
{
    UInt8 bytes[data.length];
    [data getBytes:bytes length:sizeof(bytes)];
    
    // decode port data here
    // not implemented in this example code
}

/*-----------------------------------------------------------------------------*/
/** @brief decode received packet from VexIQ                                   */
/*-----------------------------------------------------------------------------*/
- (void) decodeReceivedPacket:(NSData *)data
{
    bool    replyStatus = false;
    // We will assume that we are not out of sync
    // that is, the first byte of the received data
    // is the expected message type

    const char *bytes = [data bytes];

    // ROBOTC header byte is one's copmpliment of message type
    UInt8 messageType = (~bytes[0] & 0xFF);
    
    switch( messageType ) {
        case (~CDC_REPLY_HEADER1 & 0xFF):
            replyStatus = [self decodeReceiveCDCPacket:data];
            break;

        // Not a CDC pack so we assume it is a ROBOTC packet
        // only two opcodes understood by this demo code
        case opcdAlive:
            // We are alive
            replyStatus = true;
            break;
        
        case opcdUsrMsgFunctions:
              // We have reply to user message
            replyStatus = true;
            break;
        }
    
    
    if(self.TxCallback != nil)
        self.TxCallback(replyStatus, data);
}


@end
