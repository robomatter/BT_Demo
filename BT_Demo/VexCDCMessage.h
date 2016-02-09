/*-----------------------------------------------------------------------------*/
/*    VexCDCMessage.h                                                          */
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

#ifndef _VexCDCMessage_h
#define _VexCDCMessage_h

#define CDC_HEADER                        { 0xC9, 0x36, 0xB8, 0x47, 0x00 }

#define CDC_QUERY1                        0x21

#define CMD_DOWNLOAD_USER_PROG            0x60
#define CDC_READ_PRGREC                   0x61    //Read Program Info (catalog)
#define CDC_ERASE_FLASH                   0x63
#define CDC_WRITE_FLASH                   0x64
#define CDC_READ_FLASH                    0x65
#define CDC_EXIT_DOWNLOAD                 0x66
#define CDC_PLAY_PROGRAM                  0x67
#define CDC_STOP_PROGRAM                  0x68
#define CMD_GET_COMPONENTS                0x69    //port status

#define CDC_WRITE_FIFO_BUFR               0x7A    //Write data to user program

#define CDC_REPLY_HEADER1                 0xAA
#define CDC_REPLY_HEADER2                 0x55
#define CDC_GEN_ACK                       0x33
#define CDC_GEN_ACK_CMDLEN                5
#define CDC_RESPONSE_ACK                  0x76
#define CDC_RESPONSE_NACK                 0xFF

// pulled from vexpython - to be checked
// Brain status bits
#define CDC_BRAIN_STATUS_RADIO            0x01
#define CDC_BRAIN_STATUS_LINKED           0x02
#define CDC_BRAIN_STATUS_JOYSTICK         0x04
#define CDC_BRAIN_STATUS_FATAL_MOTOR_ERR  0x80

// Component status bits
#define CDC_COMPONENT_STATUS_PRESENT      0x01
#define CDC_COMPONENT_STATUS_BUSY         0x02
#define CDC_COMPONENT_STATUS_MASTER       0x20
#define CDC_COMPONENT_STATUS_FW_UPDATE    0x40
#define CDC_COMPONENT_STATUS_ERR          0x80

#endif
