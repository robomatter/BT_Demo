/*-----------------------------------------------------------------------------*/
/*    SmartRadio.h                                                             */
/*                                                                             */
/*    Created by James Pearman on 7/19/15.                                     */
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

#ifndef _SmartRadio_h
#define _SmartRadio_h

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

@protocol SmartRadioDelegate

@optional

-(void)userTxData:(NSData*)data;
-(void)userTxDataComplete;
-(void)joystickConnectionStatusUpdate:(BOOL)status;
-(void)dataConnectionStatusUpdate:(BOOL)status;

@end

@interface SmartRadio : NSObject <CBPeripheralManagerDelegate>

- (id)   Start:(UInt32)ssn updateRate:(UInt32)rate withJoystick:(BOOL)enableJoystick withData:(BOOL)enableData withDelagate:(id<SmartRadioDelegate>)delagate;
- (void) Stop;

- (void) sendUserData:(NSData *)data;

- (void) JoystickSet_A:(UInt16)js_a B:(UInt16)js_b C:(UInt16)js_c D:(UInt16)js_d;
- (void) JoystickSet_Buttons:(UInt16)js_buttons;
- (void) JoystickSet_Battery:(UInt16)js_battery;
- (void) JoystickSet_PowerOff:(UInt16)js_poweroff;

@end

#define RADIO_MAJOR_VERSION     1
#define RADIO_MINOR_VERSION     1

#define JS_MAJOR_VERSION        0x01
#define JS_MINOR_VERSION        0x05

#define DATA_MAJOR_VERSION      0x01
#define DATA_MINOR_VERSION      0x05

#define DEFAULT_DATA_UPDATE_RATE 1000

#define PROGRAM1                0x0020000     //User Prog1
#define PROGRAM2                0x0028000     //User Prog2
#define PROGRAM3                0x0030000     //User Prog3
#define PROGRAM4                0x0038000     //User Prog4

#define BT_MTU                  20

#define JS_SERVICE_UUID                         @"08590F7E-DB05-467E-8757-72F6FAEB13A5"
#define JS_DATA_CHARACTERISTIC_UUID             @"08590F7E-DB05-467E-8757-72F6FAEB13B5"
#define JS_RATE_CHARACTERISTIC_UUID             @"08590F7E-DB05-467E-8757-72F6FAEB13C5"

#define DATA_SERVICE_UUID                       @"08590F7E-DB05-467E-8757-72F6FAEB13D5"
#define DATA_RXBRAIN_ASYNC_CHAR_UUID            @"08590F7E-DB05-467E-8757-72F6FAEB13F5"
#define DATA_TXBRAIN_CHAR_UUID                  @"08590F7E-DB05-467E-8757-72F6FAEB1306"


typedef struct  //Warning: Keep these long word aligned (4 byte)
{
    UInt8  j1_y          :8; //0
    UInt8  j1_x          :8; //1
    UInt8  j2_y          :8; //2
    UInt8  j2_x          :8; //3
    UInt8  buttons       :8; //4
    UInt8  battery       :8; //5
    UInt8  mainPwr       :8; //6
    UInt8  idletime      :8; //7  seems to be time that we are not subscribed
    UInt8  pwrOffDelay   :8; //8  
    UInt8  contCount     :8; //9
    UInt8  pad1          :8;
    UInt8  pad2          :8;
    UInt8  pad3          :8;
    UInt8  pad4          :8;
    
} JoyStickRecord;

#define JOYBUTN_EU          0x08    //Left side buttons (Upper)
#define JOYBUTN_EL          0x02
#define JOYBUTN_FU          0x04    //Right side buttons (Upper)
#define JOYBUTN_FL          0x01
#define JOYBUTN_LU          0x20    //Left side buttons (Upper)
#define JOYBUTN_LL          0x10
#define JOYBUTN_RU          0x80    //Right side buttons (Upper)
#define JOYBUTN_RL          0x40


#endif