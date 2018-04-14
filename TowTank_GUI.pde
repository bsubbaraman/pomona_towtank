/*
GUI for Pomona College Tow Tank.  Built with controlP5 and graficas, serial communication with arduino.
 Written by Blair Subbaraman '18
 */

import controlP5.*; //GUI library
import processing.serial.*;
import grafica.*; //for plots
import java.util.*;


ControlP5 cp5;
Serial port;
//all of velocities and change cues inputted
float velocityInput, velocityInput2, velocityInput3, velocityInput4, velocityInput5;
float v_change2, v_change3, v_change4, v_change5;
float sizeRe; //size of object being towed
int direction; //1 = forwards, 0 = backwards
float slidernum = 1; //number of velocites, changed by slider on gui
int v_Re = 1; //variable for radiobutton selection. 1=v, 2=re
int v_Re_change = 1; //detect changes so we don't send a Re instead of v by accident
int time_distance = 1;
int time_distance_change = 1; //similarly for time vs distance
//these are the raw distances entered when changing speed after a specific distance.  used to convert to a time, which is sent to arduino
float rawdistance_2 =0; 
float rawdistance_3 =0;
float rawdistance_4 =0;
float rawdistance_5 =0;

//for plot of data:
int velocityData; //data being passed by arduino over serial.  right now, this is actually distance data, not velocity data
GPointsArray points; 
GPlot plot;
int added_a_point = 0; //for clearing plot
int nPoints;
float startTime = 0;

//int x = 0; pretty confident i can take out

Textarea datatable; //take out?

Table table; //write to a csv of distance over time. this can be used to see at what point the changing velocities become constant
//boolean serial_connection = false; //testing for finding active serial port

void setup() {
  //testing for finding active serial point
  //for (int i=0; i<Serial.list().length; i++) {
  //  char handShake = 'o';
  //  port = new Serial(this, Serial.list()[i], 115200);
  //  port.clear();

  //  millisStart = millis();
  //  while(millis() - millisStart < 2000) {
  //    if (port.available()>0) {
  //      handShake = port.readChar();
  //      println(handShake);
  //    }
  //    if(handShake=='s'){
  //      println(Serial.list()[i]);
  //      port.write('s');
  //      thePort = Serial.list()[i];
  //      break;
  //    }
  //    else{
  //      port.stop();
  //    }

  //  }
  //}
  cp5 = new ControlP5(this); //initialize use of library
  port = new Serial(this, "/dev/cu.usbmodem1411", 115200);  //this serial port needs to match the one that the arduino is connected to
  //Fonts:
  PFont pfont = createFont("Avenir-Medium", 14, true); //Change the font. true=smoothing
  ControlFont font = new ControlFont(pfont, 14);
  Label.setUpperCaseDefault(false); //this library's text is all upper case by default- turning this off
  
  fullScreen();
  smooth(); //makes drawn objects less blurry
  table = new Table(); //for writing to a csv of distance data
  table.addColumn("Time");
  table.addColumn("Distance (cm)");
  
  //sets up all of the controllers on our gui (size, color, etc)
  cp5.getTab("default")
    .setCaptionLabel("home")
    .setColorBackground(color(#2A4D6D))
    .setColorActive(color(#8CBA80))
    ;
    
  cp5.addTab("info") //an extra tab for info
    .setColorBackground(color(#2A4D6D))
    .setColorActive(color(#8CBA80))
    ;
    
  RadioButton r1 = cp5.addRadioButton("r1")
    .setPosition(width/8, height/7)
    .setSize(40, 20)
    .setColorBackground(color(#2A4D6D))
    .setColorForeground(color(120))
    .setColorLabel(color(255))
    .setItemsPerRow(2)
    .setSpacingColumn(50)
    .addItem("VELOCITY", 1)
    .setColorActive(color(#8CBA80))
    .addItem("RE", 2)
    .activate(0)
    ;
    
  RadioButton r2 = cp5.addRadioButton("r2")
    .setPosition(width/8 + 210, height/7)
    .setSize(40, 20)
    .setColorForeground(color(120))
    .setColorBackground(color(#2A4D6D))
    .setColorLabel(color(255))
    .setItemsPerRow(2)
    .setSpacingColumn(50)
    .setFont(font)
    .addItem("TIME", 1)
    .addItem("DISTANCE", 2)
    .activate(0)
    .setColorActive(color(#8CBA80))
    .setVisible(false) //we only want to see this if the number of velocities is >1
    ;
    
  cp5.addSlider("slider")
    .setBroadcast(false) //don't broadcast during setup, or else we'll get errors
    .setPosition(60, height/2 - 125) 
    .setSize(20, 250)
    .setRange(1, 5)
    .setNumberOfTickMarks(5)
    .setSliderMode(Slider.FIX)
    .setFont(font)
    .setCaptionLabel("# of speeds")
    .setValue(1)
    .setBroadcast(true) //turn it back on
    .setColorBackground(color(#2A4D6D))
    .setColorForeground(color(#8CBA80))
    .setColorActive(color(#8CBA80))
    ;
  cp5.getController("slider").getCaptionLabel().align(ControlP5.CENTER, ControlP5.BOTTOM_OUTSIDE).setPaddingX(0); //changing the positioning of this label

  Numberbox size = cp5.addNumberbox("size")
    .setSize(150, 30)
    .setRange(0, 1)
    .setPosition(width/8+210, height/7 + 50)
    .setValue(0)
    .setMultiplier(0.1)
    .setColorBackground(color(#2A4D6D))
    .setColorForeground(color(#8CBA80))
    .setFont(font)
    .setCaptionLabel("SIZE OF OBJECT (m)")
    ;

  Numberbox v1 = cp5.addNumberbox("v1")
    .setSize(150, 30)
    //.setRange(0, 10000)
    .setPosition(width/8, height/7 + 50)
    .setValue(0)
    .setMultiplier(0.01)
    .setColorBackground(color(#2A4D6D))
    .setColorForeground(color(#8CBA80))
    .setFont(font)
    .setCaptionLabel("VELOCITY 1 (m/s)")
    ;

  Numberbox v2 = cp5.addNumberbox("v2")
    .setSize(150, 30)
    //.setRange(0, 100)
    .setPosition(width/8, 2*height/7 + 50)
    .setValue(0)
    .setFont(font)
    .setColorBackground(color(#2A4D6D))
    .setColorForeground(color(#8CBA80))
    .setCaptionLabel("VELOCITY 2 (m/s)")
    .setVisible(false) //only want to see these when number of velocities being set is >1
    ;
  Numberbox v3 = cp5.addNumberbox("v3")
    .setSize(150, 30)
    //.setRange(0, 100)
    .setPosition(width/8, 3*height/7 + 50)
    .setValue(0)
    .setFont(font)
    .setColorBackground(color(#2A4D6D))
    .setColorForeground(color(#8CBA80))
    .setCaptionLabel("VELOCITY 3 (m/s)")
    .setVisible(false)
    ;

  Numberbox v4 = cp5.addNumberbox("v4")
    .setSize(150, 30)
    //.setRange(0, 100)
    .setPosition(width/8, 4*height/7 + 50)
    .setValue(0)
    .setFont(font)
    .setColorBackground(color(#2A4D6D))
    .setColorForeground(color(#8CBA80))
    .setCaptionLabel("VELOCITY 4 (m/s)")
    .setVisible(false)
    ;
  Numberbox v5 = cp5.addNumberbox("v5")
    .setSize(150, 30)
    //.setRange(0, 100)
    .setPosition(width/8, 5*height/7 + 50)
    .setValue(0)
    .setFont(font)
    .setColorBackground(color(#2A4D6D))
    .setColorForeground(color(#8CBA80))
    .setCaptionLabel("VELOCITY 5 (m/s)")
    .setVisible(false)
    ;

  Numberbox v_change2 = cp5.addNumberbox("v_change2")
    .setSize(150, 30)
    .setRange(0, 4000)
    .setPosition(width/8 + 210, 2*height/7 + 50)
    .setValue(999)
    .setFont(font)
    .setColorBackground(color(#2A4D6D))
    .setColorForeground(color(#8CBA80))
    .setCaptionLabel("START AT (s)")
    .setVisible(false)
    ;
  Numberbox v_change3 = cp5.addNumberbox("v_change3")
    .setSize(150, 30)
    .setRange(0, 100)
    .setPosition(width/8 + 210, 3*height/7 + 50)
    .setValue(999)
    .setFont(font)
    .setColorBackground(color(#2A4D6D))
    .setColorForeground(color(#8CBA80))
    .setCaptionLabel("START AT (s)")
    .setVisible(false)
    ;
  Numberbox v_change4 = cp5.addNumberbox("v_change4")
    .setSize(150, 30)
    .setRange(0, 100)
    .setPosition(width/8 + 210, 4*height/7 + 50)
    .setValue(999)
    .setFont(font)
    .setColorBackground(color(#2A4D6D))
    .setColorForeground(color(#8CBA80))
    .setCaptionLabel("START AT (s)")
    .setVisible(false)
    ;
  Numberbox v_change5 = cp5.addNumberbox("v_change5")
    .setSize(150, 30)
    .setRange(0, 100)
    .setPosition(width/8 + 210, 5*height/7 + 50)
    .setValue(999)
    .setFont(font)
    .setColorBackground(color(#2A4D6D))
    .setColorForeground(color(#8CBA80))
    .setCaptionLabel("START AT (s)")
    .setVisible(false)
    ;

  //this calls a function (at bottom of sketch) that makes these numberboxes editable.  Taken from controlP5 editable numberbox example
  makeEditable(v1);     
  makeEditable(v2);
  makeEditable(v3);
  makeEditable(v4);
  makeEditable(v5);
  makeEditable(v_change2);
  makeEditable(v_change3);
  makeEditable(v_change4);
  makeEditable(v_change5);
  makeEditable(size);

  cp5.addButton("RUN")     
    .setPosition(3*width/4 - 50, height/3 + 15)
    .setSize(200, 114)      //(width, height)
    .setFont(font)
    .setColorBackground(color(#2A4D6D))
    ;

  cp5.addButton("front")     
    .setPosition((3*width/4) - 110, height/4)
    .setSize(150, 40)      //(width, height)
    .setColorBackground(color(#2A4D6D))
    .setCaptionLabel("BRING TO FRONT")
    .setFont(font)
    ;

  cp5.addButton("back")     
    .setPosition((3*width/4) + 50, height/4)
    .setSize(150, 40)      //(width, height)
    .setFont(font)
    .setColorBackground(color(#2A4D6D))
    .setCaptionLabel("TAKE TO BACK")
    ;


  cp5.addToggle("Direction")
    .setPosition(3*width/4 -5, height/7)
    .setSize(100, 40)
    .setValue(true) //true = forwards, false = reverse
    .setMode(ControlP5.SWITCH)
    .setFont(font)
    .setColorBackground(color(#2A4D6D))
    .setColorActive(color(#8CBA80))
    .setCaptionLabel("      F           R")
    ;
    
  //Setting up plot of distance data
  nPoints = 100;
  points = new GPointsArray(nPoints);  
  plot = new GPlot(this, 3*width/4 -190, height/2 + 50, 450, 287);
  plot.setTitleText("Tank Data");
  plot.getXAxis().setAxisLabelText("Time (s)");
  plot.getYAxis().setAxisLabelText("Distance (cm)");
  plot.setYLim(new float[] {0, 150});
}


void draw() {
  background(#041E37);
  //every loop, we check for new data sent over from arduino
  if (port.available()>0) {
    velocityData = port.read();
    if (startTime>0) { //only get data if we have started a run
      points.add(millis()-startTime, velocityData);
      TableRow newRow = table.addRow();
      added_a_point = millis(); //variable used to clear plot data (see below)
      newRow.setString("Time", str(millis()-startTime));
      newRow.setString("Distance (cm)", str(velocityData));
      saveTable(table, "data/new.csv");
    }
    plot.setPoints(points);
  }

  if (millis() - added_a_point >5000 && startTime>0) { //if the tank has stopped moving, we clear the plot so that we're ready for the next run
    for (int i = 0; i<points.getNPoints(); i++) {
      points.remove(i);
    }
  }
  plot.defaultDraw();
  
  //the following block is to display the reynolds number (if we are setting velocities) or the velocity (if we are setting reynolds numbers) 
  float num_speeds = cp5.getController("slider").getValue();
  PFont pfont = createFont("Avenir-Medium", 14, true);
  boolean on_home_screen = cp5.getTab("default").isActive();
  for (int i = 1; i<=num_speeds; i++) {
    textFont(pfont);
    if (on_home_screen) { //don't want to display if on info tab
      if (v_Re == 1) { //display calculated Reynolds #
        text("Re: " + String.format("%.2f", cp5.getController("size").getValue()*1000*cp5.getController("v"+Integer.toString(i)).getValue()/0.00089), width/2-20, height/7 - 42 + i*115);
      }
      if (v_Re ==2) { //display velocity
        text("u (m/s): " + String.format("%.4f", cp5.getController("v"+Integer.toString(i)).getValue()*0.00089/(1000*cp5.getController("size").getValue())), width/2-20, height/7 - 42 + i*115);
      }
    }
  }

  if (v_Re_change != v_Re) { //if we change between setting velocities or Reynolds numbers, we want to clear everything.
    v_Re_change = v_Re;
    velocityInput = 0;
    velocityInput2 = 0;
    velocityInput3 = 0;
    velocityInput4 = 0;
    velocityInput5 = 0;
    for (int i = 1; i<=slidernum; i++) {
      cp5.getController("v"+Integer.toString(i)).setValue(0);
    }
  }
  
  if (time_distance_change != time_distance) { //we similarly clear everything if we switch between sending times or distances to change speeds at
    v_change2 = 0;
    v_change3 = 0;
    v_change4 = 0;
    v_change5 = 0;
    time_distance_change = time_distance;
    slider(int(slidernum));
    for (int i = 2; i<=slidernum; i++) {
      cp5.getController("v_change"+Integer.toString(i)).setValue(0);
    }
  }
  //draw the graph if we're on the home screen
  plot.setPoints(points);
  if (on_home_screen) {
    plot.defaultDraw();
  }
}


// function that will be called when controller 'numbers' changes
public void v1 (float f) {
  if (v_Re == 1) {
    velocityInput = f; //if we're setting a velocity, the entered number is our velocity
  }
  if (v_Re == 2) {
    velocityInput = f*0.00089/(1000*cp5.getController("size").getValue()); //if we're setting a reynolds number, convert this to a velocity before sending
  }
}

public void v2 (float f) {
  if (v_Re == 1) {
    velocityInput2 = f;
  }
  if (v_Re == 2) {
    velocityInput2 = f*0.00089/(1000*cp5.getController("size").getValue());
  }
}

public void v3 (float f) {
  if (v_Re == 1) {
    velocityInput3 = f;
  }
  if (v_Re == 2) {
    velocityInput3 = f*0.00089/(1000*cp5.getController("size").getValue());
  }
}

public void v4 (float f) {
  if (v_Re == 1) {
    velocityInput4 = f;
  }
  if (v_Re == 2) {
    velocityInput4 = f*0.00089/(1000*cp5.getController("size").getValue());
  }
}

public void v5 (float f) {
  if (v_Re == 1) {
    velocityInput5 = f;
  }
  if (v_Re == 2) {
    velocityInput5 = f*0.00089/(1000*cp5.getController("size").getValue());
  }
}

public void v_change2 (float f) {
  if (time_distance ==1) {
    v_change2 = f/1000.0; 
  } else {
    if (time_distance == 2) {
      v_change2 = (f/velocityInput)/1000.0;
      rawdistance_2=f;
    } else {
      v_change2 = 999/1000.0;
    }
  }
}
public void v_change3 (float f) {
  if (time_distance ==1) {
    v_change3 = f/1000.0;
  } else {
    if (time_distance == 2 & slidernum>2) {
      rawdistance_3 = f;
      v_change3 = (f-rawdistance_2)/(1000*velocityInput2)+ v_change2;
    } else {
      v_change3 = 999/1000.0;
    }
  }
}
public void v_change4 (float f) {
  if (time_distance ==1) {
    v_change4 = f/1000.0;
  } else {
    if (time_distance == 2 & slidernum>3) {
      rawdistance_4=f;
      v_change4 = (f-rawdistance_3)/(1000*velocityInput3)+ v_change3;
    } else {
      v_change4 = 999/1000.0;
    }
  }
}
public void v_change5 (float f) {
  if (time_distance ==1) {
    v_change5 = f/1000.0;
  } else {
    if (time_distance == 2 & slidernum >4) {
      rawdistance_5 = f;
      v_change5 = (f-rawdistance_4)/(1000*velocityInput4)+ v_change4;
    } else {
      v_change5 = 999/1000.0;
    }
  }
}

void RUN() {
  startTime= millis(); //initialize timing for graph
  //'c' and 'k' correspond to the 'action' character in Arduino code
  if (direction == 1) { //corresponds to forwards
    port.write('c'); 
  }
  if (direction == 0) { //backwards
    port.write('k');
  }
  //when we hit run, we can send all of the data over to the arduino
  port.write(str(velocityInput));
  port.write(str(v_change2));
  port.write(str(velocityInput2));
  port.write(str(v_change3));
  port.write(str(velocityInput3));
  port.write(str(v_change4));
  port.write(str(velocityInput4));
  port.write(str(v_change5));
  port.write(str(velocityInput5));
}

void front() {
  port.write('f'); //action char for arduino
}

void back() {
  port.write('b');
}

public void size(float f) {
  sizeRe = f;
  //If we change the size and are setting by Re, then we need to recalculate the velocity by calling the velocity functions.
  if (v_Re ==2) {
    v1(cp5.getController("v1").getValue());  
    v2(cp5.getController("v2").getValue()); 
    v3(cp5.getController("v3").getValue()); 
    v4(cp5.getController("v4").getValue()); 
    v5(cp5.getController("v5").getValue());
  }
}

public void Direction(boolean b) {
  if (b) {
    direction = 1;
  }
  if (!b) {
    direction = 0;
  }
}

public void slider(int n) {
  //setting the slider number is going to dictate what is visible on our gui.  the following switch block handles these visuale
  slidernum = n;
  if (n>1) {
    cp5.getGroup("r2").setVisible(true);
  } else {
    cp5.getGroup("r2").setVisible(false);
  }

  switch (n) {
  case 1:
    for (int i=2; i<=5; i++) {
      cp5.getController("v"+Integer.toString(i)).setVisible(false);
      cp5.getController("v_change"+Integer.toString(i)).setVisible(false);
      cp5.getController("v_change"+Integer.toString(i)).setValue(999);
    }
    break;

  case 2: 
    cp5.getController("v2").setVisible(true);
    cp5.getController("v_change2").setVisible(true);
    cp5.getController("v_change2").setValue(0);

    for (int i=3; i<=5; i++) {
      cp5.getController("v"+Integer.toString(i)).setVisible(false);
      cp5.getController("v_change"+Integer.toString(i)).setVisible(false);
      cp5.getController("v_change"+Integer.toString(i)).setValue(999);
    }
    break;
  case 3:
    for (int i=2; i<=3; i++) {
      cp5.getController("v"+Integer.toString(i)).setVisible(true);
      cp5.getController("v_change"+Integer.toString(i)).setVisible(true);
      cp5.getController("v_change"+Integer.toString(i)).setValue(0);
    }
    for (int i=4; i<=5; i++) {
      cp5.getController("v"+Integer.toString(i)).setVisible(false);
      cp5.getController("v_change"+Integer.toString(i)).setVisible(false);
      cp5.getController("v_change"+Integer.toString(i)).setValue(999);
    }
    break;
  case 4:
    for (int i=2; i<=4; i++) {
      cp5.getController("v"+Integer.toString(i)).setVisible(true);
      cp5.getController("v_change"+Integer.toString(i)).setVisible(true);
      cp5.getController("v_change"+Integer.toString(i)).setValue(0);
    }
    cp5.getController("v5").setVisible(false);
    cp5.getController("v_change5").setVisible(false);
    cp5.getController("v_change5").setValue(999);
    break;
  case 5:
    for (int i=2; i<=5; i++) {
      cp5.getController("v"+Integer.toString(i)).setVisible(true);
      cp5.getController("v_change"+Integer.toString(i)).setVisible(true);
      cp5.getController("v_change"+Integer.toString(i)).setValue(0);
    }
    break;
  }
}

public void r1(int j) {
  //change the caption labels if we're setting by velocity or Reynolds number
  v_Re = j;
  if (j==1) {
    for (int i=1; i<=5; i++) {
      cp5.getController("v"+Integer.toString(i)).setCaptionLabel("VELOCITY "+i+" (m/s)");
    }
  }
  if (j==2) {
    for (int i=1; i<=5; i++) {
      cp5.getController("v"+Integer.toString(i)).setCaptionLabel("RE "+i);
    }
  }
}

void r2(int j) {
  //change the caption labels if we're setting changes by time or length
  time_distance = j;
  if (j==1) {
    for (int i=2; i<=5; i++) {
      cp5.getController("v_change"+Integer.toString(i)).setCaptionLabel("START AT (s)");
    }
  }
  if (j==2) {
    for (int i=2; i<=5; i++) {
      cp5.getController("v_change"+Integer.toString(i)).setCaptionLabel("START AT (m)");
    }
  }
}

//the rest of the code is taken from the controlP5 editable numberbox example, used to make all of our input boxes editable
void makeEditable( Numberbox n ) {
  // allows the user to click a numberbox and type in a number which is confirmed with RETURN


  final NumberboxInput nin = new NumberboxInput( n ); // custom input handler for the numberbox

  // control the active-status of the input handler when releasing the mouse button inside 
  // the numberbox. deactivate input handler when mouse leaves.
  n.onClick(new CallbackListener() {
    public void controlEvent(CallbackEvent theEvent) {
      nin.setActive( true );
    }
  }
  ).onLeave(new CallbackListener() {
    public void controlEvent(CallbackEvent theEvent) {
      nin.setActive( false ); 
      nin.submit();
    }
  }
  );
}

// input handler for a Numberbox that allows the user to 
// key in numbers with the keyboard to change the value of the numberbox

public class NumberboxInput {

  String text = "";

  Numberbox n;

  boolean active;


  NumberboxInput(Numberbox theNumberbox) {
    n = theNumberbox;
    registerMethod("keyEvent", this );
  }

  public void keyEvent(KeyEvent k) {
    // only process key event if input is active 
    if (k.getAction()==KeyEvent.PRESS && active) {
      if (k.getKey()=='\n') { // confirm input with enter
        submit();
        return;
      } else if (k.getKeyCode()==BACKSPACE) { 
        text = text.isEmpty() ? "":text.substring(0, text.length()-1);
        //text = ""; // clear all text with backspace
      } else if (k.getKey()<255) {
        // check if the input is a valid (decimal) number
        final String regex = "\\d+([.]\\d{0,2})?";
        String s = text + k.getKey();
        if ( java.util.regex.Pattern.matches(regex, s ) ) {
          text += k.getKey();
        }
      }
      n.getValueLabel().setText(this.text);
    }
  }

  public void setActive(boolean b) {
    active = b;
    if (active) {
      n.getValueLabel().setText("");
      text = "";
    }
  }

  public void submit() {
    if (!text.isEmpty()) {
      n.setValue( float( text ) );
      text = "";
    } else {
      n.getValueLabel().setText(""+n.getValue());
    }
  }
}
