/****************************************************************************** 
 *
 * Author:    		Luan Tran
 * Module Name:  	AirPianoConfig.h
 * Description:	Global definitions ...
 *						.........................
 * Date Created:	Oct.6.2016
 * Last Modify: 	Nov.30,2016
 *	Reason:			Add auto calibration
 *   
*******************************************************************************/ 

#ifndef AIRPIANOCONFIG_H
#define AIRPIANOCONFIG_H

//----------------------------------------------------
//----Definition for state machine--------------------
//----------------------------------------------------

//----States----
#define IDLE 10
#define ACCELERATEDOWN 21
#define ACCELERATERIGHT 22
#define ACCELERATELEFT 23
#define PRESSDOWN 31	
#define PRESSRIGHT 32	
#define PRESSLEFT 33	
#define CALIBRATION 40
//----Inputs----	
#define STABLE 0
#define UP 1
#define DOWN 2
#define LEFT 3
#define RIGHT 4	
#define FORWARD 5
#define BACKWARD 6

//----------------------------------------------------
//----Accelerometer Calibration-----------------------
//----------------------------------------------------
#define DEFAULT_ZEROGX 2479 
#define DEFAULT_ZEROGY 2505 
#define DEFAULT_ZEROGZ 2624
#define DEFAULT_PPGX 488 		//points per G
#define DEFAULT_PPGY 501 
#define DEFAULT_PPGZ 501

#define XSENSITIVITY 10
#define YSENSITIVITY 10
#define ZSENSITIVITY 10 //from 0-30 (0g 0.1g 0.2g ... 3g)

//calibrating state definitions
#define X_AXIS_U 10
#define X_AXIS_D 11
#define Y_AXIS_U 20
#define Y_AXIS_D 21
#define Z_AXIS_U 30
#define Z_AXIS_D 31

#define SAMPLINGPERIOD 10 //ms
#define CALIBRATINGPERIOD 3000 // 3 seconds each axis

//----------------------------------------------------
//----Music Notes Definitions-------------------------
//----------------------------------------------------
//should be the same definitions in java file
#define NOTEDOWN 	1
#define NOTERIGHT 	2
#define NOTELEFT 	3


//----------------------------------------------------
//----TELOSB buid definition--------------------------
//----------------------------------------------------
#define NODE 1
#define STATION 2
#define MOTETYPE NODE // STATION or NODE


//----data structure------------------------------------
typedef nx_struct MyPayload {
  nx_uint16_t nodeid;
  nx_uint8_t note;// note direction
} MyPayload;

#endif
