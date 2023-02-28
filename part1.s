               .equ      EDGE_TRIGGERED,    0x1
               .equ      LEVEL_SENSITIVE,   0x0
               .equ      CPU0,              0x01    // bit-mask; bit 0 represents cpu0
               .equ      ENABLE,            0x1

               .equ      KEY0,              0b0001
               .equ      KEY1,              0b0010
               .equ      KEY2,              0b0100
               .equ      KEY3,              0b1000

               .equ      IRQ_MODE,          0b10010
               .equ      SVC_MODE,          0b10011

               .equ      INT_ENABLE,        0b01000000
               .equ      INT_DISABLE,       0b11000000
/*********************************************************************************
 * Initialize the exception vector table
 ********************************************************************************/
                .section .vectors, "ax"

                B        _start             // reset vector: by default go to _start
                .word    0                  // undefined instruction vector
                .word    0                  // software interrrupt vector
                .word    0                  // aborted prefetch vector
                .word    0                  // aborted data vector
                .word    0                  // unused vector
                B        IRQ_HANDLER        // IRQ interrupt vector: when you get an IRQ interrupt then go here
                .word    0                  // FIQ interrupt vector

/*********************************************************************************
 * Main program
 ********************************************************************************/
                .text
                .global  _start
_start:        
                /* Set up stack pointers for IRQ and SVC processor modes */
                 MOV      R1, #0b11010010                    // interrupts masked, MODE = IRQ
				 MSR      CPSR_c, R1                            // change to IRQ mode
				 LDR      SP, =0x40000                       // set IRQ stack pointer
				 /* Change to SVC (supervisor) mode with interrupts disabled */
				 MOV      R1, #0b11010011                    // interrupts masked, MODE = SVC
				 MSR      CPSR, R1                                // change to supervisor mode
				 LDR      SP, =0x20000                       // set SVC stack 

                BL       CONFIG_GIC              // configure the ARM generic interrupt controller

                // Configure the KEY pushbutton port to generate interrupts
                LDR      R0, =0xFF200050                    // pushbutton KEY base address
				MOV      R1, #0xF                                // set interrupt mask bits
				STR      R1, [R0, #0x8]                        // interrupt mask register is (base + 8)

                // enable IRQ interrupts in the processor
                MOV      R0, #0b01010011                    // IRQ unmasked, MODE = SVC
             	MSR      CPSR, R0
IDLE:
                B        IDLE                    // main program simply idles

IRQ_HANDLER:
                PUSH     {R0-R7, LR}
    
                /* Read the ICCIAR in the CPU interface */
                LDR      R4, =0xFFFEC100
                LDR      R5, [R4, #0x0C]         // read the interrupt ID

				LDR 	 R6, =0xFF200050 // store address of pushbuttons
				LDR 	 R7, =0xFF200020 // store address of hex displays

CHECK_KEYS:
                CMP      R5, #73
UNEXPECTED:     BNE      UNEXPECTED              // if interrupt is not recognized, stop here
    
                BL       KEY_ISR                 // else go to the KEY_ISR subroutine
EXIT_IRQ:
                /* Write to the End of Interrupt Register (ICCEOIR) */
                STR      R5, [R4, #0x10]
    
                POP      {R0-R7, LR}
                SUBS     PC, LR, #4

/*****************************************************0xFF200050***********************************
 * Pushbutton - Interrupt Service Routine                                
 *                                                                          
 * This routine checks which KEY(s) have been pressed. It writes to HEX3-0
 ***************************************************************************************/
                .global  KEY_ISR
KEY_ISR:
                MOV 	 R1, #0 // R1 is a temporary register to hold byte bit codes from hex display
				MOV 	 R0, #0 // R0 will hold the bit code to push to the hex display
				LDR 	 R2, [R6, #0xC] // get the value of the pushbuttons edgecapture register
				
				CMP 	 R2, #1 // check for key 0
				BEQ  	 KEY_0
				
				CMP 	 R2, #2 // check for key 1
				BEQ  	 KEY_1
				
				CMP 	 R2, #4 // check for key 2
				BEQ  	 KEY_2
				
				CMP 	 R2, #8 // check for key 3
				BEQ  	 KEY_3
				
CONTINUE: 		STR 	 R0, [R7] // push to hex display

				MOV		 R0, #0xF
				STR 	 R0, [R6, #0xC]

                MOV      PC, LR
				
KEY_0: 			LDRB 	R0, [R7, #3] // get hex 3 display code
				LSL 	R0, #8
				
				LDRB 	R1, [R7, #2] // get hex 2 display code
				ORR 	R0, R1
				LSL 	R0 , #8
				
				LDRB 	R1, [R7, #1] // get hex 1 display code
				ORR 	R0, R1
				LSL 	R0, #8

				LDRB 	 R1, [R7] // get the hex 0 display code
				CMP 	 R1, #0 // check if hex 0 is off
				MOVEQ 	 R1, #0x3F // move the bit code for 0 onto R0 if it is off
				MOVNE 	 R1, #0 // if it is on, then we have to turn it off
				ORR 	 R0, R1
				B 		 CONTINUE

KEY_1: 			LDRB 	R0, [R7, #3] // get hex 3 display code
				LSL 	R0, #8
				
				LDRB 	R1, [R7, #2] // get hex 2 display code
				ORR 	R0, R1
				LSL 	R0 , #8

				LDRB 	 R1, [R7, #1] // get the hex 1 display code
				CMP 	 R1, #0 // check if hex 1 is off
				MOVEQ 	 R1, #0x06 // move the bit code for 1 onto R0
				MOVNE 	 R1, #0 // if it is on, then we have to turn it off
				ORR 	 R0, R1
				LSL 	 R0, #8
				
				LDRB 	R1, [R7] // get hex 0 display code
				ORR 	R0, R1
				B 		 CONTINUE

KEY_2: 			LDRB 	R0, [R7, #3] // get hex 3 display code
				LSL 	R0, #8

				LDRB 	 R1, [R7, #2] // get the hex 2 display code
				CMP 	 R1, #0 // check if hex 2 is off
				MOVEQ 	 R1, #0x5B // move the bit code for 2 onto R0
				MOVNE 	 R1, #0 // if it is on, then we have to turn it off
				ORR 	 R0, R1
				LSL 	 R0, #8
				
				LDRB 	R1, [R7, #1] // get hex 1 display code
				ORR 	R0, R1
				LSL 	R0 , #8
				
				LDRB 	R1, [R7] // get hex 0 display code
				ORR 	R0, R1
				B 		 CONTINUE

KEY_3: 			LDRB 	 R0, [R7, #3] // get the hex 3 display code
				CMP 	 R0, #0 // check if hex 3 is off
				MOVEQ 	 R0, #0x4F // move the bit code for 3 onto R0
				MOVNE 	 R0, #0 // if it is on, then we have to turn it off
				LSL 	 R0, #8
				
				LDRB 	R1, [R7, #2] // get hex 2 display code
				ORR 	R0, R1
				LSL 	R0 , #8
				
				LDRB 	R1, [R7, #1] // get hex 1 display code
				ORR 	R0, R1
				LSL 	R0 , #8
				
				LDRB 	R1, [R7] // get hex 0 display code
				ORR 	R0, R1
				B 		 CONTINUE

/* 
 * Configure the Generic Interrupt Controller (GIC)
*/
                .global  CONFIG_GIC
CONFIG_GIC:
                PUSH     {LR}
                /* Enable the KEYs interrupts */
                MOV      R0, #73
                MOV      R1, #CPU0
                /* CONFIG_INTERRUPT (int_ID (R0), CPU_target (R1)); */
                BL       CONFIG_INTERRUPT

                /* configure the GIC CPU interface */
                LDR      R0, =0xFFFEC100        // base address of CPU interface
                /* Set Interrupt Priority Mask Register (ICCPMR) */
                LDR      R1, =0xFFFF            // enable interrupts of all priorities levels
                STR      R1, [R0, #0x04]
                /* Set the enable bit in the CPU Interface Control Register (ICCICR). This bit
                 * allows interrupts to be forwarded to the CPU(s) */
                MOV      R1, #1
                STR      R1, [R0]
    
                /* Set the enable bit in the Distributor Control Register (ICDDCR). This bit
                 * allows the distributor to forward interrupts to the CPU interface(s) */
                LDR      R0, =0xFFFED000
                STR      R1, [R0]    
    
                POP      {PC}
/* 
 * Configure registers in the GIC for an individual interrupt ID
 * We configure only the Interrupt Set Enable Registers (ICDISERn) and Interrupt 
 * Processor Target Registers (ICDIPTRn). The default (reset) values are used for 
 * other registers in the GIC
 * Arguments: R0 = interrupt ID, N
 *            R1 = CPU target
*/
CONFIG_INTERRUPT:
                PUSH     {R4-R5, LR}
    
                /* Configure Interrupt Set-Enable Registers (ICDISERn). 
                 * reg_offset = (integer_div(N / 32) * 4
                 * value = 1 << (N mod 32) */
                LSR      R4, R0, #3               // calculate reg_offset
                BIC      R4, R4, #3               // R4 = reg_offset
                LDR      R2, =0xFFFED100
                ADD      R4, R2, R4               // R4 = address of ICDISER
    
                AND      R2, R0, #0x1F            // N mod 32
                MOV      R5, #1                   // enable
                LSL      R2, R5, R2               // R2 = value

                /* now that we have the register address (R4) and value (R2), we need to set the
                 * correct bit in the GIC register */
                LDR      R3, [R4]                 // read current register value
                ORR      R3, R3, R2               // set the enable bit
                STR      R3, [R4]                 // store the new register value

                /* Configure Interrupt Processor Targets Register (ICDIPTRn)
                  * reg_offset = integer_div(N / 4) * 4
                  * index = N mod 4 */
                BIC      R4, R0, #3               // R4 = reg_offset
                LDR      R2, =0xFFFED800
                ADD      R4, R2, R4               // R4 = word address of ICDIPTR
                AND      R2, R0, #0x3             // N mod 4
                ADD      R4, R2, R4               // R4 = byte address in ICDIPTR

                /* now that we have the register address (R4) and value (R2), write to (only)
                 * the appropriate byte */
                STRB     R1, [R4]
    
                POP      {R4-R5, PC}

                .end   
