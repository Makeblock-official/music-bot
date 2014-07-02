#include "MePort.h"
#include "MeDCMotor.h"
#include "MeUltrasonic.h"
#include "MeRGBLed.h"
#include "MePort.h"
#include "Stepper.h"

char music_score[]="1231012310345034500056543010056543010030510003051";

int dirPin = mePort[PORT_1].s1;
int stpPin = mePort[PORT_1].s2;
Stepper stepper(Stepper::DRIVER,stpPin,dirPin); 
MeUltrasonic ultraSensor(PORT_3);
MeRGBLed led(PORT_6,SLOT_2);
MePort sw(PORT_6,SLOT_1);
MeDCMotor kicker(M1);

char mode=0;
int value;
int prevIndex=0;
int ledFlag = true;
int targetIndex = -1;
int currentIndex = -1;
unsigned int onestep = 80;
unsigned int knockFlag = false;

void setup()
{
  led.setNumber(15);
  indicators(15,0,0,0);
  led.show();  
  initStepper();  
  pinMode(7,OUTPUT);
  pinMode(6,OUTPUT);
  digitalWrite(7,HIGH);
  analogWrite(6,0);
  pinMode(6,INPUT);
  indicators(1,100,0,0);  
  led.show();
  kickoff();
  delay(3000);
  music();
  Serial.begin(9600);  
}


void loop()
{
   if(mode) ultra_control();  
   upper_computer();         
   checkStepperPosition();  
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
     if(temp< 0x12)
     {
       targetIndex = temp;
       knockFlag = true;
     }
     if(targetIndex!=prevIndex)
     {
       moveStepper(1);
       prevIndex = targetIndex;  
     }
  }  
}

void initStepper()
{
  stepper.setMaxSpeed(500);
  stepper.setAcceleration(10000);
  stepper.run(); 
  stepper.moveTo(-10000);
  while(sw.Dread1())  
  {
    if(!stepper.run()) break;
  }
  stepper.stop();
  delay(1000);  
  stepper.setCurrentPosition(0);
  stepper.run();
  stepper.moveTo(35);
  while(stepper.currentPosition()!=35) 
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
     if (targetIndex==0)
       delay(200);
     else
     {
       moveStepper(1);
       kickoff(); 
     }
     i++;
   }
}


void kickoff()
{
  knockFlag = false; 
  pinMode(6,OUTPUT);
  analogWrite(6,110);
  delay(60);
  analogWrite(6,0);
  pinMode(6,INPUT);
}


void moveStepper(char x)
{
  if(targetIndex>0 && targetIndex<16)
  {
    int stepPos = targetIndex*onestep; 
    stepper.moveTo(stepPos);
    while(stepper.run());
    int r=random(1,80);
    int b=random(1,80);
    int g=random(1,80);
    indicators(targetIndex*x,r,b,g);
    delay(50);
  }
}


void checkStepperPosition()
{
  int steptogo = abs(stepper.currentPosition()-stepper.targetPosition());
    if(steptogo==0 && knockFlag)
    {
      kickoff();
    }
}


void ultra_control()
{
    value = ultraSensor.distanceCm();
    if(value==0) return;
    if(value <70)
    {
      for(int i=1;i<=7;i++)
      {
        if(value<10*i) 
        {
          targetIndex = i;
          break;
        }
      }      
      if(targetIndex!=prevIndex)
      {
         knockFlag = true;
         moveStepper(2);
         prevIndex = targetIndex; 
      }
    }
}


void indicators(byte count,byte r,byte g,byte b)
{
  byte inSpeed = 1;
  for(int x=count;x<15;x++)
  {
      led.setColorAt(x,0,0,0);
      led.show();
      delay(inSpeed);
   }
  for(int x=0;x<count;x++)
  {
      led.setColorAt(x,r,g,b);
      led.show();
      delay(inSpeed);
   }
} 
