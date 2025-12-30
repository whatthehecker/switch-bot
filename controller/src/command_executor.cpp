#include "command_executor.h"
#include "button_constants.h"

bool CommandExecutor::doTapCommand(const char* buffer)
{
    bool holdSuccessful = doHoldCommand(&buffer[0]);
    delay(PRESS_DELAY_MILLIS);
    bool releaseSuccessful = doReleaseCommand(&buffer[0]);
    return holdSuccessful && releaseSuccessful;
}

bool CommandExecutor::doHoldCommand(const char* command)
{
    char buttonNameOrPrefix = command[0];
    switch (buttonNameOrPrefix)
    {
    case 'A':
        joystick.pressButton(A);
        return true;
    case 'B':
        joystick.pressButton(B);
        return true;
    case 'X':
        joystick.pressButton(X);
        return true;
    case 'Y':
        joystick.pressButton(Y);
        return true;
    case 'L':
        joystick.pressButton(L);
        return true;
    case 'R':
        joystick.pressButton(R);
        return true;
    case 'Z':
        {
            char side = command[1];
            if (side == 'L')
            {
                joystick.pressButton(Z_L);
                return true;
            }
            else if (side == 'R')
            {
                joystick.pressButton(Z_R);
                return true;
            }
            return false;
        }
    case 'M':
        joystick.pressButton(MINUS);
        return true;
    case 'P':
        joystick.pressButton(PLUS);
        return true;
    case 'H':
        joystick.pressButton(HOME);
        return true;
    case 'C':
        joystick.pressButton(CAPTURE);
        return true;
    case 'D':
        {
            char direction = command[1];
            switch (direction)
            {
            case 'L':
                joystick.setHatSwitch(270);
                return true;
            case 'R':
                joystick.setHatSwitch(90);
                return true;
            case 'U':
                joystick.setHatSwitch(0);
                return true;
            case 'D':
                joystick.setHatSwitch(180);
                return true;
            default:
                return false;
            }
        }
    default: return false;
    }
}

bool CommandExecutor::doReleaseCommand(const char* command)
{
    char buttonNameOrPrefix = command[0];
    switch (buttonNameOrPrefix)
    {
    case 'A':
        joystick.releaseButton(A);
        return true;
    case 'B':
        joystick.releaseButton(B);
        return true;
    case 'X':
        joystick.releaseButton(X);
        return true;
    case 'Y':
        joystick.releaseButton(Y);
        return true;
    case 'L':
        joystick.releaseButton(L);
        return true;
    case 'R':
        joystick.releaseButton(R);
        return true;
    case 'Z':
        {
            char side = command[1];
            if (side == 'L')
            {
                joystick.releaseButton(Z_L);
                return true;
            }
            else if (side == 'R')
            {
                joystick.releaseButton(Z_R);
                return true;
            }
            return false;
        }
    case 'M':
        joystick.releaseButton(MINUS);
        return true;
    case 'P':
        joystick.releaseButton(PLUS);
        return true;
    case 'H':
        joystick.releaseButton(HOME);
        return true;
    case 'C':
        joystick.releaseButton(CAPTURE);
        return true;
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
                return true;
            default:
                return false;
            }
        }
    default:
        return false;
    }
}

bool CommandExecutor::doStickCommand(const char* command)
{
    char side = command[0];
    // Invalid side, ignore.
    if (side != 'L' && side != 'R')
    {
        return false;
    }

    char* endOfToken;
    double x = strtod(&command[1], &endOfToken);
    // Check whether separator between values is a comma and ignore rest of invalid command if it is not.
    if (*endOfToken != ',')
    {
        return false;
    }

    double y = strtod(endOfToken, &endOfToken);
    // Check whether the second number marks the end of the command by being followed by a null byte.
    if (*endOfToken != '\0')
    {
        return false;
    }

    // Ignore values outside of [-1.0, 1.0].
    if (abs(x) > 1.0 || abs(y) > 1.0)
    {
        return false;
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
    return true;
}

void CommandExecutor::printVersion() const
{
    backend.println("SwitchBot controller version 1");
}

void CommandExecutor::setLeftStick(byte x, byte y)
{
    joystick.setXAxis(x);
    joystick.setYAxis(y);
}

void CommandExecutor::setRightStick(byte z, byte rz)
{
    joystick.setZAxis(z);
    joystick.setRzAxis(rz);
}

CommandExecutor::CommandExecutor(SwitchJoystick_ joystick, HardwareSerial& backend)
    : joystick(joystick), backend(backend)
{
    joystick.begin();
    // Move D-Pad and joysticks to neutral positions.
    joystick.setHatSwitch(-1);
    setLeftStick(128, 128);
    setRightStick(128, 128);
}

bool CommandExecutor::executeCommandFromBuffer(const char* buffer)
{
    char prefix = buffer[0];
    switch (prefix)
    {
    case 'T':
        return doTapCommand(&buffer[1]);
    case 'H':
        return doHoldCommand(&buffer[1]);
    case 'R':
        return doReleaseCommand(&buffer[1]);
    case 'S':
        return doStickCommand(&buffer[1]);
    case 'V':
        printVersion();
        return true;
    default:
        // Invalid command prefix, ignore.
        return false;
    }
}
