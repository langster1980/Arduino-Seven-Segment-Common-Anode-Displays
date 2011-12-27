/*
 
 Langster's New Code for driving Sparkfun Common Anode 4x seven segment displays via 2x 74HC595 Shift Registers
 and 4x BC548 Transistors...I have turned it into a clock just because I could!!
 
 This code is based on code I learnt and assimilated from lots of different sources:
 
 The following people can take some credit:
 
 Ladyada - Adafruit Industries
 Jon Boxall
 Everyone at Arduino.CC
 Sparkfun

*/

//External libraries for getting the current PC Time
//over the serial connection

#include <Wire.h>
#include "RTClib.h"

//Function for getting the current system time
RTC_Millis RTC;

//Count variables
int i=0;
int j=0;

// Pin connected to ST_CP (pin 12) of 74HC595
int latchPin = 8;

// Pin connected to SH_CP (pin 11 of 74HC595
int clockPin = 12;

// Pin connected to DS (pin 14) of 74HC595
int dataPin = 11;

/* initialise a four element array which turns the transistors on
   to control which segment is active */
   
int segmentSelect[4]= { 1,2,4,8 };  

/* Initialise a One Dimensional integer array with 
   the values for 0 - 9 on the Seven Segment LED Display */
   
int seven_seg_digits[10]={ 192,249,164,176,153,146,130,248,128,152 }; 
                             
/*
   
  without decimal point(s) 
  { dp,g,f,e,d,c,b,a },  
  { 1,1,0,0,0,0,0,0 },  // = 192 in decimal - common anode  

  { 1,1,1,1,1,0,0,1 },  // = 249 in decimal - common anode

  { 1,1,0,0,0,0,0,1 },  // = 164 in decimal - common anode
  
  { 1,0,1,1,0,0,0,0 },  // = 176 in decimal - common anode
  
  { 1,0,0,1,1,0,0,1 },  // = 153 in decimal - common anode
  
  { 1,0,0,1,0,0,1,0 },  // = 146 in decimal - common anode
  
  { 1,0,0,0,0,0,1,0 },  // = 130 in decimal - common anode
  
  { 1,1,1,1,1,0,0,0 },  // = 248 in decimal - common anode
  
  { 1,0,0,0,0,0,0,0 },  // = 128 in decimal - common anode
  
  { 0,1,1,0,0,0,0,1 },  // = 152 in decimal - common anode
  
//  Just for further reference here are the 
//  separate segment connections

  segment a = 14
  segment b = 16
  segment c = 13
  segment d = 3
  segment e = 5
  segment f = 11
  segment g = 15
  d.p. = 7 
  
*/

// constants won't change. Used here to 
// set pin numbers:

// Arduino Pin 9 is connected to the colon LED pin on the Seven Segment
const int colonPin =  9;      

// Variables will change:
int colonLedState = LOW;  // colonLedState used to set the LED
long previousMillis = 0;  // will store last time the Colon LED was updated

/*
The following variables is a long because the time, measured in miliseconds,
will quickly become a bigger number than can be stored in an int.
*/

long interval = 1000;     

//Integer variables to store the value(s) of the character that we wish to display on the Seven Segment

int firstDigit=0;
int secondDigit=0;
int thirdDigit=0;
int fourthDigit=0;

/*
Function to clear the seven segment display - In actual fact the program send the binary number zero the shift register output 
pins which are controlling the BC548 transistors.  By turning these off we cut the power to the segments.
*/

void clearDisplay() {
        
        /*   
        Take the latch pin of the shift register(s) low. shift zero serially into the shift register(s) which turns the transistors off
        and then take the latch pin of the shift register high to re-latch with the new 'zero' data
        */
        
        digitalWrite(latchPin, LOW);
        shiftOut(dataPin, clockPin, MSBFIRST, 0);
        shiftOut(dataPin, clockPin, MSBFIRST, 0);
        digitalWrite(latchPin, HIGH);   
}       

/*
Standard setup function which tells the compiler which pins are to be used for outputs and it also starts the serial listener
Very useful for debugging and in this case for setting the time!
*/

void setup() {
  
  // set the arduino pins to output so you 
  // can control the shift register(s)
  // and the colon LED segment
  
  pinMode(latchPin, OUTPUT);
  pinMode(clockPin, OUTPUT);
  pinMode(dataPin, OUTPUT);
  pinMode(colonPin, OUTPUT);  
  
  //Clear all the Display
  clearDisplay;
  
  //Turn on the serial Monitor - useful for debugging!
  Serial.begin(57600);
  Serial.println("Ready");  
  
  //Get the current system time via the serial port
  RTC.begin(DateTime(__DATE__, __TIME__));
} 

void loop() {
  
  // Call the display function
  displayNumber();        
        
}       

/*
 Using an interrupt constantly display characters on the display which are taken from the system clock
 Display these characters by rapidly sweeping from left to right and right to left to make it seem as 
 though the characters are constantly on....Persistence of vision technique
*/

void displayNumber() {
#define DISPLAY_BRIGHTNESS  1500

  long beginTime = millis();

  for(int digit = 4 ; digit > 0 ; digit--) {

    //Turn on a digit for a short amount of time
    switch(digit) {
    case 1:
      displayDigitOne();
      break;
    case 2:
      displayDigitTwo();
      break;
    case 3:
      displayDigitThree();
      break;
    case 4:
      displayDigitFour();
      break;
    }
    
    //Display this digit for a fraction of a second (between 1us and 5ms)
    delayMicroseconds(DISPLAY_BRIGHTNESS); 

    //Turn on all segments
    updateDisplay(); 

    //Turn off all digits
    clearDisplay();
  }
    
    //Wait for 20ms to pass before we paint the display again
    while( (millis() - beginTime) < 10) ; 
 
   unsigned long currentMillis = millis();
  
    if(currentMillis - previousMillis > interval) {
    
    // save the last time you blinked the Colon LED 
    previousMillis = currentMillis;   
    
    if (colonLedState == LOW)
      colonLedState = HIGH;
    else
      colonLedState = LOW;

    // set the colon LED with the State of the variable:
    digitalWrite(colonPin, colonLedState);
    
    }
}

/*
 Using the current PC time as a data source, set the segments to display the time
 by passing the current time as variables to the segments
*/

void updateDisplay() {
      
      DateTime now = RTC.now();
      firstDigit=now.hour()/10;
      secondDigit=now.hour()%10;
      thirdDigit=now.minute()/10;
      fourthDigit=(now.minute()%10);     
     
}

void displayDigitOne() {  
          
        //take the latch pin of the shift register(s) low and shift in 
        //the data for the required character, then turn the correct transistor 
        //for the first segment on which turns the segment on
        //then latch the shift register by taking the latch pin HIGH
        
        digitalWrite(latchPin, LOW);
        shiftOut(dataPin, clockPin, MSBFIRST, seven_seg_digits[firstDigit]);
        shiftOut(dataPin, clockPin, MSBFIRST, segmentSelect[0]);
        digitalWrite(latchPin, HIGH);   
  
}

void displayDigitTwo() {
  
        //take the latch pin of the shift register(s) low and shift in 
        //the data for the required character, then turn the correct transistor 
        //for the second segment on which turns the segment on
        //then latch the shift register by taking the latch pin HIGH
        
        digitalWrite(latchPin, LOW);
        shiftOut(dataPin, clockPin, MSBFIRST, seven_seg_digits[secondDigit]);
        shiftOut(dataPin, clockPin, MSBFIRST, segmentSelect[1]);
        digitalWrite(latchPin, HIGH);     

}

void displayDigitThree() {
  
        //take the latch pin of the shift register(s) low and shift in 
        //the data for the required character, then turn the correct transistor 
        //for the third segment on which turns the segment on
        //then latch the shift register by taking the latch pin HIGH
        
        digitalWrite(latchPin, LOW);      
        shiftOut(dataPin, clockPin, MSBFIRST, seven_seg_digits[thirdDigit]);
        shiftOut(dataPin, clockPin, MSBFIRST, segmentSelect[2]);
        digitalWrite(latchPin, HIGH);
 
}

void displayDigitFour() {
      
        //take the latch pin of the shift register(s) low and shift in 
        //the data for the required character, then turn the correct transistor 
        //for the fourth segment on which turns the segment on
        //then latch the shift register by taking the latch pin HIGH
        
        digitalWrite(latchPin, LOW);
        shiftOut(dataPin, clockPin, MSBFIRST, seven_seg_digits[fourthDigit]);
        shiftOut(dataPin, clockPin, MSBFIRST, segmentSelect[3]);
        digitalWrite(latchPin, HIGH);
 
}

/* Simple function for setting the output via the serial monitor
Currently not being called in the main program - add it to the 
loop function of you wish to all it.
*/

void updateSegmentValueSerial(){
if (Serial.available() > 0) {
	// read the incoming byte:
	j = Serial.read();
	// say what you got:
	Serial.print("Serial Data received: ");
	Serial.println(j);
        
              if (j == '0' || j == '0')
              
              {
                i=0;
              }   
              else if (j == '1' || j == '!')
              {
                i=1; 
              }
              else if (j == '2' || j == '@')
              {
                i=2;
              }
              else if (j == '3' || j == '#')
              {
                i=3;
              }
              else if (j == '4' || j == '$')
              {
                i=4;
              }
              else if (j == '5' || j == '%')
              {
                i=5;
              }
              else if (j == '6' || j == '^')
              {
                i=6;
              }
              else if (j == '7' || j == '&')
              {
                i=7;
              }
              else if (j == '8' || j == '*')
              {
                i=8;
              }
              else if (j == '9' || j == '(')
              {
                i=9;
              }
      }               
}

