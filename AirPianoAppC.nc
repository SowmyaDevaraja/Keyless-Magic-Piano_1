#include "AirPianoConfig.h" 

configuration AirPianoAppC {
}

#if (MOTETYPE==NODE)
implementation {
  components MainC, AirPianoC as App;
  App.Boot -> MainC;
  
  components LedsC;
  App.Leds -> LedsC;

  components new TimerMilliC() as TimerAccel;
  App.TimerAccel -> TimerAccel;

  components new TimerMilliC() as TimerCalibrate;
  App.TimerCalibrate -> TimerCalibrate;

  components new Msp430ADC0C() as XSensor;
  App.Xaxis -> XSensor;

  components new Msp430ADC1C() as YSensor;
  App.Yaxis -> YSensor;

  components new Msp430ADC2C() as ZSensor;
  App.Zaxis -> ZSensor;
 
  components ActiveMessageC, new AMSenderC(0) as RadioSendXYZ;
  App.RadioControl -> ActiveMessageC;
  App.RadioSendXYZ -> RadioSendXYZ;
  
  components UserButtonC;
  App.Notify -> UserButtonC;
}

//---------------------------------------------------------------------------------------
// STATION
//---------------------------------------------------------------------------------------

#elif (MOTETYPE==STATION)
implementation {
  components MainC, AirPianoC as App;
  App.Boot -> MainC;
  
  components LedsC;
  App.Leds -> LedsC;
 
  components SerialActiveMessageC, ActiveMessageC,
  new SerialAMSenderC(100) as SerialSend,
  new AMReceiverC(0) as ReceiverRadio;
  
  App.RadioControl -> ActiveMessageC;
  App.SerialControl -> SerialActiveMessageC;
  App.SerialSend -> SerialSend;
  App.Receive -> ReceiverRadio;
}
#endif