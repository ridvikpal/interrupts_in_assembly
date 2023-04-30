# Interrupts in Assembly
## IT IS AN ACADEMIC OFFENSE TO COPY CODE. THIS IS SIMPLY FOR REFERENCE.
Working Code for ECE243 Lab 4 (Winter 2023) at the University of Toronto. The goal is to work learn how to use interrupts for the ARMv7 processor on the DE1-SoC board. All code is written and debugged in ARM Assembly. All code is written in C and debugged in ARM Assembly. To simulate the code, upload the code and compile using the ARMv7 [CPUlator online tool](https://cpulator.01xz.net/?sys=arm-de1soc "CPUlator"). See the lab handout for more information.

## Part 1
Part 1 shows the numbers 0 to 3 on the hex displays HEX0 to HEX3 respectively when the corresponding pushbutton KEY0 to KEY3 is pressed, using pushbutton interrupts:
![image](https://user-images.githubusercontent.com/105998663/221741090-58767af5-6a6a-4897-b8aa-ce96f53510be.png)


## Part 2
Part 2 uses the LEDR lights to show the value of a binary counter which is incremented by the A9 timer. The pushbutton keys can be used to pause the counter. Both the timer and pushbuttons use interrupts:
![image](https://user-images.githubusercontent.com/105998663/221741586-7dbc0e52-5bae-4da9-adb5-dc56da355754.png)


## Part 3
Part 3 does the same as Part 2 but now the pushbuttons can also be used to double or halve the rate of the binary counter.
