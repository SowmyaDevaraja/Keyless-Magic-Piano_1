#include "AirPianoConfig.h"
#include <string.h>
#include <UserButton.h>

#if (MOTETYPE==NODE)
module AirPianoC {
  uses {
    interface Boot;
    interface Leds;
    interface Timer<TMilli> as TimerAccel;
    interface Timer<TMilli> as TimerCalibrate;
    interface Read<uint16_t> as Xaxis;
    interface Read<uint16_t> as Yaxis;
    interface Read<uint16_t> as Zaxis;
    interface SplitControl as RadioControl;
    interface AMSend as RadioSendXYZ;
    interface Notify<button_state_t>;
  }
}

implementation {
//-------------------variables------------------------------------- 
	message_t pkt_temp;   
	int16_t Xval = 0;
	int16_t Yval = 0;
	int16_t Zval = 0;
	int16_t zerogx 	= DEFAULT_ZEROGX; 
	int16_t zerogz 	= DEFAULT_ZEROGZ; 
	int16_t ppgx 	= DEFAULT_PPGX; 
	int16_t ppgz 	= DEFAULT_PPGZ;
	int16_t xthreshold = (XSENSITIVITY * DEFAULT_PPGX)/10;
	int16_t zthreshold = (ZSENSITIVITY * DEFAULT_PPGZ)/10;
	//----variables needed for auto calibration----------------------
	int16_t p_1g_x 	= 0;//positive 1g value of x axis
	int16_t n_1g_x 	= 9999;//negative 1g value of x axis
	int16_t p_1g_z 	= 0;//positive 1g value of z axis
	int16_t n_1g_z 	= 9999;//negative 1g value of z axis
	uint8_t axis_calibrating = Z_AXIS_U;
	bool calibration = FALSE;
	bool calib_timeout = FALSE;

	uint16_t xmovement = STABLE;
	//uint16_t ymovement = STABLE;
	uint16_t zmovement = STABLE;

	uint8_t state = IDLE;
	uint16_t state_timeout_count = 0;
	uint8_t notedirection;
	uint8_t notetosend;


//-------------------------------------------------------- 
	event void Boot.booted() {
		call TimerAccel.startPeriodic(SAMPLINGPERIOD);
		call RadioControl.start();
		call Notify.enable();
	}
    
	event void TimerAccel.fired() {
		call Xaxis.read(); 
	}
  
	event void TimerCalibrate.fired() {		calib_timeout = TRUE;   	
	}
  
	event void Xaxis.readDone(error_t result, uint16_t data) {
		if (result == SUCCESS)
		{
			Xval = data;
			call Zaxis.read();
		}
	}
  
	event void Yaxis.readDone(error_t result, uint16_t data) {
		if (result == SUCCESS)
		{
			Yval = data;
			call Zaxis.read();
		}
	}
  
	task void sendMsg()
	{
		MyPayload *payload = (MyPayload*)call RadioSendXYZ.getPayload(&pkt_temp, sizeof(MyPayload)); 
		payload->nodeid = TOS_NODE_ID;
		payload->note = notetosend;
		call TimerAccel.stop();
		if (call RadioSendXYZ.send(AM_BROADCAST_ADDR, &pkt_temp, sizeof(MyPayload)) != SUCCESS) {
			post sendMsg();
		}
	}
  
	task void NoteCheck(){
		switch(state){
			case IDLE:
							if(zmovement==DOWN )
								state = ACCELERATEDOWN;
							else if(xmovement==RIGHT)
								state = ACCELERATERIGHT;
							//left note is not used for now
							//else if(xmovement==LEFT) 
							//	state = ACCELERATELEFT;
							break;	
			case ACCELERATEDOWN: 
							if(zmovement==UP){
								notedirection = NOTEDOWN;//notecopy(note, NOTEDOWN);	
								state = PRESSDOWN;	call Leds.led0On();
							}
							state_timeout_count++;	
							break;									 
			case ACCELERATERIGHT:
							if(xmovement==LEFT){
								notedirection = NOTERIGHT;		
								state = 	PRESSRIGHT;				
							}
							state_timeout_count++;
							break;
			case ACCELERATELEFT://never come to this state
							if(xmovement==RIGHT){
								notedirection = NOTELEFT;	
								state = PRESSLEFT;								
							}
							state_timeout_count++;	
							break;
			case PRESSDOWN: 
							if(zmovement==STABLE)
								state = IDLE;
							break;
			case PRESSRIGHT:
							if(xmovement==STABLE)
								state = IDLE;
							break;
			case PRESSLEFT:
							if(xmovement==STABLE)
								state = IDLE;
							break;										
		}
		
		if(notedirection != 0){
			notetosend = notedirection;
			notedirection = 0;
			post sendMsg();
		}
		
		if (state_timeout_count == 50){
			state_timeout_count = 0;
			state = IDLE;
		}		
	}
  
  
	task void MovementCheck(){
		Zval = Zval - zerogz - ppgz;
		Xval = Xval - zerogx;
	
  		if(Zval > zthreshold){
			zmovement = UP;
		}else if (Zval < -zthreshold){
			zmovement = DOWN;
		}else{
			zmovement = STABLE;			
		}
						
		if(Xval > xthreshold){
			xmovement = RIGHT;
		}else if (Xval < -xthreshold){
			xmovement = LEFT;
		}else{
			xmovement = STABLE;				
		}
		
		post NoteCheck();
	}
    
	task void Calibrate(){
		switch(axis_calibrating){	
			case 	Z_AXIS_U: //Z axis, Up
				if(p_1g_z < Zval)				
					p_1g_z = Zval;
				if(calib_timeout == TRUE){					   		
      			call Leds.led1On();					   		
      			call Leds.led2On();
					calib_timeout = FALSE;
					axis_calibrating = X_AXIS_U;
				}					
				break;
				
			case 	X_AXIS_U: //X axis, Up
				if(p_1g_x < Xval)				
					p_1g_x = Xval;
				if(calib_timeout == TRUE){					   		
      			call Leds.led1Off();					   		
      			call Leds.led2Off();
					calib_timeout = FALSE;
					axis_calibrating = Z_AXIS_D;
				}								
				break;	
				
			case 	Z_AXIS_D: //Z axis, Down
				if(n_1g_z > Zval)				
					n_1g_z = Zval;
				if(calib_timeout == TRUE){					   		
      			call Leds.led1On();					   		
      			call Leds.led2On();
					calib_timeout = FALSE;
					axis_calibrating = X_AXIS_D;
				}	
				break;
				
			case 	X_AXIS_D: //X axis, Down
				if(n_1g_x > Xval)				
					n_1g_x = Xval;
				if(calib_timeout == TRUE){	
					calib_timeout = FALSE;				
					call TimerCalibrate.stop();
					//-----wrap up, should make a task but just do like this for now---
					call TimerAccel.stop();
					zerogx = (p_1g_x + n_1g_x)/2;
					ppgx = (p_1g_x - n_1g_x)/2;
					zerogz = (p_1g_z + n_1g_z)/2;
					ppgz = (p_1g_z - n_1g_z)/2;
					xthreshold = (XSENSITIVITY*ppgx)/10;
					zthreshold = (ZSENSITIVITY*ppgz)/10;														   		
					call Leds.led0Off();					   		
					call Leds.led1Off();
					call Leds.led2Off();
					calibration = FALSE;
					call TimerAccel.startPeriodic(SAMPLINGPERIOD);
				}					
				break;
			default:
				break;
		}  		
	} 
  
	event void Zaxis.readDone(error_t result, uint16_t data) {
		if (result == SUCCESS)
		{
			Zval = data;  
			if (calibration == TRUE)  
				post Calibrate();  
			else   
				post MovementCheck(); 
		} 
	}
  
 
	event void RadioSendXYZ.sendDone(message_t* msg, error_t error) 
	{    
		if (error == SUCCESS) 
		{
			call Leds.led2Toggle();
			call TimerAccel.startPeriodic(SAMPLINGPERIOD);
		}
		else
			post sendMsg();
	}
  
	event void RadioControl.startDone(error_t err) {
		//if radio starts, send message else restart it
		if (err == SUCCESS){
		}	
		else 
			call RadioControl.start();
	}

	event void RadioControl.stopDone(error_t err) 
	{
		//if radio doesn't turn off try stopping it again
		if (err != SUCCESS)		
		call RadioControl.stop();
	}

	
	event void Notify.notify( button_state_t buttonstate ) {		
    	if (buttonstate == BUTTON_PRESSED && calibration == FALSE){
    		p_1g_x 	= 0;//just to make sure
  			n_1g_x 	= 9999;
 			p_1g_z 	= 0;
  			n_1g_z 	= 9999;
			axis_calibrating = Z_AXIS_U;
			calibration = TRUE;      		
			call Leds.led0On();     		
			call Leds.led1Off();     		
			call Leds.led2Off();    
			call TimerCalibrate.startPeriodic(CALIBRATINGPERIOD);	
		}
  	}
}


//-------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------
// CODE for STATION
//-------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------
#elif (MOTETYPE==STATION)
module AirPianoC {
	uses {
		interface Boot;
		interface Leds;
		//interface Timer<TMilli> as TimerSend;
		interface SplitControl as RadioControl;
		interface SplitControl as SerialControl;
		interface AMSend as SerialSend;
		interface Receive;
	}
}

implementation {
	//variables
	uint16_t id;
	uint8_t notedirection;
	bool busy = FALSE;
	message_t pkt_data;
	
	
	event void Boot.booted() {
    	call RadioControl.start();
    	call SerialControl.start();
	}
  
	event void RadioControl.startDone(error_t err) {
		if (err == SUCCESS) {
		}	
		else 
			call RadioControl.start();
	}

	event void RadioControl.stopDone(error_t err) 
	{
		if (err != SUCCESS)		
		call RadioControl.stop();
	}
  
	event void SerialControl.startDone(error_t err) {
		if (err == SUCCESS) {
		}	
		else 
			call SerialControl.start();
	}

	event void SerialControl.stopDone(error_t err) 
	{
		if (err != SUCCESS)		
			call SerialControl.stop();
	}
  
  	task void SendMsgtoUart(){
    	if (!busy){ //not busy
    		MyPayload* btrpkt = (MyPayload*)(call SerialSend.getPayload(&pkt_data, NULL));
   		btrpkt->nodeid = id;
    		btrpkt->note = notedirection;
		   if (call SerialSend.send(AM_BROADCAST_ADDR, &pkt_data, sizeof(MyPayload)) == SUCCESS) {
				busy=TRUE;
   		}
    		else {
				post SendMsgtoUart(); // repost the task
    		}
    	}
	}
	
	event void SerialSend.sendDone(message_t* msg, error_t error) {
		if (&pkt_data == msg) {
			busy = FALSE;
    }
	} 
	event message_t *Receive.receive(message_t *msg, void *payload, uint8_t length) {
    	MyPayload* pkt = (MyPayload *)payload;
  		id = pkt->nodeid;
  		notedirection = pkt->note;
		call Leds.led2Toggle();
		post SendMsgtoUart();
  		return msg;
	}	
} 
#endif
