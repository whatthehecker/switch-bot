# Serial protocol
The serial protocol is used to communicate between your computer and the Arduino that acts as a virtual controller for your Switch.
It defines commands to control which buttons are to be pressed and how other parts such as the joysticks on the controller are supposed to be moved.

## Command structure
Commands are sent in plain-text over serial to the controller.
The used baud rate is 115200, the error correction scheme is TODO (Stopbits and stuff).
Commands are separated by newline characters (`\n`).
The controller executes each command immediately when it receives a full line of text and does not send any acknowledgement (for now). This is done so that no time is wasted waiting for acknowledgement which takes too long in cases where a complex series of commands has to be executed in a quick succession (imagine rotating one of the joysticks evenly to walk a circle in a game).
A command may only contain the data it is supposed to have. If there's any trailing data before the newline or the command is not one of the commands defined below, it is invalid. Invalid commands are silently discarded.

## Command prefixes
- T: Tap button. Holds and then shortly after releases a button again, similar to when you manually tap a button.
- H: Hold button down. Only allowed for buttons and triggers which can be held down.
- R: Release held button. Only allowed for buttons and triggers which can be held down.
- S: Stick input. Followed by the name of the joystick and two decimal numbers (separated by a comma) describing the movement of the stick on the X and Y axis.

## Button names
The following strings can be used to refer to buttons:
- A: A button
- B: B button
- Y: Y button
- X: X button
- L: Front left shoulder button
- R: Front right shoulder button
- ZL: Back left shoulder button
- ZR: Back right shoulder button
- M: Minus button
- P: Plus button
- H: Home button
- C: Capture/screenshot button
- D: Prefix for the D-Pad buttons, followed by one of the following:
  - L: Left
  - R: Right
  - U: Up
  - D: Down

## Joystick names
The following strings can be used to refer to the joysticks:
- S: Prefix for the joysticks, followed by one of the following:
  - L: Left joystick
  - R: Right joystick

## Special commands
- `V`: Test the connection. If received by the controller, it prints `SwitchBot controller version XXX` where `XXX` is a version identifier. Use this command to check whether everything is working correctly.

## Command examples
- `HA`: Start holding down the A button. Does nothing if A was already held.
- `RB`: Release the B button. Does nothing if B was not held.
- `SL-1,0.5`: Move the left stick all the way to the left horizontally and up halfway.
- `SR0,0`: Move the left stick to the neutral center position.
- `HDU`: Start holding down on the D-Pad.
- `TH`: Tap the Home button by holding it down and then releasing it again shortly after.
