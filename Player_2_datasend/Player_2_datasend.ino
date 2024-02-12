#include <SPI.h>
#include <nRF24L01.h>
#include <RF24.h>
#include <Wire.h>
#include <Adafruit_Sensor.h>
#include <Adafruit_ADXL345_U.h>

RF24 radio(7, 8); // CE, CSN

int IRblockPIN = 2;       //Use Digital PIN 2
int IRblockStatus = LOW; //HIGH means no obstacle
bool IRbool = false;

Adafruit_ADXL345_Unified accel = Adafruit_ADXL345_Unified(12345);

const byte address[6] = "00001";

float x_acc = 0;
float y_acc = 0;
float z_acc = 0;

float x_acc_final = 0;
float y_acc_final = 0;
float z_acc_final = 0;

float filter_factor = 0.5;


void setup() 
{
  pinMode(IRblockPIN, INPUT);
  
  Serial.begin(9600);
  if(!accel.begin()) {
    /* There was a problem detecting the ADXL345 ... check your connections */
    Serial.println("Ooops, no ADXL345 detected ... Check your wiring!");
    while(1);
  }

  /*Sensor*/
  accel.setRange(ADXL345_RANGE_2_G);

  /* RADIO */
  radio.begin();
  radio.openWritingPipe(address);
  radio.setPALevel(RF24_PA_MAX);
  radio.stopListening();

}

void loop()
{
  IRblockStatus = digitalRead(IRblockPIN);

  sensors_event_t event; 
  accel.getEvent(&event);
    
  x_acc = event.acceleration.x;
  x_acc_final = (x_acc_final *(1-filter_factor)) + (x_acc * filter_factor);
    
  y_acc = event.acceleration.y;
  y_acc_final = (y_acc_final *(1-filter_factor)) + (y_acc * filter_factor);
    
  z_acc = event.acceleration.z;
  z_acc_final = (z_acc_final *(1-filter_factor)) + (z_acc * filter_factor);

  if (IRblockStatus == LOW) {
    IRbool = false;
  }
  else {
    IRbool = true;
  }
  String final_string = (String(x_acc_final)+","+String(y_acc_final)+","+String(z_acc_final)+","+String(IRbool));
  char charbuff[32];
  final_string.toCharArray(charbuff, 30);
  radio.write(&charbuff, sizeof(charbuff));
  Serial.println(final_string);

}
