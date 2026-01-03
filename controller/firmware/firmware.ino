#include <SwitchJoystick.h>
#include "command_executor.h"

// The Serial port that is connected to the host computer, being connected through a USB-to-UART converter cable.
#define BackendSerial Serial1
// The Serial port that acts as a USB controller and is connected to the Nintendo Switch, being the Pro Micro's USB port.
#define SwitchSerial Serial

const int STATUS_LED_PIN = LED_BUILTIN;

SwitchJoystick_ joystick;

const char COMMAND_SEPARATOR = '\n';
const size_t MAX_COMMAND_LENGTH = 32;
char commandBuffer[MAX_COMMAND_LENGTH];
size_t currentIndex = 0;

// The "center" value for a joystick axis.
const uint8_t AXIS_NEUTRAL = 128;

CommandExecutor *executor;

void resetCommandBuffer();

void setup()
{
  pinMode(STATUS_LED_PIN, OUTPUT);
  digitalWrite(STATUS_LED_PIN, LOW);

  BackendSerial.begin(115200);
  SwitchSerial.begin(9600);

  BackendSerial.println("Setting up virtual joystick...");

  joystick.begin();
  joystick.setHatSwitch(-1);
  joystick.setXAxis(AXIS_NEUTRAL);
  joystick.setYAxis(AXIS_NEUTRAL);
  joystick.setZAxis(AXIS_NEUTRAL);
  joystick.setRzAxis(AXIS_NEUTRAL);

  executor = new CommandExecutor(joystick, BackendSerial);

  digitalWrite(STATUS_LED_PIN, HIGH);
  BackendSerial.println("Setup done!");
}

void resetCommandBuffer()
{
  memset(commandBuffer, 0, sizeof(commandBuffer));
  currentIndex = 0;
}

void loop()
{
  while (BackendSerial.available() > 0)
  {
    int receivedData = BackendSerial.read();

    if (receivedData == -1)
    {
      continue;
    }

    char receivedChar = static_cast<char>(receivedData);
    // If the command is invalid because it is too long, ignore it.
    if (currentIndex >= MAX_COMMAND_LENGTH - 1)
    {
      resetCommandBuffer();
      return;
    }

    if (receivedChar == COMMAND_SEPARATOR)
    {
      // Ignore empty commands.
      if (currentIndex == 0)
      {
        resetCommandBuffer();
        return;
      }

      commandBuffer[currentIndex] = '\0';
      BackendSerial.print("Executing command: ");
      BackendSerial.println(commandBuffer);
      bool wasValid = executor->executeCommandFromBuffer(commandBuffer);
      if (wasValid)
      {
        BackendSerial.println("Command was valid.");
      } else
      {
        BackendSerial.println("CommandExecutor ignored invalid command.");
      }
      resetCommandBuffer();
    }
    else
    {
      commandBuffer[currentIndex++] = receivedChar;
    }
  }
}
