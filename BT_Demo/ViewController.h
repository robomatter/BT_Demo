/*-----------------------------------------------------------------------------*/
/*    ViewController.h                                                         */
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

#import <UIKit/UIKit.h>
#import "SmartController.h"

@interface ViewController : UIViewController <SmartControllerDelegate>
@property (strong, nonatomic) IBOutlet UISwitch *connectSwitch;
@property (strong, nonatomic) IBOutlet UITextField *systemIdText;
@property (strong, nonatomic) IBOutlet UIButton *userButton1;
@property (strong, nonatomic) IBOutlet UIButton *userButton2;
@property (strong, nonatomic) IBOutlet UIButton *userButton3;
@property (strong, nonatomic) IBOutlet UIButton *userButton4;
@property (strong, nonatomic) IBOutlet UILabel *connectionStatus;
@property (strong, nonatomic) IBOutlet UILabel *buttonState;
@property (strong, nonatomic) IBOutlet UILabel *pollCount;


@end

