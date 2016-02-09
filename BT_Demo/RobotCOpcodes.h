/*-----------------------------------------------------------------------------*/
/*    RobotCOpcodes.h                                                          */
/*                                                                             */
/*    Created by James Pearman on 2/8/16.                                      */
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

#ifndef RobotCOpcodes_h
#define RobotCOpcodes_h

#define ROBOTC_HEADER                        { 0x00, 0x77, 0x99, 0x33, 0x00 }

#define opEnumType (uint8_t)

typedef enum TVMOpcode
{
  opcdAlive               = opEnumType  0x10,
  opcdUsrMsgFunctions     = opEnumType  0xD0,
} TVMOpcode;

typedef enum TUsrMsgOpcodeFunctions
{
  usgMsgFcn_RecieveUserMsg = 0x10,
  usgMsgFcn_RequestUsrMsg,
} TUsrMsgOpcodeFunctions;

#endif /* RobotCOpcodes_h */
