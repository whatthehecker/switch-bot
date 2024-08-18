#ifndef COMMAND_EXECUTOR_H
#define COMMAND_EXECUTOR_H

#include <SwitchJoystick.h>

class CommandExecutor {
private:
    SwitchJoystick_ joystick;
    HardwareSerial backend;

    bool doTapCommand(const char* buffer);
    bool doHoldCommand(const char* buffer);
    bool doStickCommand(char* buffer);
    bool doReleaseCommand(const char* buffer);
    void printVersion();
    void setLeftStick(byte, byte);
    void setRightStick(byte, byte);

public:
    CommandExecutor(SwitchJoystick_ joystick, HardwareSerial backend);

    // The in milliseconds between holding down and releasing a button again when simulating a press.
    static const unsigned int PRESS_DELAY_TIME = 50;

    bool executeCommandFromBuffer(char* buffer);
};
#endif