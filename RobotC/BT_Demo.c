/*-----------------------------------------------------------------------------*/
/*                                                                             */
/*                         Copyright (c) Robomatter                            */
/*                                   2016                                      */
/*                            All Rights Reserved                              */
/*                                                                             */
/*-----------------------------------------------------------------------------*/
/*                                                                             */
/*    Module:     BT_Demo.c                                                    */
/*    Author:     James Pearman                                                */
/*    Created:    8 Feb 2016                                                   */
/*                                                                             */
/*                V1.00 8 Feb 2016  Initial release tested with V4.52          */
/*                                                                             */
/*-----------------------------------------------------------------------------*/
/*                                                                             */
/*    The author is supplying this software for use with the VEX IQ            */
/*    control system. This file can be freely distributed and teams are        */
/*    authorized to freely use this program , however, it is requested that    */
/*    improvements or additions be shared with the Vex community via the vex   */
/*    forum.  Please acknowledge the work of the authors when appropriate.     */
/*    Thanks.                                                                  */
/*                                                                             */
/*    Licensed under the Apache License, Version 2.0 (the "License");          */
/*    you may not use this file except in compliance with the License.         */
/*    You may obtain a copy of the License at                                  */
/*                                                                             */
/*      http://www.apache.org/licenses/LICENSE-2.0                             */
/*                                                                             */
/*    Unless required by applicable law or agreed to in writing, software      */
/*    distributed under the License is distributed on an "AS IS" BASIS,        */
/*    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. */
/*    See the License for the specific language governing permissions and      */
/*    limitations under the License.                                           */
/*                                                                             */
/*-----------------------------------------------------------------------------*/

// Check platform
#ifndef VexIQ
#error "This program is designed for the VexIQ platform"
#else

// Check if Smart Radio features are enabled
#ifndef VexIQ_SR
#error "This sample needs to have the smart radio features enabled"
#else

#define PORTNONE  ((tSensors)(-1))
tSensors        robotTouchSensor = PORTNONE;

/*-----------------------------------------------------------------------------*/
/*  Discover devices and look for a touch sensor                               */
/*-----------------------------------------------------------------------------*/
void
iqDiscoverDevices()
{
    TVexIQDeviceTypes   type;
    TDeviceStatus       status;
    short               ver;
    short               index;

    // Get all device info
    for(index=(short)PORT1;index<=(short)PORT12;index++) {
        getVexIqDeviceInfo( index, type, status, ver );

        // Touch LED on any port used to start stop robot
        if( type == vexIQ_SensorLED )
            robotTouchSensor = (tSensors)index;
    }
}

/*-----------------------------------------------------------------------------*/
/*  Setup message to remote device if touch LED state changed                  */
/*-----------------------------------------------------------------------------*/
void
checkTouchSensor()
{
    static  int   oldValue = -1;
    static  char  msg[41];

    // If Touch LED installed
    if(robotTouchSensor)
        {
        int value = SensorValue[ robotTouchSensor ];

        if(  value != oldValue )
            {
            msg[0] = 0x80;
            msg[1] = value;
            oldValue = value;

            // User message to remote device
            sendUserMessage(msg);
            }
        }
}

/*-----------------------------------------------------------------------------*/
/*  Check if we received a user message from the bluetooth device              */
/*-----------------------------------------------------------------------------*/
void
checkForUserMessage()
{
    char usrMsg[41]; //extra byte for null char

    if(userMessageAvailable())
        {
        // Get the incomming message
        readUserMessage(usrMsg);

        // The demo preceeds commands with the string "usr"
        if( usrMsg[0] == 'u' && usrMsg[1] == 's' && usrMsg[2] == 'r' )
            {
            // We have a message, see if the touch LED is found
            if(robotTouchSensor)
                {
                switch( usrMsg[3] )
                  {
                  case  1:  setTouchLEDColor( robotTouchSensor, colorBlue );   displayString(1, "Blue  " ); break;
                  case  2:  setTouchLEDColor( robotTouchSensor, colorRed );    displayString(1, "Red   " );break;
                  case  3:  setTouchLEDColor( robotTouchSensor, colorGreen );  displayString(1, "Green " );break;
                  case  4:  setTouchLEDColor( robotTouchSensor, colorOrange ); displayString(1, "Orange" );break;
                  default:  setTouchLEDColor( robotTouchSensor, colorNone );   displayString(1, "      " );break;
                  }
                }
            }
        }
}

/*-----------------------------------------------------------------------------*/
task main()
{
    eraseDisplay();

    iqDiscoverDevices();

    // run forever looking for user messages
    while(true){
        checkForUserMessage();

        checkTouchSensor();
        wait1Msec(10);
    }
}

#endif // End Smart Radio features enabled check
#endif // End platform check
