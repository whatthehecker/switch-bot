#include <Arduino.h>
#include <SwitchJoystick.h>
#include "button_constants.h"
#include "command_constants.h"
#include "command_executor.h"

#define Backend Serial1
#define Switch Serial

const int STATUS_LED_PIN = 9;

SwitchJoystick_ joystick;

const char COMMAND_SEPARATOR = '\n';
const size_t MAX_COMMAND_LENGTH = 32;
char commandBuffer[MAX_COMMAND_LENGTH];

CommandExecutor *executor;

void clearStoredCommand();

void setup()
{
  pinMode(STATUS_LED_PIN, OUTPUT);
  digitalWrite(STATUS_LED_PIN, LOW);

  Switch.begin(9600);
  Backend.begin(9600);

  // Spinlock until incoming serial interface is ready.
  while (!Backend);

  executor = new CommandExecutor(joystick, Backend);

  digitalWrite(STATUS_LED_PIN, HIGH);
}

void clearStoredCommand()
{
  memset(commandBuffer, 0, sizeof(commandBuffer));
}

void loop()
{
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
      executor->executeCommandFromBuffer(commandBuffer);
      clearStoredCommand();
    }
    else
    {
      commandBuffer[i++] = receivedChar;
    }
  }
}
