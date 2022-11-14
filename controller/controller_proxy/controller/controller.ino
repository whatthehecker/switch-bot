/**
 * Code for the Arduino which reads data from the proxy Arduino and acts
 * as a virtual controller for the Nintendo Switch.
 */
#include <Joystick.h>

#define Primary Serial1
#define Switch Serial

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

#define OK '.'
#define ERR '-'

#define STATUS_LED_PIN 9

char buf[8];

Joystick_ joystick;

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
  
  Primary.begin(9600);
  Switch.begin(9600);

  // Setup JoyCon
  joystick.begin();

  joystick.setHatSwitch(-1);
  // 0 = left/up, 128 = neutral, 255 = right/down
  set_left_stick(128, 128);
  set_right_stick(128, 128);

  digitalWrite(STATUS_LED_PIN, HIGH);
}

byte handle_d_pad(byte directionByte) {
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
      return ERR;
  }
  return OK;
}

byte handle_command(byte command, int bytesRead, char buf[]) {
  switch(command) {
      case D_PAD_PREFIX:
        // Payload must be exactly one byte.
        if(bytesRead - 1 != 1) {
          return ERR;
        }
        return handle_d_pad(buf[1]);
      case STICK_PREFIX:
        if(bytesRead - 1 != 3) {
          return ERR;
        }

        {
          byte stickIdentifierByte = buf[1];
          byte firstDirection = buf[2];
          byte secondDirection = buf[3];
  
          if(stickIdentifierByte == L_STICK_PREFIX) {
            set_left_stick(firstDirection, secondDirection);
            return OK;
          }
          else if(stickIdentifierByte == R_STICK_PREFIX) {
            set_right_stick(firstDirection, secondDirection);
            return OK;
          }
        }
       
        return ERR;
      case 'Y':
        joystick.pressButton(Y);
        delay(50);
        joystick.releaseButton(Y);
        return OK;
      case 'X':
        joystick.pressButton(X);
        delay(50);
        joystick.releaseButton(X);
        return OK;
      case 'A':
        joystick.pressButton(A);
        delay(50);
        joystick.releaseButton(A);
        return OK;
      case 'B':
        joystick.pressButton(B);
        delay(50);
        joystick.releaseButton(B);
        return OK;
      case 'H':
        joystick.pressButton(HOME);
        delay(50);
        joystick.releaseButton(HOME);
        return OK;
      case 'M':
        joystick.pressButton(MINUS);
        delay(50);
        joystick.releaseButton(MINUS);
        return OK;
      case 'P':
        joystick.pressButton(PLUS);
        delay(50);
        joystick.releaseButton(PLUS);
        return OK;
      case 'R':
        joystick.pressButton(R);
        delay(50);
        joystick.releaseButton(R);
        return OK;
      case 'L':
        joystick.pressButton(L);
        delay(50);
        joystick.releaseButton(L);
        return OK;
      case 'C':
        joystick.pressButton(CAPTURE);
        delay(50);
        joystick.releaseButton(CAPTURE);
        return OK;
      case 'Z':
        // Payload must be exactly 1 byte.
        if(bytesRead - 1 != 1) {
          return ERR;
        }

        {
          byte directionByte = buf[1];
          if(directionByte == 'L') {
            joystick.pressButton(Z_L);
            delay(50);
            joystick.releaseButton(Z_L);
            return OK;
          }
          else if(directionByte == 'R') {
            joystick.pressButton(Z_R);
            delay(50);
            joystick.releaseButton(Z_R);
            return OK;
          }
        }

        return ERR;
      default:
        return ERR;
    }
    return ERR;
}

void loop() {
  int bytesRead = Primary.readBytesUntil('\n', buf, sizeof(buf));
  if(bytesRead > 0)  {
    byte command = buf[0];
    byte result = handle_command(command, bytesRead, buf);
    Primary.write(result);
  }
}
