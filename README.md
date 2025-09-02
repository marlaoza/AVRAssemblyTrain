# AVR Assembly Model Train Station With ATmega328P  

This is the source code for an automation project assignment from my computer engineering classes. built in **AVR ASSEMBLY** for the **ATMEGA328P** microcontroller
It simulates and controls a **miniature train station**, with **two trains**, **track switches**, and automatic **station stops**.  

---

  - **H-Bridge motor driver** to control two trains individually.  
  - Energy is passed trought the board to the moving trains via a **SlipRing**.  
  - When a train passes over an LDR, the corresponding **servo motor rotates**, automatically redirecting the tracks.  
  - **other 2 additional LDR sensors** detect when a train has arrived at a station, halting the corresponding train until the other gets close.  
  - **4 servo motors** controlled via software induced pwm.
  - Fully controllable speed and fully reversible with a potentiometer.

---

