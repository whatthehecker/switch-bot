#include <SwitchJoystick.h>

SwitchJoystick_ joystick;

#define Y 0
#define B 1
#define A 2
#define X 3
#define L 4
#define R 5
#define Z_L 6
#define Z_R 7
#define MINUS 8
#define PLUS 9
#define LSTICK 10
#define RSTICK 11
#define HOME 12
#define CAPTURE 13

#define D_PAD_PREFIX 'D'
#define D_PAD_LEFT 'L'
#define D_PAD_RIGHT 'R'
#define D_PAD_DOWN 'D'
#define D_PAD_UP 'U'

#define STICK_PREFIX 'S'
#define L_STICK_PREFIX 'L'
#define R_STICK_PREFIX 'R'

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
  
  Serial.begin(9600);
  Serial1.begin(9600);

  // Spinlock until incoming interface is ready.
  while(!Serial1);

  // Setup JoyCon
  joystick.begin();

  joystick.setHatSwitch(-1);
  // 0 = left/up, 128 = neutral, 255 = right/down
  set_left_stick(128, 128);
  set_right_stick(128, 128);

  digitalWrite(STATUS_LED_PIN, HIGH);
  Serial1.println("Switch controller ready!");
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
      Serial1.print("Unknown D-Pad direction: ");
      Serial1.println(directionByte);
      break;
  }
}

void loop() {
  Serial1.println("Entering loop");
  if(Serial1.available() > 0) {
    int inByte = Serial1.read();

    // Ignore newlines and line feeds
    if(inByte == '\n' || inByte == 10) {
      return;
    }

    Serial1.print("Received command: ");
    Serial1.println(inByte);

    // Handle d-pad differently than buttons
    if(inByte == D_PAD_PREFIX) {
      while(!Serial1.available());
      
      int directionByte = Serial1.read();
      handle_d_pad(directionByte);
      return;
    }
    if(inByte == STICK_PREFIX) {
      while(!Serial1.available());

      int stickIdentifierByte = Serial1.read();
      if(stickIdentifierByte != L_STICK_PREFIX && stickIdentifierByte != R_STICK_PREFIX) {
        Serial1.print("Unknown stick identifier: ");
        Serial1.println(stickIdentifierByte);
      }
      else {
        while(Serial1.available() < 2);
        byte firstDirection = Serial1.read();
        byte secondDirection = Serial1.read();

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
          while(!Serial1.available());
          
          int directionByte = Serial1.read();
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
            Serial1.print("Unknown Z suffix: ");
            Serial1.println(directionByte);
          }
        }
      default:
        Serial1.print("Unknown command: ");
        Serial1.println(inByte);
        break;
    }
  }
}
