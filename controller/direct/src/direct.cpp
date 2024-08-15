#include <Arduino.h>
#include <SwitchJoystick.h>
#include "button_constants.h"
#include "command_constants.h"

#define Backend Serial1
#define Switch Serial

const int STATUS_LED_PIN = 9;

SwitchJoystick_ joystick;

const char COMMAND_SEPARATOR = '\n';
const int MAX_COMMAND_LENGTH = 32;
char commandBuffer[MAX_COMMAND_LENGTH];

// The in milliseconds between holding down and releasing a button again when simulating a press.
const unsigned int PRESS_DELAY_TIME = 50;

void doTapCommand(char *);
void doHoldCommand(char *);
void doReleaseCommand(char *);
void doStickCommand(char *);
void printVersion();
void setLeftStick(byte, byte);
void setRightStick(byte, byte);
void executeStoredCommand();
void clearStoredCommand();

void setLeftStick(byte x, byte y)
{
  joystick.setXAxis(x);
  joystick.setYAxis(y);
}

void setRightStick(byte z, byte rz)
{
  joystick.setZAxis(z);
  joystick.setRzAxis(rz);
}

void setup()
{
  pinMode(STATUS_LED_PIN, OUTPUT);
  digitalWrite(STATUS_LED_PIN, LOW);

  Switch.begin(9600);
  Backend.begin(9600);

  // Spinlock until incoming serial interface is ready.
  while (!Backend)
    ;

  // Setup JoyCon
  joystick.begin();

  // Move D-Pad and joysticks to neutral positions.
  joystick.setHatSwitch(-1);
  setLeftStick(128, 128);
  setRightStick(128, 128);

  digitalWrite(STATUS_LED_PIN, HIGH);
  Backend.println("Switch controller ready!");
}

void executeStoredCommand()
{
  char prefix = commandBuffer[0];
  switch (prefix)
  {
  case 'T':
    doTapCommand(&commandBuffer[1]);
    break;
  case 'H':
    doHoldCommand(&commandBuffer[1]);
    break;
  case 'R':
    doReleaseCommand(&commandBuffer[1]);
    break;
  case 'S':
    doStickCommand(&commandBuffer[1]);
    break;
  case 'V':
    printVersion();
    break;
  default:
    // Invalid command prefix, ignore.
    return;
  }
}

void printVersion()
{
  Backend.print("SwitchBot controller version 1");
}

void doTapCommand(char *command)
{
  doHoldCommand(&command[0]);
  delay(PRESS_DELAY_TIME);
  doReleaseCommand(&command[0]);
}

void doHoldCommand(char *command)
{
  char buttonNameOrPrefix = command[0];
  switch (buttonNameOrPrefix)
  {
  case 'A':
    joystick.pressButton(A);
    break;
  case 'B':
    joystick.pressButton(B);
    break;
  case 'X':
    joystick.pressButton(X);
    break;
  case 'Y':
    joystick.pressButton(Y);
    break;
  case 'L':
    joystick.pressButton(L);
    break;
  case 'R':
    joystick.pressButton(R);
    break;
  case 'Z':
  {
    char side = command[1];
    if (side == 'L')
    {
      joystick.pressButton(Z_L);
    }
    else if (side == 'R')
    {
      joystick.pressButton(Z_R);
    }
  }
  break;
  case 'M':
    joystick.pressButton(MINUS);
    break;
  case 'P':
    joystick.pressButton(PLUS);
    break;
  case 'H':
    joystick.pressButton(HOME);
    break;
  case 'C':
    joystick.pressButton(CAPTURE);
    break;
  case 'D':
  {
    char direction = command[1];
    switch (direction)
    {
    case 'L':
      joystick.setHatSwitch(270);
      break;
    case 'R':
      joystick.setHatSwitch(90);
      break;
    case 'U':
      joystick.setHatSwitch(0);
      break;
    case 'D':
      joystick.setHatSwitch(180);
      break;
    }
  }
  }
}

void doReleaseCommand(char *command)
{
  char buttonNameOrPrefix = command[0];
  switch (buttonNameOrPrefix)
  {
  case 'A':
    joystick.releaseButton(A);
    break;
  case 'B':
    joystick.releaseButton(B);
    break;
  case 'X':
    joystick.releaseButton(X);
    break;
  case 'Y':
    joystick.releaseButton(Y);
    break;
  case 'L':
    joystick.releaseButton(L);
    break;
  case 'R':
    joystick.releaseButton(R);
    break;
  case 'Z':
  {
    char side = command[1];
    if (side == 'L')
    {
      joystick.releaseButton(Z_L);
    }
    else if (side == 'R')
    {
      joystick.releaseButton(Z_R);
    }
  }
  break;
  case 'M':
    joystick.releaseButton(MINUS);
    break;
  case 'P':
    joystick.releaseButton(PLUS);
    break;
  case 'H':
    joystick.releaseButton(HOME);
    break;
  case 'C':
    joystick.releaseButton(CAPTURE);
    break;
  case 'D':
  {
    char direction = command[1];
    switch (direction)
    {
    case 'L':
    case 'R':
    case 'U':
    case 'D':
      joystick.setHatSwitch(-1);
      break;
    }
  }
  }
}

void doStickCommand(char *command)
{
  char side = command[0];
  // Invalid side, ignore.
  if (side != 'L' && side != 'R')
  {
    return;
  }

  char *xAxisToken = strtok(command, ",");
  char *endOfToken;
  double x = strtod(&command[1], &endOfToken);
  // Check whether separator between values is a comma and ignore rest of invalid command if it is not.
  if (*endOfToken != ',')
  {
    return;
  }

  double y = strtod(endOfToken, &endOfToken);
  // Check whether the second number marks the end of the command by being followed by a null byte.
  if (*endOfToken != '\0')
  {
    return;
  }

  // Ignore values outside of [-1.0, 1.0].
  if (abs(x) > 1.0 || abs(y) > 1.0)
  {
    return;
  }

  // The conversion is a bit weird:
  // 0 is left, 127 is neutral, 255 is right (so 128 is apparently already a bit right).
  // If we multiplied by 128 instead of 127 we could end up with negative values for x = -1.0 which would overflow,
  // if we offset by 128 instead of 127 we cannot go all the way to the left since we can get 128 - 127 = 1 at most.
  // Since the second case isn't as bad we do that.
  byte xByte = 128 + x * 127;
  byte yByte = 128 + y * 127;

  if (side == 'L')
  {
    setLeftStick(xByte, yByte);
  }
  // We can just use else because anything other than these 2 values should have been caught earlier already.
  else
  {
    setRightStick(xByte, yByte);
  }
}

void clearStoredCommand()
{
  memset(commandBuffer, 0, sizeof(commandBuffer));
}

void loop()
{
  Backend.println("Entering loop");

  size_t i = 0;
  while (Backend.available() > 0)
  {
    char receivedChar = Serial.read();
    // If the command is invalid because it is too long, ignore it.
    if (i >= MAX_COMMAND_LENGTH - 1)
    {
      clearStoredCommand();
      return;
    }

    if (receivedChar == COMMAND_SEPARATOR)
    {
      commandBuffer[i++] = '\0';
      executeStoredCommand();
      clearStoredCommand();
    }
    else
    {
      commandBuffer[i++] = receivedChar;
    }
  }
}
