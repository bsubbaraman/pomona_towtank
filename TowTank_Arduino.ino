/*
 * Arduino Sketch to run the Pomona College Tow Tank 
 * 
 * Written by Blair Subbaraman '18
 */


#include <TimerOne.h> //accesses 16-bit timer to send larger range of pwm signals (0-1023 instead of 0-255)
//note that this means the 'analogWrite()' function cannot be used.

//read in each velocity from the GUI, and the time at which the
//velocity should change
float velocity, velocity2, velocity3, velocity4, velocity5;
float v_change2, v_change3, v_change4, v_change5;

//coordinating timing on GUI graph
long t_start;
boolean get_start_time = true;
long previous_time = 0;

//setting up distance sensor
const int trigPin = 12;
const int echoPin = 11;
long duration;
int distance;

//setup for tank parameters
char action; //tells arduino which button has been pressed on GUI
int pwmPin = 9; //pin that is driving the VFD via 0-20 mA current loop 
int relayPin = 6; //digital pin connected to relay. controls forwards/reverse. HIGH = forwards, LOW = reverse
boolean forwards = false;
boolean backwards = false;
boolean runTank = false;
boolean bringToFront = false;
boolean takeToBack = false;

//Defines front and back of tank based on distance measurements.
//change these if you wish to run the tank over a greater or smaller distance  
float tank_length_front = 30; //cm
float tank_length_back = 120; //m

//Testing to find active Serial Port
boolean serial_connection = false;
char handShake;


void setup() {
  Serial.begin(115200);
  Timer1.initialize(1000); //have to initalize library before use.
  pinMode(pwmPin, OUTPUT);
  Timer1.pwm(pwmPin, 0); 
  pinMode(trigPin, OUTPUT); // Sets the trigPin as an Output
  pinMode(echoPin, INPUT); // Sets the echoPin as an Input
  pinMode(relayPin, OUTPUT);
  digitalWrite(relayPin, LOW);
}

void loop() {
  //Testing trying to find the active Serial port
//    while (!serial_connection) {
//      Serial.write('s');
//      if (Serial.available()) {
//        handShake = Serial.read();
//      }
//      if(handShake == 's'){
//        serial_connection = true;
//      }
//  
//    }

  if (Serial.available()) { //Look for a new 'action' being sent from GUI
    action = Serial.read();
  }

  if (action == 'c') { // c (clockwise) corresponds forwards in GUI code
    velocity = 0;
    runTank = true;
    bringToFront = false;
    takeToBack = false;
    forwards = true;
    backwards = false;
  }
  if (action == 'k') { // k (counterclockwise) corresponds to backwards in GUI code
    velocity = 0;
    runTank = true;
    bringToFront = false;
    takeToBack = false;
    backwards = true;
    forwards = false;
  }
  //While we are running the tank, look for all of the velocities and velocity change times being sent over Serial
  while (runTank) {
    if (Serial.available() > 0) {
      velocity = Serial.parseFloat();
    }
    if (Serial.available() > 0) {
      v_change2 = Serial.parseFloat() * 100;
    }
    if (Serial.available() > 0) {
      velocity2 = Serial.parseFloat();
    }
    if (Serial.available() > 0) {
      v_change3 = Serial.parseFloat() * 100;
    }
    if (Serial.available() > 0) {
      velocity3 = Serial.parseFloat();
    }
    if (Serial.available() > 0) {
      v_change4 = Serial.parseFloat() * 100;
    }
    if (Serial.available() > 0) {
      velocity4 = Serial.parseFloat();
    }
    if (Serial.available() > 0) {
      v_change5 = Serial.parseFloat() * 100;
    }
    if (Serial.available() > 0) {
      velocity5 = Serial.parseFloat();
    }

    if (forwards) {
      digitalWrite(relayPin, HIGH);
    }
    if (backwards) {
      digitalWrite(relayPin, LOW);
    }
    
    if (got_start_time) { //get start time to coordinate timing on GUI graph
      t_start = millis();
      get_start_time = false;
    }
    long current_time = millis();
    //Send distance data every second to plot 
    if (current_time - previous_time > 1000) {
      Serial.write(distanceFunction());
      previous_time = current_time;
    }

    //the conversion from velocity to pwm signal was experimentally determined to be v = .001*(pwm signal) -.216
    float pwm = (velocity + .216) / .001;
    if ((current_time - t_start) < (v_change2 * 10000)) {
      Timer1.pwm(pwmPin, pwm);
    }
    else if ((current_time - t_start) < (v_change3 * 10000)) {
      pwm = (velocity2 + .216) / .001;
      Timer1.pwm(pwmPin, pwm);
    }
    else if ((current_time - t_start) < (v_change4 * 10000)) {
      pwm = (velocity3 + .216) / .001;
      Timer1.pwm(pwmPin, pwm);
    }
    else if ((current_time - t_start) < (v_change5 * 10000)) {
      pwm = (velocity4 + .216) / .001;
      Timer1.pwm(pwmPin, pwm);
    }
    else if ((current_time - t_start) > (v_change5 * 10000)) {
      pwm = (velocity5 + .216) / .001;
      Timer1.pwm(pwmPin, pwm);
    }

    //Safety- stopping at start and end of tank.  define these bounds at top of sketch
    if ((distanceFunction() < tank_length_front && backwards) || (distanceFunction() > tank_length_back && forwards) ) {
      Timer1.pwm(pwmPin, 0);
      digitalWrite(relayPin, LOW);
      forwards = false;
      backwards = false;
      runTank = false;
      action = ""; //give an empty action char, so we start looking for a new one sent over serial
      get_start_time = true;
    }
  }



  if (action == 'f') { //corresponds to 'bring to front' button on GUI
    velocity = 0;
    bringToFront = true;
    runTank = false;
    takeToBack = false;
    backwards = true;
    forwards = false;

  }
  while (bringToFront) {
    digitalWrite(relayPin, LOW);
    while (distanceFunction() > tank_length_front) {
      Timer1.pwm(9, 250);
    }
    if (distanceFunction() < tank_length_front) {
      Timer1.pwm(9, 0);
      bringToFront = false;
      backwards = false;
      action = "";
    }
  }

  if (action == 'b') { //corresponds to 'take to back' on GUI
    velocity = 0;
    takeToBack = true;
    runTank = false;
    bringToFront = false;
    forwards = true;
    backwards = false;
  }
  while (takeToBack) {
    digitalWrite(relayPin, HIGH);
    while (distanceFunction() < tank_length_back) {
      Timer1.pwm(pwmPin, 250);
    }
    if (distanceFunction() > tank_length_back) {
      Timer1.pwm(pwmPin, 0);
      takeToBack = false;
      forwards = false;
      action = "";
    }
  }
}

int distanceFunction() { //function to get distance using range finder 
  // Clears the trigPin
  digitalWrite(trigPin, LOW);
  delayMicroseconds(2);
  // Sets the trigPin on HIGH state for 10 micro seconds
  digitalWrite(trigPin, HIGH);
  delayMicroseconds(10);
  digitalWrite(trigPin, LOW);
  // Reads the echoPin, returns the sound wave travel time in microseconds
  duration = pulseIn(echoPin, HIGH);
  // Calculating the distance
  distance = duration * 0.034 / 2;
  return distance;
}

