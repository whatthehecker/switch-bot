#include <Arduino.h>
#include <SwitchJoystick.h>
#include "button_constants.h"
#include "command_constants.h"

#define Backend Serial1
#define Switch Serial

SwitchJoystick_ joystick;

#define STATUS_LED_PIN 9

void set_left_stick(byte x, byte y) {
  joystick.setXAxis(x);
  joystick.setYAxis(y);
}

void set_right_stick(byte z, byte rz) {
  joystick.setZAxis(z);
  joystick.setRzAxis(rz);
}

void setup() {
  pinMode(STATUS_LED_PIN, OUTPUT);
  digitalWrite(STATUS_LED_PIN, LOW);
  
  Switch.begin(9600);
  Backend.begin(9600);

  // Spinlock until incoming interface is ready.
  while(!Backend);

  // Setup JoyCon
  joystick.begin();

  joystick.setHatSwitch(-1);
  // 0 = left/up, 128 = neutral, 255 = right/down
  set_left_stick(128, 128);
  set_right_stick(128, 128);

  digitalWrite(STATUS_LED_PIN, HIGH);
  Backend.println("Switch controller ready!");
}

void handle_d_pad(int directionByte) {
  switch(directionByte) {
    case D_PAD_LEFT:
      joystick.setHatSwitch(270);
      delay(50);
      joystick.setHatSwitch(-1);
      break;
    case D_PAD_RIGHT:
      joystick.setHatSwitch(90);
      delay(50);
      joystick.setHatSwitch(-1);
      break;
    case D_PAD_DOWN:
      joystick.setHatSwitch(180);
      delay(50);
      joystick.setHatSwitch(-1);
      break;
    case D_PAD_UP:
      joystick.setHatSwitch(0);
      delay(50);
      joystick.setHatSwitch(-1);
      break;
    default:
      Backend.print("Unknown D-Pad direction: ");
      Backend.println(directionByte);
      break;
  }
}

void loop() {
  Backend.println("Entering loop");
  if(Backend.available() > 0) {
    int inByte = Backend.read();

    // Ignore newlines and line feeds
    if(inByte == '\n' || inByte == 10) {
      return;
    }

    Backend.print("Received command: ");
    Backend.println(inByte);

    // Handle d-pad differently than buttons
    if(inByte == D_PAD_PREFIX) {
      while(!Backend.available());
      
      int directionByte = Backend.read();
      handle_d_pad(directionByte);
      return;
    }
    if(inByte == STICK_PREFIX) {
      while(!Backend.available());

      int stickIdentifierByte = Backend.read();
      if(stickIdentifierByte != L_STICK_PREFIX && stickIdentifierByte != R_STICK_PREFIX) {
        Backend.print("Unknown stick identifier: ");
        Backend.println(stickIdentifierByte);
      }
      else {
        while(Backend.available() < 2);
        byte firstDirection = Backend.read();
        byte secondDirection = Backend.read();

        if(stickIdentifierByte == L_STICK_PREFIX) {
          set_left_stick(firstDirection, secondDirection);
        }
        else if(stickIdentifierByte == R_STICK_PREFIX) {
          set_right_stick(firstDirection, secondDirection);
        }
      }
    }
    
    switch(inByte) {
      case 'Y':
        joystick.pressButton(Y);
        delay(50);
        joystick.releaseButton(Y);
        break;
      case 'X':
        joystick.pressButton(X);
        delay(50);
        joystick.releaseButton(X);
        break;
      case 'A':
        joystick.pressButton(A);
        delay(50);
        joystick.releaseButton(A);
        break;
      case 'B':
        joystick.pressButton(B);
        delay(50);
        joystick.releaseButton(B);
        break;
      case 'H':
        joystick.pressButton(HOME);
        delay(50);
        joystick.releaseButton(HOME);
        break;
      case 'M':
        joystick.pressButton(MINUS);
        delay(50);
        joystick.releaseButton(MINUS);
        break;
      case 'P':
        joystick.pressButton(PLUS);
        delay(50);
        joystick.releaseButton(PLUS);
        break;
      case 'R':
        joystick.pressButton(R);
        delay(50);
        joystick.releaseButton(R);
        break;
      case 'L':
        joystick.pressButton(L);
        delay(50);
        joystick.releaseButton(L);
        break;
      case 'C':
        joystick.pressButton(CAPTURE);
        delay(50);
        joystick.releaseButton(CAPTURE);
        break;
      case 'Z':
        {
          while(!Backend.available());
          
          int directionByte = Backend.read();
          if(directionByte == 'L') {
            joystick.pressButton(Z_L);
            delay(50);
            joystick.releaseButton(Z_L);
          }
          else if(directionByte == 'R') {
            joystick.pressButton(Z_R);
            delay(50);
            joystick.releaseButton(Z_R);
          }
          else {
            Backend.print("Unknown Z suffix: ");
            Backend.println(directionByte);
          }
        }
        break;
      default:
        Backend.print("Unknown command: ");
        Backend.println(inByte);
        break;
    }
  }
}
