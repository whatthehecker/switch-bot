# Controller
The controller is the software running on an Arduino (or a similar microcontroller) that acts as a game controller attached by USB to the Nintendo Switch console.

It takes in commands through another USB connection and executes the corresponding action on the Switch (such as pressing a gamepad button or moving the joysticks).

## Variants
There are two variants of the Arduino setup:
1. Direct: The direct variant uses a single microcontroller. Commands are read over the serial pins, which are connected to the computer using a Serial-to-UART cable. 

This only requires a single microcontroller but has the drawback of being more error prone. Should the computer send any data to the microcontroller which is not understood, the controller might lock up. Under Windows, this regularly happens when the computer attempts to go to sleep and sends a request to go into low-power mode to all USB devices. For this reason, using the proxy-controller variant is recommended, which is more error resistant.

2. Proxy-Controller: This variant uses two Arduinos which communicate to each other through the serial pins. The "controller" Arduino uses its built-in USB port to act as a virtual controller for the Nintendo Switch while the "proxy" Arduino uses its USB port to communicate with the computer. As both Arduinos use their USB ports for communication, there's usually fewer problems with other software sending unrecognized commands which lock up any of the microcontrollers.