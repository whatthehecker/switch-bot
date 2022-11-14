/**
 * Code for the Arduino which sends data to another Arduino over UART to make
 * that Arduino act as a controller for the Nintendo Switch instead.
 */
#define Controller Serial1
#define Computer Serial

#define STATUS_LED_PIN 9

char buf[8];

void setup() {
  pinMode(STATUS_LED_PIN, OUTPUT);
  digitalWrite(STATUS_LED_PIN, LOW);

  Computer.begin(9600);
  delay(1000);
  Controller.begin(9600);

  digitalWrite(STATUS_LED_PIN, HIGH);
  Computer.println("Primary proxy ready!");
}

void loop() {
  int bytesRead;
  if(bytesRead = Computer.readBytesUntil('\n', buf, sizeof(buf))) {
    // Write the receives bytes followed by a single newline (println emits an additional carriage return before the newline
    // which we don't want).
    Controller.write(buf, bytesRead);
    Controller.write('\n');

    // Read response and relay it to the computer.
    while(!Controller.available());
    byte response = Controller.read();
    Computer.write(response);
  }
}
