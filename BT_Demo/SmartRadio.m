/*-----------------------------------------------------------------------------*/
/*    SmartRadio.m                                                             */
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

#import "SmartRadio.h"

//#define _DEBUG

@interface SmartRadio()

@property (strong, nonatomic) CBPeripheralManager       *peripheralManager;
@property (strong, nonatomic) CBMutableCharacteristic   *dataCharacteristic;
@property (strong, nonatomic) CBMutableCharacteristic   *rateCharacteristic;
@property (strong, nonatomic) CBMutableCharacteristic   *dataTxCharacteristic;
@property (strong, nonatomic) CBMutableCharacteristic   *dataRxCharacteristic;
@property (nonatomic) UInt32                            SSN;

@property (nonatomic, assign) id                        delagate;

@property (nonatomic) BOOL                              joystickServiceEnabled;
@property (nonatomic) BOOL                              dataServiceEnabled;

@property (nonatomic) UInt16                            updateRate;
@property (strong, nonatomic) NSTimer                   *updateTimer;

@property (nonatomic) BOOL                              btInitialized;
@property (nonatomic) BOOL                              tmInitialized;
@property (nonatomic) UInt16                            contCount;

@property (nonatomic) UInt16                            JS_A;
@property (nonatomic) UInt16                            JS_B;
@property (nonatomic) UInt16                            JS_C;
@property (nonatomic) UInt16                            JS_D;
@property (nonatomic) UInt16                            JS_Buttons;
@property (nonatomic) UInt16                            JS_Battery;
@property (nonatomic) UInt16                            JS_MainPower;
@property (nonatomic) UInt16                            JS_IdleTime;
@property (nonatomic) UInt16                            JS_PowerOffDelay;

@property (strong, atomic) NSMutableArray              *userDataQueue;
@property (strong, atomic) NSLock                      *userdataLock;

@end

@implementation SmartRadio

/*-----------------------------------------------------------------------------*/
/** @brief Start the Smart Radio bluetooth simulation                          */
/*-----------------------------------------------------------------------------*/

- (id)Start:(UInt32)ssn updateRate:(UInt32)rate withJoystick:(BOOL)enableJoystick withData:(BOOL)enableData withDelagate:(id<SmartRadioDelegate>)delagate
{
    NSLog(@"Smart Radio Start with SSN %d", (unsigned int)ssn);

    id newInstance = [super init];
    if (newInstance) {
        self.delagate = delagate;
        
        // Save the enable state of the two possible services
        _joystickServiceEnabled = enableJoystick;
        _dataServiceEnabled     = enableData;

        // Get a peripheralManager object, use default queue
        _peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil];
        
        _SSN = ssn;
        
        if( rate != 0 )
            _updateRate = rate;
        else
            _updateRate = DEFAULT_DATA_UPDATE_RATE;
        
        // Set default values for the joystick data structure
        _JS_A = 0x7F;
        _JS_B = 0x7F;
        _JS_C = 0x7F;
        _JS_D = 0x7F;
        _JS_Buttons = 0;
        _JS_Battery = 0xBf;
        _JS_MainPower = 0x8A;
        _JS_IdleTime = 0;
        _JS_PowerOffDelay = 0;
        
        _btInitialized = false;
        _tmInitialized = false;

        //_userdataLock =  [[NSLock alloc] init];
        _userDataQueue = [[NSMutableArray alloc] init];
    }
    
    return newInstance;
}

/*-----------------------------------------------------------------------------*/
/** @brief Stop the Smart Radio bluetooth simulation                           */
/*-----------------------------------------------------------------------------*/

- (void) Stop
{
    if (self.updateTimer != nil) {
        [self.updateTimer invalidate];
        self.updateTimer = nil;
        self.tmInitialized = FALSE;
    }
    
    if( self.peripheralManager != nil ) {
        [self.peripheralManager stopAdvertising];
        [self.peripheralManager removeAllServices];
        self.peripheralManager = nil;
        self.btInitialized     = FALSE;
        [self.userDataQueue removeAllObjects];
    }
}

/*-----------------------------------------------------------------------------*/
/** @brief Update the joystick analog values                                   */
/*-----------------------------------------------------------------------------*/

- (void) JoystickSet_A:(UInt16)js_a B:(UInt16)js_b C:(UInt16)js_c D:(UInt16)js_d
{
    self.JS_A = js_a;
    self.JS_B = js_b;
    self.JS_C = js_c;
    self.JS_D = js_d;
}

/*-----------------------------------------------------------------------------*/
/** @brief Update the joystick button value                                    */
/*-----------------------------------------------------------------------------*/

- (void) JoystickSet_Buttons:(UInt16)js_buttons
{
    self.JS_Buttons = js_buttons;
}

/*-----------------------------------------------------------------------------*/
/** @brief Update the joystick battery level                                   */
/*-----------------------------------------------------------------------------*/

- (void) JoystickSet_Battery:(UInt16)js_battery
{
    self.JS_Buttons = js_battery;
}

/*-----------------------------------------------------------------------------*/
/** @brief Update the power off delay                                          */
/*-----------------------------------------------------------------------------*/

- (void) JoystickSet_PowerOff:(UInt16)js_poweroff
{
    self.JS_PowerOffDelay = js_poweroff;
}

/*-----------------------------------------------------------------------------*/
/** @brief Create the joystick control service                                 */
/*-----------------------------------------------------------------------------*/

- (CBMutableService *) createJoystickService
{
    //CBUUID *userDescriptionUUID = [CBUUID UUIDWithString:CBUUIDCharacteristicUserDescriptionString];
    //CBMutableDescriptor *dataDescriptor = [[CBMutableDescriptor alloc]initWithType:userDescriptionUUID value:@"JSSim.Data"];
    //CBMutableDescriptor *rateDescriptor = [[CBMutableDescriptor alloc]initWithType:userDescriptionUUID value:@"JSSim.Rate"];
 
    // Create joystick data characteristoic
    self.dataCharacteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:JS_DATA_CHARACTERISTIC_UUID]
                                                                 properties:CBCharacteristicPropertyIndicate | CBCharacteristicPropertyNotify | CBCharacteristicPropertyRead
                                                                      value:nil
                                                                permissions:CBAttributePermissionsReadable];
        
 
    // Vex Brain did not like the use of these, no idea why
    //self.dataCharacteristic.descriptors = @[dataDescriptor];
       
    // Create joystick rate characteristoic
    self.rateCharacteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:JS_RATE_CHARACTERISTIC_UUID]
                                                                 properties:CBCharacteristicPropertyRead | CBCharacteristicPropertyWriteWithoutResponse | CBCharacteristicPropertyWrite
                                                                      value:nil
                                                                permissions:CBAttributePermissionsReadable | CBAttributePermissionsWriteable];
 
    // Vex Brain did not like the use of these, no idea why
    //self.rateCharacteristic.descriptors = @[rateDescriptor];
        
    // Create the service
    CBMutableService *joystickService = [[CBMutableService alloc] initWithType:[CBUUID UUIDWithString:JS_SERVICE_UUID] primary:YES];
    
    // Add the characteristics to the service
    joystickService.characteristics = @[self.dataCharacteristic, self.rateCharacteristic, ];
   
    NSLog(@"Joystick service created");
    
    return joystickService;
}

/*-----------------------------------------------------------------------------*/
/** @brief Create the data service                                             */
/*-----------------------------------------------------------------------------*/

- (CBMutableService *) createDataService
{
    //CBUUID *userDescriptionUUID = [CBUUID UUIDWithString:CBUUIDCharacteristicUserDescriptionString];
    //CBMutableDescriptor *rxDescriptor = [[CBMutableDescriptor alloc]initWithType:userDescriptionUUID value:@"RxData"];
    //CBMutableDescriptor *txDescriptor = [[CBMutableDescriptor alloc]initWithType:userDescriptionUUID value:@"TxData"];

    // Create rx characteristoic
    self.dataRxCharacteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:DATA_RXBRAIN_ASYNC_CHAR_UUID]
                                                                   properties:CBCharacteristicPropertyNotify | CBCharacteristicPropertyRead
                                                                        value:nil
                                                                  permissions:CBAttributePermissionsReadable];
  
   // Vex Brain did not like the use of these, no idea why
   //self.dataRxCharacteristic.descriptors = @[rxDescriptor];

    // Create tx characteristoic
    self.dataTxCharacteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:DATA_TXBRAIN_CHAR_UUID]
                                                                   properties:CBCharacteristicPropertyRead | CBCharacteristicPropertyWrite | CBCharacteristicPropertyWriteWithoutResponse
                                                                        value:nil
                                                                  permissions:CBAttributePermissionsReadable | CBAttributePermissionsWriteable];
    
    // Vex Brain did not like the use of these, no idea why
    //self.dataTxCharacteristic.descriptors = @[txDescriptor];
    
    // Create the service
    CBMutableService *dataService = [[CBMutableService alloc] initWithType:[CBUUID UUIDWithString:DATA_SERVICE_UUID] primary:YES];
        
    // Add the characteristics to the service
    dataService.characteristics = @[self.dataRxCharacteristic, self.dataTxCharacteristic, ];

    NSLog(@"Data service created");
    
    return( dataService );
}

/*-----------------------------------------------------------------------------*/
/** @brief Callback from CB when bluetooth state changes                       */
/*-----------------------------------------------------------------------------*/

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
{
    NSLog(@"peripheralManagerDidUpdateState: %d", (int)peripheral.state);
    
    if (CBPeripheralManagerStatePoweredOn == peripheral.state) {
        if( !_joystickServiceEnabled && !_dataServiceEnabled ) {
            NSLog(@"No services were enabled");
            return;
        }
            
        NSLog(@"Add services");
        
        // Add joystick service
        if( _joystickServiceEnabled )
            [peripheral addService:[self createJoystickService]];

        // And data service
        if( _dataServiceEnabled )
            [peripheral addService:[self createDataService]];

        // Start advertising
        NSLog(@"Start advertizing");
        [peripheral startAdvertising:@{ CBAdvertisementDataServiceUUIDsKey : @[[CBUUID UUIDWithString:JS_SERVICE_UUID]],
                                        CBAdvertisementDataLocalNameKey:[NSString stringWithFormat:@"%d-%d-%d-%d-%d", (unsigned int)self.SSN, JS_MAJOR_VERSION, JS_MINOR_VERSION,RADIO_MAJOR_VERSION,RADIO_MINOR_VERSION]}];

        self.btInitialized = YES;
        }
}

/*-----------------------------------------------------------------------------*/
/** @brief Callback from CB when bluetooth starts advertizing                  */
/*-----------------------------------------------------------------------------*/

- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral error:(NSError *)error
{
    NSLog(@"peripheralManagerDidStartAdvertising: %@", error);
}

/*-----------------------------------------------------------------------------*/
/** @brief Callback from CB when service is added                              */
/*-----------------------------------------------------------------------------*/

- (void)peripheralManager:(CBPeripheralManager *)peripheral didAddService:(CBService *)service error:(NSError *)error
{
#ifdef _DEBUG
    NSLog(@"peripheralManagerDidAddService: %@ %@", service, error);
#endif
}

/*-----------------------------------------------------------------------------*/
/** @brief Callback when we receive write request                              */
/*-----------------------------------------------------------------------------*/

- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveWriteRequests:(NSArray *)requests
{
    CBATTRequest*       request = [requests  objectAtIndex: 0];
    
    [peripheral respondToRequest:request    withResult:CBATTErrorSuccess];

    //NSLog(@"Write request %@",request.characteristic.UUID);
    
    if([request.characteristic.UUID isEqual: [CBUUID UUIDWithString:JS_RATE_CHARACTERISTIC_UUID]] ) {
        
        UInt16 newUpdateRate = 0;
        if( [request.value length] >= 2 )
            memcpy(&newUpdateRate, [request.value bytes], 2);
        else
        if( [request.value length] == 1 )
            memcpy(&newUpdateRate, [request.value bytes], 1);
        
        NSLog(@"Recived new Update Rate %d", newUpdateRate);
        
        if( newUpdateRate > 10 ) {
            self.updateRate = newUpdateRate;
            }
        
        // Restart the timer
        if( self.tmInitialized )
            [self startTimer];
    }
    if([request.characteristic.UUID isEqual: [CBUUID UUIDWithString:DATA_TXBRAIN_CHAR_UUID]] ) {
        NSLog(@"Recived tx data from brain %lu bytes", [request.value length] );
        
        [self debugPacket:request.value ];
       
        // Callback here
        if(self.delagate != nil && [self.delagate respondsToSelector:@selector(userTxData:)]) {
            [self.delagate userTxData:request.value];
        }
        return;

    }
}

/*-----------------------------------------------------------------------------*/
/** @brief Callback when we receive read request                               */
/*-----------------------------------------------------------------------------*/

- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveReadRequest:(CBATTRequest *)request
{
    //NSLog(@"Read Request");

    if([request.characteristic.UUID isEqual: [CBUUID UUIDWithString:JS_RATE_CHARACTERISTIC_UUID]] )
        {
        UInt16 rate = self.updateRate;
        request.value = [NSData dataWithBytes:&rate length:sizeof(rate)];
    
        [peripheral respondToRequest:request    withResult:CBATTErrorSuccess];
        }
    else
    if([request.characteristic.UUID isEqual: [CBUUID UUIDWithString:JS_DATA_CHARACTERISTIC_UUID]] )
        {
        request.value = [self getJoystickData];
    
        [peripheral respondToRequest:request    withResult:CBATTErrorSuccess];
        }
    else
    [peripheral respondToRequest:request    withResult:CBATTErrorReadNotPermitted];
}

/*-----------------------------------------------------------------------------*/
/** @brief Callback when someone subscribes to a characteristic                */
/*-----------------------------------------------------------------------------*/

- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic
{
    if([characteristic.UUID isEqual: [CBUUID UUIDWithString:JS_DATA_CHARACTERISTIC_UUID]] )
        {
        NSLog(@"Central subscribed to JS Data");
        
        [self startTimer];
        // Callback here
        if(self.delagate != nil && [self.delagate respondsToSelector:@selector(joystickConnectionStatusUpdate:)])
            [self.delagate joystickConnectionStatusUpdate:true];
        }
    
    if( [characteristic.UUID isEqual: [CBUUID UUIDWithString:DATA_RXBRAIN_ASYNC_CHAR_UUID]] )
        {
        NSLog(@"Central subscribed to RX Data Ready");
        // Callback here
        if(self.delagate != nil && [self.delagate respondsToSelector:@selector(dataConnectionStatusUpdate:)])
            [self.delagate dataConnectionStatusUpdate:true];
        }
}

/*-----------------------------------------------------------------------------*/
/** @brief Callback when someone unsubscribes to a characteristic              */
/*-----------------------------------------------------------------------------*/
- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic
{
    NSLog(@"Central unsubscribed");

    if([characteristic.UUID isEqual: [CBUUID UUIDWithString:JS_DATA_CHARACTERISTIC_UUID]] )
        {
        NSLog(@"Central unsubscribed to JS Data");
        [self stopTimer];
        // Callback here
        if(self.delagate != nil && [self.delagate respondsToSelector:@selector(joystickConnectionStatusUpdate:)])
            [self.delagate joystickConnectionStatusUpdate:false];
        }
    
    if( [characteristic.UUID isEqual: [CBUUID UUIDWithString:DATA_RXBRAIN_ASYNC_CHAR_UUID]] )
        {
        NSLog(@"Central unsubscribed to RX Data Ready");
        // Callback here
        if(self.delagate != nil && [self.delagate respondsToSelector:@selector(dataConnectionStatusUpdate:)])
            [self.delagate dataConnectionStatusUpdate:false];
        }
}

/*-----------------------------------------------------------------------------*/
/** @brief Callback when PeripheralManager is ready to send data               */
/*-----------------------------------------------------------------------------*/
/** @details
 *   This callback comes in when the PeripheralManager is ready to send the 
 *   next chunk of data.  This ensures that packets will arrive in the order
 *   they are sent
 */

- (void)peripheralManagerIsReadyToUpdateSubscribers:(CBPeripheralManager *)peripheral
{
    NSLog(@"UpdateSubscribers:queue size %d", (int) self.userDataQueue.count );
    
    // Check we have a queue - why wouldn't we?
    if(self.userDataQueue == nil)
        return;

    // Send more data until BT buffer is full
    while(self.userDataQueue.count > 0) {
        // Send packet at start of array
        if([self.peripheralManager updateValue:[self.userDataQueue firstObject] forCharacteristic:self.dataRxCharacteristic onSubscribedCentrals:nil] != YES) {
            // Packet could not be sent
            // So get out until this callback fires again
            NSLog(@"UpdateSubscribers: Tx buffer full with queue at (%d)", (int) self.userDataQueue.count);
            break;
        }
        else {
            [self debugPacket:[self.userDataQueue firstObject] ];
            // Packet sent so remove it from the array
            [self.userDataQueue removeObjectAtIndex: 0];
        }
    }

    // Are we done?
    if( 0 == self.userDataQueue.count ) {
        NSLog(@"UpdateSubscribers: queue empty");
        // Callback here
        if(self.delagate != nil && [self.delagate respondsToSelector:@selector(userTxDataComplete)]) {
            [self.delagate userTxDataComplete];
        }
    }
}

- (void)debugPacket:(NSData *)packet
{
    int capacity = (int)packet.length * 3;
    
    NSMutableString *sbuf = [NSMutableString stringWithCapacity:capacity];
    
    const unsigned char *buf = packet.bytes;
    
    int i;
    
    for (i=0; i<packet.length; ++i) {
        [sbuf appendFormat:@"%02X ", (int)buf[i]];
    }
    
    NSLog( sbuf, nil );
}

/*-----------------------------------------------------------------------------*/
/** @brief Start notification timer                                            */
/*-----------------------------------------------------------------------------*/

- (void)startTimer
{
    [self stopTimer];

    // updateRate is in mS
    double updaterate = (double)self.updateRate / 1000.00;

    self.updateTimer = [NSTimer scheduledTimerWithTimeInterval:updaterate
                                                            target:self
                                                          selector:@selector(sendJoystickData)
                                                          userInfo:nil
                                                           repeats:YES];
    // Timer is initialized
    self.tmInitialized = true;
}

/*-----------------------------------------------------------------------------*/
/** @brief Stop notification timer                                             */
/*-----------------------------------------------------------------------------*/

- (void)stopTimer
{
    if (self.updateTimer != nil) {
        [self.updateTimer invalidate];
        self.updateTimer = nil;
        self.tmInitialized = false;
    }
}

/*-----------------------------------------------------------------------------*/
/** @brief Send data for JS data characteristic                                */
/*-----------------------------------------------------------------------------*/

-(void) sendJoystickData
{
    NSData *JS = [self getJoystickData];
    
    //NSLog(@"Sending JS Update %d", self.contCount);
    
    if(self.btInitialized) {        
        if(![self.peripheralManager updateValue:JS forCharacteristic:self.dataCharacteristic onSubscribedCentrals:nil]) {
            NSLog(@"Failed Sending JS Update");
        }
    }
}

/*-----------------------------------------------------------------------------*/
/** @brief Send raw data for RX data characteristic (user message)             */
/*-----------------------------------------------------------------------------*/

-(void) sendTxData:(NSData *)data
{
    if(self.btInitialized) {
        if(![self.peripheralManager updateValue:data forCharacteristic:self.dataRxCharacteristic onSubscribedCentrals:nil]) {
            NSLog(@"Failed Sending TX Data");
        }
    }
}

/*-----------------------------------------------------------------------------*/
/** @brief Send and queue data for RX data characteristic (user message)       */
/*-----------------------------------------------------------------------------*/

-(void) sendUserData:(NSData *)data
{
    BOOL  sendData = true;
    
    // Check we have a queue - why wouldn't we?
    if(self.userDataQueue == nil)
        return;
    
    NSLog(@"sendUserData:length %d",(int)data.length );
    
    // Do we need a mutex in this call??
    
    // Do we already have data in the queue?
    if( self.userDataQueue.count > 0 ) {
        // We are already sending data
        sendData = false;
    }
        
    // Add to queue
    if( data.length < BT_MTU ) {
        // We can just add
        [self.userDataQueue addObject: data];
    }
    else {
        // We break up into packets of BT_MTU length or less
        int index = 0;
        int datalen;

        while (index < data.length ) {
            // Get length of next packet
            if( index + BT_MTU > data.length )
                datalen = (int)data.length - index;
            else
                datalen = BT_MTU;

            // Create a new packet
            NSData *pak = [data subdataWithRange:NSMakeRange(index, datalen)];

            // Add one packet
            [self.userDataQueue addObject: pak];
            
            index += datalen;
        }
    }
    
    NSLog(@"sendUserData:queue size %d", (int) self.userDataQueue.count );
    
    // Now send the data unless we had filled the BT buffer and the callback is handling this
    if( sendData ) {
        while(self.userDataQueue.count > 0) {
            // Send packet at start of array
            if([self.peripheralManager updateValue:[self.userDataQueue firstObject] forCharacteristic:self.dataRxCharacteristic onSubscribedCentrals:nil] != YES) {
                // Packet could not be sent
                // So get out and allow the peripheralManagerIsReadyToUpdateSubscribers
                // callback do the rest of the work.
                NSLog(@"sendUserData: Tx buffer full with queue at (%d)", (int) self.userDataQueue.count);
                break;
            }
            else {
                [self debugPacket:[self.userDataQueue firstObject] ];
                // Packet sent so remove it from the array
                [self.userDataQueue removeObjectAtIndex: 0];
            }
        }
    }

    // Are we done?
    if( 0 == self.userDataQueue.count ) {
        NSLog(@"sendUserData: queue empty");
        // Callback here
        if(self.delagate != nil && [self.delagate respondsToSelector:@selector(userTxDataComplete)]) {
            [self.delagate userTxDataComplete];
        }
    }
}


/*-----------------------------------------------------------------------------*/
/** @brief Create data message for JS data characteristic                      */
/*-----------------------------------------------------------------------------*/

-(NSData *) getJoystickData
{
    JoyStickRecord jsData =
    {
        .j1_y        = self.JS_D,
        .j1_x        = self.JS_C,
        .j2_y        = self.JS_A,
        .j2_x        = self.JS_B,
        .buttons     = self.JS_Buttons,
        .battery     = self.JS_Battery,
        .mainPwr     = self.JS_MainPower,
        .idletime    = self.JS_IdleTime,
        .pwrOffDelay = self.JS_PowerOffDelay,
        .contCount   = self.contCount,
        .pad1        = 0,
        .pad2        = 0,
        .pad3        = 0,
        .pad4        = 0,
    };

    self.contCount = (self.contCount + 1) % 255;
    
    return [NSData dataWithBytes:&jsData length:sizeof(jsData)];
}

@end
