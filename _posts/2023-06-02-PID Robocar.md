---
layout: post
title: PID 遙控小車
author: [賴建宇]
category: [Lecture]
tags: [jekyll, ai]
---
## Homework Report Format
**PID 遙控小車**<br>
* **應用與功能說明**<br>
  - 自動修正路徑
  - 藍芽遠端操控
* **設計考量與所需相關技術**
  - 操作方式:透過藍芽連線操控自走小車
  - 移動方式:兩輪驅動
  - 供電方式:電池或電腦USB
  - 連線方式:WiFi或藍芽
  - 方位感測元件：MPU6050
  - 驅動裝置：DRV8833

* **系統方塊圖**<br>

![](https://github.com/ouo0725/MCU-project/blob/main/images/1DF15DF4-2083-49D2-99F6-6B9E4A78B5DB.jpg?raw=true)

* **實作照片**<br>

![](https://github.com/ouo0725/MCU-project/blob/main/images/S__147996674.jpg?raw=true)
![](https://github.com/ouo0725/MCU-project/blob/main/images/S__147996676.jpg?raw=true)
![](https://github.com/ouo0725/MCU-project/blob/main/images/S__147996677.jpg?raw=true)

* **位置偵測**<br>

<iframe width="365" height="650" src="https://www.youtube.com/embed/4tvbFpI4C40" title="2023年6月4日" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" allowfullscreen></iframe>

* **實際操作**<br>

<iframe width="365" height="650" src="https://www.youtube.com/embed/9uHduNI7L98" title="2023年6月4日" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" allowfullscreen></iframe>

<iframe width="365" height="650" src="https://www.youtube.com/embed/b1AzkakRuUk" title="2023年6月4日" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" allowfullscreen></iframe>

<iframe width="365" height="650" src="https://www.youtube.com/embed/hAifEgHTZS8" title="2023年6月4日" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" allowfullscreen></iframe>

<iframe width="365" height="650" src="https://www.youtube.com/embed/_qStj0ZPaX8" title="我幹你娘張承翰，我在睡覺你在那邊吵" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" allowfullscreen></iframe>


* **程式碼**<br>

```
//
// RoboCar with MPU6050 using PID control for going straight line
// by Richard Kuo, NTOU/EE
//
#include <Wire.h>
#include <ESP32MotorControl.h> 
#include <MPU6050_6Axis_MotionApps20.h>

// MPU6050 : Inertial Measurement Unit
MPU6050 mpu;
//MPU6050 mpu(0x69); // <-- use for AD0 high

#define IN1pin 16  
#define IN2pin 17  
#define IN3pin 18 
#define IN4pin 19

#define motorR 0
#define motorL 1


ESP32MotorControl motor;
// MPU control/status vars
bool dmpReady = false;  // set true if DMP init was successful
uint8_t mpuIntStatus;   // holds actual interrupt status byte from MPU
uint8_t devStatus;      // return status after each device operation (0 = success, !0 = error)
uint16_t packetSize;    // expected DMP packet size (default is 42 bytes)
uint16_t fifoCount;     // count of all bytes currently in FIFO
uint8_t fifoBuffer[64]; // FIFO storage buffer

// orientation/motion vars
Quaternion q;           // [w, x, y, z]         quaternion container
VectorInt16 aa;         // [x, y, z]            accel sensor measurements
VectorInt16 aaReal;     // [x, y, z]            gravity-free accel sensor measurements
VectorInt16 aaWorld;    // [x, y, z]            world-frame accel sensor measurements
VectorFloat gravity;    // [x, y, z]            gravity vector
float euler[3];         // [psi, theta, phi]    Euler angle container
float ypr[3];           // [yaw, pitch, roll]   yaw/pitch/roll container and gravity vector

// packet structure for InvenSense teapot demo
uint8_t teapotPacket[14] = { '$', 0x02, 0,0, 0,0, 0,0, 0,0, 0x00, 0x00, '\r', '\n' };

static float  preHeading, Heading, HeadingTgt;

// PID tuning method : Ziegler-Nichols method
const int Ku = 10;
const int Tu = 100;
const int Kp = 0.6 * Ku;
const int Ki = 1.2 * Ku / Tu;
const int Kd = 3 * Ku * Tu /40;

// PWM freq : NodeMCU = 1KHz, UNO = 500Hz
// PWM duty   NodeMCU = 1023 (10-bit PWM), UNO = 255 (8-bit PWM)
#define PWM_FULLPOWER  1023
int USR_FullPower;
int USR_MotorPower;
int PID_FullPower;
int PID_MotorPower;

#define CMD_STOP     0
#define CMD_FORWARD  1
#define CMD_BACKWARD 2
#define CMD_RIGHT    3
#define CMD_LEFT     4
int command;
int angle;
    
// TB6612FNG : Full-Bridge DC Motor Driver
#define STBY D0
#define PWMA D3
#define AIN2 D4
#define AIN1 D5
#define BIN1 D6
#define BIN2 D7
#define PWMB D8

// value 1 or -1 for motor spining default
const int offsetA = 1;
const int offsetB = 1;


// Interrup Service Routine (ISR)
volatile bool mpuInterrupt = false;     // indicates whether MPU interrupt pin has gone high
void dmpDataReady() {
    mpuInterrupt = true;
}

void setup() {  
  Wire.begin();
  Wire.setClock(400000);
    
  Serial.begin(115200);
  Serial.println("NodeMCU RoboCar with IMU");
 motor.attachMotors(IN1pin, IN2pin, IN3pin, IN4pin);

   motor.motorStop(motorR);
  motor.motorStop(motorL);
  
  mpu.initialize();
  devStatus = mpu.dmpInitialize();
  
  // initialize device
  Serial.println(F("Initializing I2C devices...f="));
  mpu.initialize();

  // verify connection
  Serial.println(F("Testing device connections..."));
  Serial.println(mpu.testConnection() ? F("MPU6050 connection successful") : F("MPU6050 connection failed"));

  // wait for ready
  Serial.println(F("\nSend any character to begin DMP programming and demo: "));
  /*while (Serial.available() && Serial.read()); // empty buffer
  while (!Serial.available());                 // wait for data
  while (Serial.available() && Serial.read()); // empty buffer again*/

  // load and configure the DMP
  Serial.println(F("Initializing DMP..."));
  devStatus = mpu.dmpInitialize();

  // supply your own gyro offsets here, scaled for min sensitivity
  // Note - use the 'raw' program to get these.  
  // Expect an unreliable or long startup if you don't bother!!! 
  mpu.setXGyroOffset(220);
  mpu.setYGyroOffset(76);
  mpu.setZGyroOffset(-85);
  mpu.setZAccelOffset(1788);
    
  // make sure it worked (returns 0 if so)
  if (devStatus == 0) {
    // turn on the DMP, now that it's ready
    Serial.println(F("Enabling DMP..."));
    mpu.setDMPEnabled(true);

    // enable Arduino interrupt detection
    Serial.println(F("Enabling interrupt detection (Arduino external interrupt 0)..."));
    attachInterrupt(0, dmpDataReady, RISING);
    mpuIntStatus = mpu.getIntStatus();

    // set our DMP Ready flag so the main loop() function knows it's okay to use it
    Serial.println(F("DMP ready! Waiting for first interrupt..."));
    dmpReady = true;

    // get expected DMP packet size for later comparison
    packetSize = mpu.dmpGetFIFOPacketSize();
  } else {
    // ERROR!
    // 1 = initial memory load failed
    // 2 = DMP configuration updates failed
    // (if it's going to break, usually the code will be 1)
    Serial.print(F("DMP Initialization failed (code "));
    Serial.print(devStatus);
    Serial.println(F(")"));
  }

  //  read heading till it is stable
  for (int i=0;i<200;i++) {
      GetHeading(&Heading); 
      delay(100);
  }

  // set command & angle for moving RoboCar
  command = CMD_FORWARD; // CMD_RIGHT
  angle = 0;             // +60

  switch(command) {
    case CMD_STOP:
      USR_FullPower = 0;
      PID_FullPower = 0;
      break;    
    case CMD_FORWARD:
      USR_FullPower = PWM_FULLPOWER * 3/4;
      PID_FullPower = PWM_FULLPOWER - USR_FullPower;
      break;
    case CMD_BACKWARD:
      USR_FullPower = PWM_FULLPOWER * 3/4;
      PID_FullPower = PWM_FULLPOWER - USR_FullPower;
      break;
    case CMD_RIGHT:
      USR_FullPower = PWM_FULLPOWER * 1/4;
      PID_FullPower = PWM_FULLPOWER - USR_FullPower;
      break;
    case CMD_LEFT:
      USR_FullPower = PWM_FULLPOWER * 1/4;
      PID_FullPower = PWM_FULLPOWER - USR_FullPower;
      break;
    default:
      USR_FullPower = 0;
      PID_FullPower = 0;    
      break;
  }


  // set target heading to default heading
  GetHeading(&Heading); 
  HeadingTgt = Heading + angle;
  if (HeadingTgt>=360) HeadingTgt = HeadingTgt - 360;
  else if (HeadingTgt<0) HeadingTgt = HeadingTgt + 360;
  Serial.print("Heading Target = \t");
  Serial.println(HeadingTgt);
}

void loop() { 
  const int Moving = 1; 
  
  if (!dmpReady) return;

  // NOT USING MPU6050 INT pin
  // wait for MPU interrupt or extra packet(s) available
  //while (!mpuInterrupt && fifoCount < packetSize) {
  //} // 100Hz Fast Loop

  GetHeading(&Heading);
  Serial.print("Yaw:\t");
  Serial.print(Heading);
  Serial.print("\t");
  Serial.println(HeadingTgt);
  
  PID(Heading,HeadingTgt,&PID_MotorPower, Kp, Ki , Kd, Moving);

  USR_MotorPower = USR_FullPower; // assign User defined full power 
  Serial.print("Power:\t"); ;  
  Serial.print(USR_MotorPower);
  Serial.print("\t");   
  Serial.println(PID_MotorPower);
  
  if (Heading==HeadingTgt) PID_MotorPower = 0;
  switch (command) {
    case CMD_STOP:
      motor.motorForward(motorR,USR_MotorPower - PID_MotorPower);
      motor.motorForward(motorL,USR_MotorPower + PID_MotorPower);
      break;
    case CMD_FORWARD:
      motor.motorForward(motorR,USR_MotorPower - PID_MotorPower);
      motor.motorForward(motorL,USR_MotorPower + PID_MotorPower);
      break;
    case CMD_BACKWARD:
      motor.motorForward(motorR,-USR_MotorPower - PID_MotorPower);
      motor.motorForward(motorL,-USR_MotorPower + PID_MotorPower);
      break;
    case CMD_RIGHT:
      motor.motorForward(motorR, USR_MotorPower - PID_MotorPower);
      motor.motorForward(motorL,-USR_MotorPower + PID_MotorPower);
      break;
    case CMD_LEFT:
      motor.motorForward(motorR,-USR_MotorPower + PID_MotorPower);
      motor.motorForward(motorL, USR_MotorPower - PID_MotorPower);
      break;
    default:
      motor.motorForward(motorR,USR_FullPower - PID_MotorPower);
      motor.motorForward(motorL,USR_FullPower + PID_MotorPower);
      break;
  }
}

void  GetHeading(float *Heading)                                                                                                                                                   
{
  //calc heading from IMU
  // reset interrupt flag and get INT_STATUS byte
  mpuInterrupt = false;
  mpuIntStatus = mpu.getIntStatus();

  // get current FIFO count
  fifoCount = mpu.getFIFOCount();

  // check for overflow (this should never happen unless our code is too inefficient)
  if ((mpuIntStatus & 0x10) || fifoCount == 1024) {
    // reset so we can continue cleanly
    mpu.resetFIFO();
    Serial.println(F("FIFO overflow!"));

    // otherwise, check for DMP data ready interrupt (this should happen frequently)
  } 
  else if (mpuIntStatus & 0x02) 
  {
    // wait for correct available data length, should be a VERY short wait
    while (fifoCount < packetSize) fifoCount = mpu.getFIFOCount();

    // read a packet from FIFO
    mpu.getFIFOBytes(fifoBuffer, packetSize);
        
    // track FIFO count here in case there is > 1 packet available
    // (this lets us immediately read more without waiting for an interrupt)
    fifoCount -= packetSize;
          
    // display Euler angles in degrees
    mpu.dmpGetQuaternion(&q, fifoBuffer);
    mpu.dmpGetGravity(&gravity, &q);
    mpu.dmpGetYawPitchRoll(ypr, &q, &gravity);
    *Heading = int((ypr[0] * 180/M_PI)) + 180;    
  }//done
}//END GetHeading

void PID(float Heading,float HeadingTarget,int *Power, float kP,float kI,float kD, byte Moving)                                                 
{
  static unsigned long lastTime; 
  static float Output; 
  static float errSum, lastErr,error ; 

  // IF not moving then 
  if(!Moving)
  {
        errSum = 0;
        lastErr = 0;
        return;
  }

  //error correction for angular overlap
  error = Heading-HeadingTarget;
  if(error<180)
    error += 360;
  if(error>180)
    error -= 360;
      
  //http://brettbeauregard.com/blog/2011/04/improving-the-beginners-pid-introduction/

  /*How long since we last calculated*/
  unsigned long now = millis();    
  float timeChange = (float)(now - lastTime);       
  /*Compute all the working error variables*/
  //float error = Setpoint - Input;    
  errSum += (error * timeChange);   

  //integral windup guard
  LimitFloat(&errSum, -300, 300);

  float dErr = (error - lastErr) / timeChange;       

  /*Compute PID Output*/
  *Power = kP * error + kI * errSum + kD * dErr;
  /*Remember some variables for next time*/
  lastErr = error;    
  lastTime = now; 

  //limit demand 
  LimitInt(Power, - PID_FullPower,  PID_FullPower);

}//END getPID

void LimitInt(int *x,int Min, int Max)
{
  if(*x > Max)
    *x = Max;
  if(*x < Min)
    *x = Min;

}//END LimitInt

//
// Clamp a float between a min and max.  Note doubles are the same 
// as floats on this platform.

void LimitFloat(float *x,float Min, float Max)
{
  if(*x > Max)
    *x = Max;
  if(*x < Min)
    *x = Min;

}//END LimitInt
```
---
*This site was last updated {{ site.time | date: "%B %d, %Y" }}.*


