#include "MePort.h"
#include "MeDCMotor.h"
#include "MeUltrasonic.h"
#include "MeRGBLed.h"
#include "MePort.h"
#include "Stepper.h"

char music_score[]="89:8089:80:;<0:;<000<=<;:0800<=<;:08009050800090508";
int dirPin = mePort[PORT_1].s1;
int stpPin = mePort[PORT_1].s2;
int sw     = mePort[PORT_6].s2;
Stepper stepper(Stepper::DRIVER,stpPin,dirPin); 
MeUltrasonic ultraSensor(PORT_3);
MeRGBLed led(PORT_6,SLOT_1);
MeDCMotor kicker(M1);

char mode=0;
int targetIndex = 0;
int currentIndex = 0;
int onestep = 80;

void setup()
{
  Serial.begin(115200);  
  led.setNumber(15);
  indicators(15,0,0,0);
  led.show();  
  initStepper(); 
  indicators(1,100,0,0);  
  led.show();
  kickoff();
  delay(5000);
  music();
}


void loop()
{
   if(mode) ultra_control();  
   upper_computer();  
   delay(50);
}


void upper_computer()
{
  if(Serial.available())
 {
     char temp = Serial.read();
     if(temp=='M')   
     {
       mode=1;
       return;
     }
     if(temp=='N')  
     {
       mode=0;      
       return;
     }
     if(temp>0 && temp<16)
     {
      targetIndex = 16- temp;
      moveStepper();
     }
  }  
}

void initStepper()
{
  stepper.setMaxSpeed(500);
  stepper.setAcceleration(15000); 
  stepper.setCurrentPosition(0);  
  stepper.run(); 
  pinMode (sw,INPUT_PULLUP);
  delay(500);  
  stepper.moveTo(-10000);
  while(1)  
  {
    if(!stepper.run() || !digitalRead(sw)) 
    {
        delay(100);
        if(!stepper.run() || !digitalRead(sw))
       break; 
    }
    stepper.run();
  }
  delay(2000);  
  stepper.setCurrentPosition(0);
  stepper.run();
  stepper.moveTo(40);
  while(stepper.currentPosition()!=40) 
  {
    stepper.run();
  }
  stepper.stop(); 
  stepper.setMaxSpeed(10000);
  stepper.setAcceleration(10000);
  stepper.setCurrentPosition(80);
  stepper.run();
}

void music()
{
  char i=0;
  while(music_score[i]!='\0')
  {
     targetIndex=(music_score[i]-48);
     targetIndex=16-targetIndex; 
     if (targetIndex==16) delay(200);
     else  moveStepper();
     i++;
  }
}


void kickoff()
{
  kicker.run(115);
  delay(55);
  kicker.stop();
}

void moveStepper()  
{
  if(targetIndex>0 && targetIndex<16)
  {  
    int stepPos = targetIndex*onestep; 
    stepper.moveTo(stepPos);
    while(stepper.run());
    int r=random(1,50);
    int b=random(1,50);
    int g=random(1,50);
    indicators(targetIndex,r,b,g);
    currentIndex = targetIndex;
    kickoff();
  }
}

void ultra_control()
{ 
    int value=0;
    value = ultraSensor.distanceCm();
    if(value==0) return;
    if(value <70)
    {
      targetIndex=value/10+9;     
      if(targetIndex!=currentIndex)
      {
         moveStepper(); 
      }
    }
}

void indicators(int count,byte r,byte g,byte b)
{
  for(int x=count;x<15;x++)
  {
      led.setColorAt(x,0,0,0);
  }
  led.show();
  for(int x=0;x<count;x++)
  {
      led.setColorAt(x,r,g,b);
  }
  led.show();   
} 
