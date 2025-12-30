#ifndef COMMAND_EXECUTOR_H
#define COMMAND_EXECUTOR_H

#include <SwitchJoystick.h>

class CommandExecutor {
private:
    SwitchJoystick_ joystick;
    HardwareSerial& backend;

    bool doTapCommand(const char* buffer);
    bool doHoldCommand(const char* buffer);
    bool doStickCommand(const char* command);
    bool doReleaseCommand(const char* command);
    void printVersion() const;
    void setLeftStick(byte, byte);
    void setRightStick(byte, byte);

public:
    CommandExecutor(SwitchJoystick_ joystick, HardwareSerial& backend);

    // The delay between holding down and releasing a button again when simulating a press.
    static const unsigned int PRESS_DELAY_MILLIS = 50;

    bool executeCommandFromBuffer(const char* buffer);
};
#endif