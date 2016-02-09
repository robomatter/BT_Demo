/*-----------------------------------------------------------------------------*/
/*    ViewController.m                                                         */
/*                                                                             */
/*    Created by James Pearman on 2/8/16.                                      */
/*    Copyright (c) 2016 robomatter. All rights reserved.                      */
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

#import "ViewController.h"
#import "GlobalData.h"
#import "SmartController.h"

@interface ViewController ()

@property (strong, nonatomic) SmartController       *myController;
@property (strong, nonatomic) NSTimer               *pollTimer;
@property (nonatomic)         UInt32                 pollCounter;

@end

@implementation ViewController

/*-----------------------------------------------------------------------------*/
- (void)viewDidLoad {
    [super viewDidLoad];

    // Create toolbar for the keypad
    UIToolbar* numberToolbar = [[UIToolbar alloc]initWithFrame:CGRectMake(0, 0, 320, 50)];
    numberToolbar.barStyle = UIBarStyleDefault;
    numberToolbar.items = [NSArray arrayWithObjects:
                           [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                           [[UIBarButtonItem alloc]initWithTitle:@"Apply" style:UIBarButtonItemStyleDone target:self action:@selector(doneWithNumberPad)],
                           nil];
    [numberToolbar sizeToFit];
    self.systemIdText.inputAccessoryView = numberToolbar;
  
    // Set initial state of the system id test field
    NSInteger ssn = [GlobalVariables getInstance].ssn;

    if( ssn == 0 )
        self.systemIdText.text = @"0000";
    else
        self.systemIdText.text = [NSString stringWithFormat:@"%ld", ssn];
}

/*-----------------------------------------------------------------------------*/
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*-----------------------------------------------------------------------------*/
/** @brief Dismiss keyboard when apply selected                                */
/*-----------------------------------------------------------------------------*/
-(void)doneWithNumberPad{
    [self.systemIdText resignFirstResponder];
    [GlobalVariables setBrainSsn:[_systemIdText.text intValue]];
}

/*-----------------------------------------------------------------------------*/
/** @brief Dismiss keyboard if background touched                              */
/*-----------------------------------------------------------------------------*/
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.view endEditing:YES];
    [GlobalVariables setBrainSsn:[_systemIdText.text intValue]];
}

/*-----------------------------------------------------------------------------*/
/** @brief Status of data link changed                                         */
/*-----------------------------------------------------------------------------*/
- (void)joystickStatus:(BOOL)status
{
    // Not used in demo
}

/*-----------------------------------------------------------------------------*/
/** @brief Status of data link changed                                         */
/*-----------------------------------------------------------------------------*/
- (void)dataStatus:(BOOL)status
{
    if( status ) {
        self.connectionStatus.text = @"Connected";
        [self initPollTimer];
    }
    else {
        self.connectionStatus.text = @"------";
        self.buttonState.text = @"(----)";
        [self.connectSwitch setOn:false animated:true];
      
        [self stopPollTimer];
    }
}

/*-----------------------------------------------------------------------------*/
/** @brief User pressed connect switch                                         */
/*-----------------------------------------------------------------------------*/
- (IBAction)connectPressed:(id)sender {
    if( self.connectSwitch.on ) {
        int systemId = [_systemIdText.text intValue];

        NSLog(@"connect %d", systemId);
        
        // Try and connect to IQ Brain
        self.myController = [[SmartController alloc] init:systemId withDelagate:self];
        self.connectionStatus.text = @"Connecting....";
    }
    else {
        NSLog(@"Disconnect");
        [self.myController Stop];
        self.connectionStatus.text = @"------";
        self.buttonState.text = @"(----)";

        [self stopPollTimer];
    }
}

/*-----------------------------------------------------------------------------*/
/** @brief User pressed one of the buttons                                     */
/*-----------------------------------------------------------------------------*/
- (IBAction)userButtonPressed:(id)sender {
    int  buttonId = 0;
    
    NSLog(@"Send user message ");

    // Which button
    if(sender == _userButton1 )
        buttonId = 1;
    if(sender == _userButton2 )
        buttonId = 2;
    if(sender == _userButton3 )
        buttonId = 3;
    if(sender == _userButton4 )
        buttonId = 4;
    
    // If we have connected then send message
    if( self.myController != nil ) {
        char data[] = { 'u', 's', 'r', buttonId };
        
        NSData *cmd = [NSData dataWithBytes:data length:sizeof(data) ];
        
        [self.myController robotcUserMessageSend:cmd withReply:false];
    }
}

/*-----------------------------------------------------------------------------*/
/** @brief user message payload received                                       */
/*-----------------------------------------------------------------------------*/
- (void) userMessage:(NSData *)msg
{
    const unsigned char *bytes = [msg bytes];

    if( bytes[0] == 0x80 && bytes[1] == 1 ) {
        NSLog(@"pressed");
        self.buttonState.text = @"(pressed)";
    }
    else
    if( bytes[0] == 0x80 && bytes[1] == 0 ) {
        NSLog(@"release");
        self.buttonState.text = @"(release)";
    }
    else {
        NSLog(@"unknown msg");
        self.buttonState.text = @"(----)";
    }
}

/*-----------------------------------------------------------------------------*/
/** @brief Init poll timer                                                     */
/*-----------------------------------------------------------------------------*/
- (void) initPollTimer
{
    double timeoutTime = 0.20;

    self.pollTimer = [NSTimer scheduledTimerWithTimeInterval:timeoutTime
                                                      target:self
                                                    selector:@selector(timeoutCallback:)
                                                    userInfo:nil
                                                    repeats:YES];
}

/*-----------------------------------------------------------------------------*/
/** @brief Stop poll timer                                                     */
/*-----------------------------------------------------------------------------*/
- (void)stopPollTimer
{
  if (self.pollTimer != nil) {
      [self.pollTimer invalidate];
      self.pollTimer = nil;
  }
}

/*-----------------------------------------------------------------------------*/
/** @brief poll timer callback - ask for user message data from brain          */
/*-----------------------------------------------------------------------------*/
-(void) timeoutCallback:(NSTimer *)timer
{
    NSLog(@"Poll Timer");
  
    if( self.myController != nil )
    {
      [self.myController robotcUserMessageRequest];
      self.pollCount.text = [NSString stringWithFormat:@"%d", self.pollCounter++];
      
    }
}

@end
