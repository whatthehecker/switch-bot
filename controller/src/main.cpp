#include "Arduino.h"
#include <SwitchJoystick.h>
#include "command_executor.h"

// The Serial port that is connected to the host computer, being connected through a USB-to-UART converter cable.
#define BackendSerial Serial1
// The Serial port that acts as a USB controller and is connected to the Nintendo Switch, being the Pro Micro's USB port.
#define SwitchSerial Serial

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

  SwitchSerial.begin(115200);
  BackendSerial.begin(9600);

  executor = new CommandExecutor(joystick, BackendSerial);

  digitalWrite(STATUS_LED_PIN, HIGH);
}

void clearStoredCommand()
{
  memset(commandBuffer, 0, sizeof(commandBuffer));
}

void loop()
{
  size_t i = 0;
  while (BackendSerial.available() > 0)
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
