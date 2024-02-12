#include <Adafruit_SSD1306.h>
#include <Adafruit_GFX.h>

#include <SPI.h>
#include <nRF24L01.h>
#include <RF24.h>

#include <Wire.h>
#include <Adafruit_Sensor.h>
#include <Adafruit_ADXL345_U.h>

#define SCREEN_WIDTH 128 // OLED display width, in pixels
#define SCREEN_HEIGHT 64 // OLED display height, in pixels

// Declaration for an SSD1306 display connected to I2C
Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, 4);

String val; // Data received from the serial port
boolean recieved_score = true; // Checks if a point has already been given to a player
int P1Score = 0;
int P2Score = 0;

// Below are 3 game state variables in ASCII code, for interpreting data from Processing
int P1_CONST = 50;
int P2_CONST = 53;
int RESET_CONST = 56;

RF24 radio(7, 8); // CE, CSN

int IRblockPIN = 2;       //Use Digital PIN 2 for IR sensor
int IRblockStatus = LOW; //LOW means obstacle

Adafruit_ADXL345_Unified accel = Adafruit_ADXL345_Unified(12345); // to access accelerometer data


const byte address[6]="00001"; // information pipeline to recieve data from player 2

float x_acc = 0;
float y_acc = 0;
float z_acc = 0;

float x_acc_final = 0;
float y_acc_final = 0;
float z_acc_final = 0;

float filter_factor = 0.5; // 


void setup()
{
  pinMode(IRblockPIN, INPUT);
  
  Serial.begin(9600);
  if(!accel.begin())
  {
    // There was a problem detecting the ADXL345 ... check your connections
    Serial.println("Ooops, no ADXL345 detected ... Check your wiring!");
    while(1);
  }
  // There was a problem with the OLED display
  if(!display.begin(SSD1306_SWITCHCAPVCC, 0x3D)) { // Address 0x3D for 128x64
    Serial.println(F("SSD1306 allocation failed"));
    for(;;);
  }
  // Clears display buffer, initiates screen and sets text color
  display.clearDisplay(); 
  display.display();
  delay(2000);
  display.setTextColor(WHITE);
  

  // Selects accelerometer range
  accel.setRange(ADXL345_RANGE_2_G);

  // Initiates radio to start listening
  radio.begin();
  radio.openReadingPipe(1, address);
  radio.setPALevel(RF24_PA_MAX);
  radio.startListening();
}

void loop(){
  
  display.clearDisplay();
  
  if (Serial.available()){
     val = Serial.read(); // if information is available from Processing, save to val
      if (recieved_score == false){ // if no point has been given, check if a point is to be given
        
        if (String(val) == String(P1_CONST)){
          P1Score += 1;
          recieved_score = true; // makes sure only one point is given at a time
        }
      
        if (String(val) == String(P2_CONST)){
          P2Score += 1;
          recieved_score = true;
        }
       } else {
        if (String(val) == String(RESET_CONST)){
          recieved_score = false;
        }
      }
      if (String(val) == "1") { // if Processing says the game is over, reset score
        P1Score = 0;
        P2Score = 0;
     }
      
     drawScore(); // updates the OLED
    }
  
  IRblockStatus = digitalRead(IRblockPIN); // Checks if IR sensor detects obstacle or not, to pass onto Processing

  
  sensors_event_t event; 
  accel.getEvent(&event); // access accelerometer data

  // filters accelerometer values and prints them
  x_acc = event.acceleration.x;
  x_acc_final = (x_acc_final *(1-filter_factor)) + (x_acc * filter_factor);
  Serial.print(x_acc_final);
  Serial.print(',');
  y_acc = event.acceleration.y;
  y_acc_final = (y_acc_final *(1-filter_factor)) + (y_acc * filter_factor);
  Serial.print(y_acc_final);
  Serial.print(',');
  z_acc = event.acceleration.z;
  z_acc_final = (z_acc_final *(1-filter_factor)) + (z_acc * filter_factor);
  Serial.print(z_acc_final);
  Serial.print(',');

  // If obstacle, pass false, else pass true
  if (IRblockStatus == LOW)
  {
    Serial.print(false);
    Serial.print(",");
  }
  else
  {
    Serial.print(true);
    Serial.print(",");
  }

  // saves incoming transmission from player 2
  char text[32] = "";
  radio.read(&text, sizeof(text));

  // prints player 2 information
  if(String(text) != "")
  {
    Serial.println(text);
  } else {
    // in case of packet loss, print new line
    Serial.println();
  }
}

void drawScore() { // draws the player scores in an appropriate way
  display.clearDisplay();
  display.setTextSize(1);
  display.setCursor(10, 10);
  display.print("Player 1");

  display.setTextSize(2);
  display.setCursor(30, 30);
  display.print(P1Score);

  display.setTextSize(1);
  display.setCursor(70, 10);
  display.print("Player 2");

  display.setTextSize(2);
  display.setCursor(90, 30);
  display.print(P2Score);

  display.display();
}
