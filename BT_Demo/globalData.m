/*-----------------------------------------------------------------------------*/
/*    globalData.m                                                             */
/*                                                                             */
/*    Created by James Pearman on 2/8/16.                                      */
/*    From code by Jacob Palnick created on 4/24/15.                           */
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

#import "globalData.h"

@implementation GlobalVariables

/*-----------------------------------------------------------------------------*/
/** @brief init global variables                                               */
/*-----------------------------------------------------------------------------*/
- (instancetype)init {
    self = [super init];
  
    if (self != nil) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        self.ssn = [defaults integerForKey:@"ssn"];
    }
    return self;
}

/*-----------------------------------------------------------------------------*/
/** @brief Get instance of the global variables data                           */
/*-----------------------------------------------------------------------------*/
+ (GlobalVariables *)getInstance
{
    static GlobalVariables *sharedInstance = nil;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        sharedInstance = [[GlobalVariables alloc] init];
    });
    
    return sharedInstance;
}

/*-----------------------------------------------------------------------------*/
/** @brief store a new value of the ssn                                        */
/*-----------------------------------------------------------------------------*/
+ (void)setBrainSsn:(NSInteger)ssn {
    [GlobalVariables getInstance].ssn = ssn;
}


/*-----------------------------------------------------------------------------*/
/** @brief save global variables                                               */
/*-----------------------------------------------------------------------------*/
+ (void)save {
    GlobalVariables *inst = [GlobalVariables getInstance];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    [defaults setInteger:inst.ssn forKey:@"ssn"];
    
    [defaults synchronize];
}

@end
