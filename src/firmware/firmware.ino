#include "MePort.h"
#include "MeDCMotor.h"
#include "MeUltrasonic.h"
#include "MeRGBLed.h"
#include "MePort.h"
#include "Stepper.h"


char a[53]={1,2,3,1,0,0,1,2,3,1,0,0,0,3,4,5,0,0,3,4,5,0,0,5,6,5,4,3,0,1,0,0,0,0,5,6,5,4,3,0,1,0,0,0,3,5,1,0,0,0,3,5,1};
int num=53;
//上面数组是音乐乐谱，也可以自己编曲

int dirPin = mePort[PORT_1].s1;//步进电机驱动接1口
int stpPin = mePort[PORT_1].s2;//步进电机驱动接1口
Stepper stepper(Stepper::DRIVER,stpPin,dirPin); 
MeUltrasonic ultraSensor(PORT_3);//超声波模块接3口
MeDCMotor kicker(M1);        //电磁铁接M1口
MeRGBLed led(PORT_6,SLOT_2);//ＬＥＤ灯条接转接模块的Ｊ４处
MePort sw(PORT_6,SLOT_1);//限位开关接转接模块的Ｊ５处，转接模块接主控板的８口

int targetIndex = -1;
int currentIndex = -1;
int value;
long startPosition = 0;
char mode=1;
unsigned int knockFlag = false;
unsigned int onestep = 79;
int prevIndex=0;
int lastNum = 0;

void setup()
{
  Serial.begin(9600);
  initStepper();
  pinMode(7,OUTPUT);
  pinMode(6,OUTPUT);
  digitalWrite(7,HIGH);
  analogWrite(6,0);
  pinMode(6,INPUT);
  led.setNumber(15);
  indicators(15,0,0,0);
  led.show();
  indicators(1,100,0,0);  
  led.show();
  kickoff();
  delay(3000);
  music();
}

int ledFlag = true;

void loop()
{
   if(mode) ultra_control(); //检测超声波 
   upper_computer();         //检测上位机
   checkStepperPosition();  
   delay(50);
}

void upper_computer()
{
  if(Serial.available())
 {
     char temp = Serial.read();
     if(temp=='M')   //开启超声波，上电默认开启模式
     {
       mode=1;
       Serial.read();
       return;
     }
     if(temp=='N')   //关闭超声波
     {
       mode=0; 
       Serial.read();       
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
  startPosition=0;
  stepper.run();
  stepper.moveTo(29);
  while(stepper.currentPosition()!=29) 
  {
    stepper.run();
  }
  stepper.stop(); 
  stepper.setMaxSpeed(20000);
  stepper.setAcceleration(10000);
  stepper.setCurrentPosition(79);
  stepper.run();
}


void music()
{
  int i=0;
  for(int i;i<num;i++)
  {
     targetIndex=(a[i]);
     if (targetIndex==0)
     delay(200);
     else
     {
       moveStepper(1);
       kickoff(); 
     }
   }
}

void kickoff()
{
  knockFlag = false; 
  pinMode(6,OUTPUT);
  analogWrite(6,100);
  delay(50);
  analogWrite(6,0);
  pinMode(6,INPUT);
}

void moveStepper(char x)
{
  if(targetIndex>=0)
  {
    int stepPos = startPosition+targetIndex*onestep; 
    stepper.moveTo(stepPos);
    while(stepper.run());
    int r=random(1,200);
    int b=random(1,200);
    int g=random(1,200);
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
      if(value <10)
      {
        targetIndex = 1;
      }
      else if(value <20)
      {
        targetIndex = 2;
      }
      else if(value <30)
      {
        targetIndex = 3;
      }
      else if(value <40)
      {
        targetIndex = 4;
      }
      else if(value <50)
      {
        targetIndex = 5;
      }
      else if(value <60)
      {
        targetIndex = 6;
      }
      else if(value <70)
      {
        targetIndex = 7;
      }
      else
      { 
        targetIndex = 16;
      }
      if(targetIndex!=prevIndex)
      {
       if(targetIndex<16)
       {
         knockFlag = true;
         moveStepper(2);
       }
       prevIndex = targetIndex; 
      }
    } 
}



void indicators(byte count,byte r,byte g,byte b)
{
  byte inSpeed = 1;
  for(int x = count; x <= 15; x++)
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
