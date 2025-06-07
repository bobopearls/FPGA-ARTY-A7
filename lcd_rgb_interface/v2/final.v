Marie
Add Status

Marie — 6/5/25, 6:43 PM
hello
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Maria Louise Quitoriano
// 4-bit Initializaiton for the Dot Matrix LCD Screen
//////////////////////////////////////////////////////////////////////////////////
Expand
message.txt
32 KB
## This file is a general .xdc for the Arty A7-35 Rev. D and Rev. E
## To use it in a project:
## - uncomment the lines corresponding to used pins
## - rename the used ports (in each line, after get_ports) according to the top level signal names in the project

## Clock signal
Expand
message.txt
22 KB
peakysneaky12 — 6/5/25, 7:19 PM
`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Maria Louise Quitoriano
// 4-bit Initializaiton for the Dot Matrix LCD Screen
//////////////////////////////////////////////////////////////////////////////////
Expand
marie.v
31 KB
peakysneaky12 — Yesterday at 10:13 PM
hello marie, just wanna ask lang
diba tom Jan 7 11:59 pm is the deadline for documentation
Marie — 12:47 AM
Hello!! Slr yes june 7
Basically today HAHHAHA
slr finished a 192 paper (sobrang clutch)
peakysneaky12 — 2:20 AM
ah np, sorry if i botherd u on your paper
thank you for the response
﻿
peakysneaky12
sneakypeaky5300
 
`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Maria Louise Quitoriano
// 4-bit Initializaiton for the Dot Matrix LCD Screen
//////////////////////////////////////////////////////////////////////////////////

// this will take the 10 bit input, and then divide it into the ff
// the enable and r/w bits, then the lower and upper halves.
// after, we assign the bits to certain parts and this becomes the output to the LCD
// this is for initalization

// initialization activity:
// power on
// .wait for more than 15 ms after logic high vcc = 4.5v   15ms
// .func set command 1                                     15ms + 40us 
// .wait 4.1ms                                             15ms + 40us + 4.1ms
// .func set command 2                                     15ms + 40us + 4.1ms + 40us
// .wait more than 100 us                                  15ms + 40us + 4.1ms + 40us + 100us 
// func set command 3 - after this BF can be checked      15ms + 40us + 4.1ms + 40us + 100us + 40us
// func set command 4 - 4 bit interface already           15ms + 40us + 4.1ms + 40us + 100us + 40us + 40us
// func set command 5 - two sets                          15ms + 40us + 4.1ms + 40us + 100us + 40us + 40us + (40us + 40us)
// display off - two sets                                 15ms + 40us + 4.1ms + 40us + 100us + 40us + 40us + 40us + 40us + (40us + 40us) 
// clear display - two sets                               15ms + 40us + 4.1ms + 40us + 100us + 40us + 40us + 40us + 40us + 40us + 40us + (15.2ms +15.2ms)
// entry mode set - two sets                              15ms + 40us + 4.1ms + 40us + 100us + 40us + 40us + 40us + 40us + 40us + 40us + 15.2ms +15.2ms +(40us + 40us)
// display on - two sets                                  
// init done for the LCD screen


// edit: since we need to read out a DB7 bit for the busy flag, add that later 
// note in the data sheet says to check BF bit before every instruction, starting with display OFF: 
// Reads the busy flag (BF) and value of the address counter (AC). BF = 1 indicates that on internal operation is in
// progress and the next instruction will not be accepted until BF is set to "0". If the display is written while BF = 1,
// abnormal operation will occur.
// The BF status should be checked before each write operation
module marie(
    input wire clk, nrst,
    output reg RS_init, E_init,
    //output DB7, DB6, DB5, DB4 // these outputs will be sent over to the LCD, check constraints later
    output reg [3:0] data_bits // idw to individually assign anymore
    );
    
    //reg RS_init, E_init;
//    reg [3:0] data_bits;
    
//    assign DB7 = data_bits[3];
//    assign DB6 = data_bits[2];
//    assign DB5 = data_bits[1];
//    assign DB4 = data_bits[0];
//    assign RS = RS_init;
//    assign E = E_init;
    
//    parameter count_15ms = 1_500_000; // these are the wait times for the init set up
//    parameter count_4_1ms = 410_000;
//    parameter count_100us = 10_000;
    
//    parameter count_15_2ms = 1_520_000; // these are the max wait times for the different functions
//    parameter count_40us = 40_000;
//    // i gave up tracking this, im gonan hard code the counts
    
    // so depending on the series of condtions, we output certain stuff 
    reg [27:0] counter;
    reg [27:0] E_count; // separate counter for enable and the rest of the logic (this was also another issue)
    // issue I had with this was that the Enable and Commands (data_bits) cannot be outputted at the same time due to non-idealities 
    // I should check out the timing diagram properly next time - no need to be accurate with the numbers since its better if it is a bit over
    // advice given (ty sir allen): there is just one part where there is a max, but everything else has a minimum. recall that there is a slope in actual application
    reg done; // done signal needed to know if the initialization is complete
    // Initialization logic
    always @(posedge clk or negedge nrst) begin
        if (!nrst) begin
            // Reset all outputs and counters
            data_bits <= 4'b0000;
            RS_init <= 1'b0;
//            rw <= 1'b0;
            E_init <= 1'b0;
            counter <= 28'b0000000000000000000000000000;
            done <= 1'b0;
            E_count <= 28'b0000000000000000000000000000;
            
        // BEGIN INITIALIZATION
        end else begin          
            if (!done) begin
                if (counter < 10_000_000) begin                                                                 // WAIT MORE THAN 15MS
                    // Wait for 100 ms after power-on
                    counter = counter + 1;
                    E_count = 0;
                    RS_init = 1'b0;
                    
                end 
                
                else if (counter >= 10_000_000) begin
                    if (E_count < 20000) begin        //wait 200us before 1st E_init
                        data_bits = 4'b0011;
                    end 

                    else if (E_count < 100000) begin    // on E_init for 1ms                      // PULSE EN SIGNAL
                        E_init = 1'b1;
                    end

                    else if (E_count < 100000 + 600000) begin    // off E_init for 6ms               // WAIT MORE THAN 4.1MS
                        E_init = 1'b0;
                    end

                    else if (E_count < 100000 + 600000 + 100000) begin    // turn it ON again after 1ms                      
                        E_init = 1'b1;                                                                                    
                    end

                    else if (E_count < 100000 + 600000 + 100000 + 100000) begin    // turn it OFF for 1ms          // WAIT FOR MORE THAN 100us       
                        E_init = 1'b0;
                    end

                    else if (E_count < 100000 + 600000 + 100000 + 100000 + 100000) begin   // on E_init for 1ms                          
                        E_init = 1'b1;                                                                                
                    end

                    else if (E_count < 100000 + 600000 + 100000 + 100000 + 100000 + 120000) begin    // turn it OFF for 1.2ms           
                        E_init = 1'b0;
                    end


                    // FUNCTION SET (SET INTERFACE TO 4-BIT -- SET N and F)
                    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    else if (E_count < 1_120_000 + 20_000) begin    // SEND 0010 after 200 us          
                        data_bits = 4'b0010;
                    end

                    else if (E_count < 1120000 + 20000 + 50000) begin    //wait 100ns before triggering the EN signal                          // PULSE EN SIGNAL
                        E_init = 1'b1;
                    end

                    else if (E_count < 1120000 + 20000 + 50000 + 50000) begin    // turn ON EN signal for 1ms before turning it off       
                        E_init = 1'b0;
                    end
                    
                    else if (E_count < 1120000 + 20000 + 50000 + 50000 + 50000) begin    //wait 100ns before triggering the EN signal                          // PULSE EN SIGNAL
                        E_init = 1'b1;
                    end

                    else if (E_count < 1120000 + 20000 + 50000 + 50000 + 50000 + 50000) begin    // turn ON EN signal for 1ms before turning it off       
                        E_init = 1'b0;
                    end


                    else if (E_count < 1120000 + 20000 + 100000 + 100000 + 20000) begin    // SEND 1000 after 200us   (NFxx = 1000)      
                        data_bits = 4'b1000;
                    end

                    else if (E_count < 1120000 + 20000 + 100000 + 100000 + 20000 + 100000) begin   //wait 100ns before triggering the EN signal       // PULSE EN SIGNAL     
                        E_init = 1'b1;
                    end

                    else if (E_count < 1120000 + 20000 + 100000 + 100000 + 20000 + 100000 + 100000) begin   // turn ON EN signal for 1ms before turning it off     
                        E_init = 1'b0;
                    end
                    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -



                    // DISPLAY OFF
                    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    else if (E_count < 1560000 + 20000) begin    // SEND 0000 after 200us       
                        data_bits = 4'b0000;
                    end

                    else if (E_count < 1560000 + 20000 + 100000) begin   //wait 100ns before triggering the EN signal       // PULSE EN SIGNAL     
                        E_init = 1'b1;
                    end

                    else if (E_count < 1560000 + 20000 + 100000 + 100000) begin   // turn ON EN signal for 1ms before turning it off     
                        E_init = 1'b0;
                    end

                    else if (E_count < 1560000 + 20000 + 100000 + 100000 + 20000) begin    // SEND 1000 after 200us    
                        data_bits = 4'b1000;
                    end

                    else if (E_count < 1560000 + 20000 + 100000 + 100000 + 20000 + 100000) begin   //wait 100ns before triggering the EN signal       // PULSE EN SIGNAL     
                        E_init = 1'b1;
                    end

                    else if (E_count < 1560000 + 20000 + 100000 + 100000 + 20000 + 100000 + 100000) begin   // turn ON EN signal for 1ms before turning it off     
                        E_init = 1'b0;
                    end
                    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -



                    // CLEAR DISPLAY
                    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    else if (E_count < 2000000 + 2000000) begin    // SEND 0000 after 20ms       
                        data_bits = 4'b0000;
                    end

                    else if (E_count < 2000000 + 2000000 + 100000) begin   //wait 100ns before triggering the EN signal       // PULSE EN SIGNAL     
                        E_init = 1'b1;
                    end

                    else if (E_count < 2000000 + 2000000 + 100000 + 100000) begin   // turn ON EN signal for 1ms before turning it off     
                        E_init = 1'b0;
                    end

                    else if (E_count < 2000000 + 2000000 + 100000 + 100000 + 2000000) begin    // SEND 0001 after 20ms    
                        data_bits = 4'b0001;
                    end

                    else if (E_count < 2000000 + 2000000 + 100000 + 100000 + 2000000 + 100000) begin   //wait 100ns before triggering the EN signal       // PULSE EN SIGNAL     
                        E_init = 1'b1;
                    end

                    else if (E_count < 2000000 + 2000000 + 100000 + 100000 + 2000000 + 100000 + 100000) begin   // turn ON EN signal for 1ms before turning it off     
                        E_init = 1'b0;
                    end
                    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -





                    // ENTRY MODE SET
                    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    else if (E_count < 6_400_000 + 2000000) begin    // SEND 0000 after 20ms       
                        data_bits = 4'b0000;
                    end

                    else if (E_count < 6400000 + 2000000 + 100000) begin   //wait 100ns before triggering the EN signal       // PULSE EN SIGNAL     
                        E_init = 1'b1;
                    end

                    else if (E_count < 6400000 + 2000000 + 100000 + 100000) begin   // turn ON EN signal for 1ms before turning it off     
                        E_init = 1'b0;
                    end

                    else if (E_count < 6400000 + 2000000 + 100000 + 100000 + 2000000) begin    // SEND 0111 after 20ms    (0  1  I/D  S)
                        data_bits = 4'b0110;
                    end

                    else if (E_count < 6400000 + 2000000 + 100000 + 100000 + 2000000 + 100000) begin   //wait 100ns before triggering the EN signal       // PULSE EN SIGNAL     
                        E_init = 1'b1;
                    end

                    else if (E_count < 6400000 + 2000000 + 100000 + 100000 + 2000000 + 100000 + 100000) begin   // turn ON EN signal for 1ms before turning it off     
                        E_init = 1'b0;
                    end
                    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -



                    // DISPLAY ON
                    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    else if (E_count < 10800000 + 20000) begin    // SEND 0000 after 200us       
                        data_bits = 4'b0000;
                    end

                    else if (E_count < 10800000 + 20000 + 100000) begin   //wait 100ns before triggering the EN signal       // PULSE EN SIGNAL     
                        E_init = 1'b1;
                    end

                    else if (E_count < 10800000 + 20000 + 100000 + 100000) begin   // turn ON EN signal for 1ms before turning it off     
                        E_init = 1'b0;
                    end

                    else if (E_count < 10800000 + 20000 + 100000 + 100000 + 20000) begin    // SEND 1111 after 200us    (1  1  C  B) 1111_0100_1110_0100
                        data_bits = 4'b1110;
                    end

                    else if (E_count < 10800000 + 20000 + 100000 + 100000 + 20000 + 100000) begin   //wait 100ns before triggering the EN signal       // PULSE EN SIGNAL     
                        E_init = 1'b1;
                    end

                    else if (E_count < 10800000 + 20000 + 100000 + 100000 + 20000 + 100000 + 80000) begin   // turn ON EN signal for 1ms before turning it off     
                        E_init = 1'b0;
                    end
                    else if (E_count < 10800000 + 20000 + 100000 + 100000 + 20000 + 100000 + 80000 + 20000) begin   // turn ON EN signal for 1ms before turning it off     
                        RS_init = 1'b1;
                        //counter = 0;
                        //E_count = 0;
                        //init_done = 1;
                    end
                    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                
                //////////////////////////////////////////////////////////////////////////////////////////////////////////////
                
                // NEXT THING TO DO IS TO HAVE COLOR MODE ON TOP
                // LETTER C, SEND UPPER THEN LOWER BITS (has to overlap a bit with the previous)
                else if (E_count < 10_800_000 + 20_000 + 100_000 + 100_000 + 20_000 + 100_000 + 100_000 + 20_000) data_bits <= 4'b0100; // UPPER HALF FIRST
                else if (E_count < 10_800_000 + 20_000 + 100_000 + 100_000 + 20_000 + 100_000 + 100_000 + 20_000 + 100_000) E_init <= 1;
                else if (E_count < 10_800_000 + 20_000 + 100_000 + 100_000 + 20_000 + 100_000 + 100_000 + 20_000 + 100_000 + 100_000) E_init <= 0;
                else if (E_count < 10_800_000 + 20_000 + 100_000 + 100_000 + 20_000 + 100_000 + 100_000 + 20_000 + 100_000 + 100_000 + 100_000) data_bits <= 4'b0011; // LOWER HALF NEXT
                else if (E_count < 11_240_000 + 20_000 + 100_000 + 100_000 + 20_000 + 100_000) E_init <= 1;
                else if (E_count < 11_240_000 + 20_000 + 100_000 + 100_000 + 20_000 + 100_000 + 100_000) E_init <= 0;
                
                // LETTER o
                else if (E_count < 11_680_000 + 20_000) data_bits <= 4'b0110; // UPPER HALF FIRST
                else if (E_count < 11_680_000 + 20_000 + 100_000) E_init <= 1;
                else if (E_count < 11_680_000 + 20_000 + 100_000 + 100_000) E_init <= 0;
                else if (E_count < 11_680_000 + 20_000 + 100_000 + 100_000 + 20_000) data_bits <= 4'b1111; // LOWER HALF NEXT
                else if (E_count < 11_680_000 + 20_000 + 100_000 + 100_000 + 20_000 + 100_000) E_init <= 1;
                else if (E_count < 11_680_000 + 20_000 + 100_000 + 100_000 + 20_000 + 100_000 + 100_000) E_init <= 0;
                
                // LETTER l
                else if (E_count < 12_120_000 + 20_000) data_bits <= 4'b0110; // UPPER HALF FIRST
                else if (E_count < 12_120_000 + 20_000 + 100_000) E_init <= 1;
                else if (E_count < 12_120_000 + 20_000 + 100_000 + 100_000) E_init <= 0;
                else if (E_count < 12_120_000 + 20_000 + 100_000 + 100_000 + 20_000) data_bits <= 4'b1100; // LOWER HALF NEXT
                else if (E_count < 12_120_000 + 20_000 + 100_000 + 100_000 + 20_000 + 100_000) E_init <= 1;
                else if (E_count < 12_120_000 + 20_000 + 100_000 + 100_000 + 20_000 + 100_000 + 100_000) E_init <= 0;
                
                // LETTER o
                else if (E_count < 12_560_000 + 20_000) data_bits <= 4'b0110; // UPPER HALF FIRST
                else if (E_count < 12_560_000 + 20_000 + 100_000) E_init <= 1;
                else if (E_count < 12_560_000 + 20_000 + 100_000 + 100_000) E_init <= 0;
                else if (E_count < 12_560_000 + 20_000 + 100_000 + 100_000 + 20_000) data_bits <= 4'b1111; // LOWER HALF NEXT
                else if (E_count < 12_560_000 + 20_000 + 100_000 + 100_000 + 20_000 + 100_000) E_init <= 1;
                else if (E_count < 12_560_000 + 20_000 + 100_000 + 100_000 + 20_000 + 100_000 + 100_000) E_init <= 0;
                
                // LETTER r LAST LETTER FOR Color
                else if (E_count < 13_000_000 + 20_000) data_bits <= 4'b0111; // UPPER HALF FIRST
                else if (E_count < 13_000_000 + 20_000 + 100_000) E_init <= 1;
                else if (E_count < 13_000_000 + 20_000 + 100_000 + 100_000) E_init <= 0;
                else if (E_count < 13_000_000 + 20_000 + 100_000 + 100_000 + 20_000) data_bits <= 4'b0010; // LOWER HALF NEXT
                else if (E_count < 13_000_000 + 20_000 + 100_000 + 100_000 + 20_000 + 100_000) E_init <= 1;
                else if (E_count < 13_000_000 + 20_000 + 100_000 + 100_000 + 20_000 + 100_000 + 100_000) E_init <= 0;
                
                // (space) portion
                // CURRENT ACCUMULATE: 13_440_000
                else if (E_count < 13_440_000 + 20_000) data_bits <= 4'b0010; // UPPER HALF FIRST
                else if (E_count < 13_440_000 + 20_000 + 100_000) E_init <= 1;
                else if (E_count < 13_440_000 + 20_000 + 100_000 + 100_000) E_init <= 0;
                else if (E_count < 13_440_000 + 20_000 + 100_000 + 100_000 + 20_000) data_bits <= 4'b0000; // LOWER HALF NEXT
                else if (E_count < 13_440_000 + 20_000 + 100_000 + 100_000 + 20_000 + 100_000) E_init <= 1;
                else if (E_count < 13_440_000 + 20_000 + 100_000 + 100_000 + 20_000 + 100_000 + 100_000) E_init <= 0;
                
                // M portion
                // current accumulate: 13_880_000
                else if (E_count < 13_880_000 + 20_000) data_bits <= 4'b0100; // UPPER HALF FIRST 
                else if (E_count < 13_880_000 + 20_000 + 100_000) E_init <= 1;
                else if (E_count < 13_880_000 + 20_000 + 100_000 + 100_000) E_init <= 0;
                else if (E_count < 13_880_000 + 20_000 + 100_000 + 100_000 + 20_000) data_bits <= 4'b1101; // LOWER HALF NEXT
                else if (E_count < 13_880_000 + 20_000 + 100_000 + 100_000 + 20_000 + 100_000) E_init <= 1;
                else if (E_count < 13_880_000 + 20_000 + 100_000 + 100_000 + 20_000 + 100_000 + 100_000) E_init <= 0;
                
                // o portion
                // current accumulate: 14_320_000
                else if (E_count < 14_320_000 + 20_000) data_bits <= 4'b0110; // UPPER HALF FIRST
                else if (E_count < 14_320_000 + 20_000 + 100_000) E_init <= 1;
                else if (E_count < 14_320_000 + 20_000 + 100_000 + 100_000) E_init <= 0;
                else if (E_count < 14_320_000 + 20_000 + 100_000 + 100_000 + 20_000) data_bits <= 4'b1111; // LOWER HALF NEXT
                else if (E_count < 14_320_000 + 20_000 + 100_000 + 100_000 + 20_000 + 100_000) E_init <= 1;
                else if (E_count < 14_320_000 + 20_000 + 100_000 + 100_000 + 20_000 + 100_000 + 100_000) E_init <= 0;
                
                // d portion
                // current accumulate: 14_760_000
                else if (E_count < 14_760_000 + 20_000) data_bits <= 4'b0110; // UPPER HALF FIRST
                else if (E_count < 14_760_000 + 20_000 + 100_000) E_init <= 1;
                else if (E_count < 14_760_000 + 20_000 + 100_000 + 100_000) E_init <= 0;
                else if (E_count < 14_760_000 + 20_000 + 100_000 + 100_000 + 20_000) data_bits <= 4'b0100; // LOWER HALF NEXT
                else if (E_count < 14_760_000 + 20_000 + 100_000 + 100_000 + 20_000 + 100_000) E_init <= 1;
                else if (E_count < 14_760_000 + 20_000 + 100_000 + 100_000 + 20_000 + 100_000 + 100_000) E_init <= 0;
                
                // e portion. Last for the Mode print. rs should be 0 here / at least called
                // current accumulate: 15_200_000
                else if (E_count < 15_200_000 + 20_000) data_bits <= 4'b0110; // UPPER HALF FIRST
                else if (E_count < 15_200_000 + 20_000 + 100_000) E_init <= 1;
                else if (E_count < 15_200_000 + 20_000 + 100_000 + 100_000) E_init <= 0;
                else if (E_count < 15_200_000 + 20_000 + 100_000 + 100_000 + 20_000) data_bits <= 4'b0101; // LOWER HALF NEXT
                else if (E_count < 15_200_000 + 20_000 + 100_000 + 100_000 + 20_000 + 100_000) E_init <= 1;
                else if (E_count < 15_200_000 + 20_000 + 100_000 + 100_000 + 20_000 + 100_000 + 80_000) E_init <= 0;
                else if (E_count < 15_200_000 + 20_000 + 100_000 + 100_000 + 20_000 + 100_000 + 80_000 + 20_000) RS_init <= 0;
                
                // FIRST LINE OF WRITES COMPLETE (Color Mode), PROCEED TO PREPARING THE SECOND LINE TO WRITE TYPE MODE
                ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                // MOVE TO THE SECOND LINE
                // current accumulate: 15_640_000
                else if (E_count < 15_640_000 + 20_000) data_bits <= 4'b1100; // UPPER HALF FIRST
                else if (E_count < 15_640_000 + 20_000 + 100_000) E_init <= 1;
                else if (E_count < 15_640_000 + 20_000 + 100_000 + 100_000) E_init <= 0;
                else if (E_count < 15_640_000 + 20_000 + 100_000 + 100_000 + 20_000) data_bits <= 4'b0000; // LOWER HALF NEXT
                else if (E_count < 15_640_000 + 20_000 + 100_000 + 100_000 + 20_000 + 100_000) E_init <= 1;
                else if (E_count < 15_640_000 + 20_000 + 100_000 + 100_000 + 20_000 + 100_000 + 80_000) E_init <= 0;
                else if (E_count < 15_640_000 + 20_000 + 100_000 + 100_000 + 20_000 + 100_000 + 80_000 + 20_000) RS_init <= 1; // YAASSSS ENABLED NA SIYA
                
                ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                
                // Type Mode, second line
                // current accumulate: 16_080_000
                // LETTER T
                else if (E_count < 16_080_000 + 20_000) data_bits <= 4'b0101; // UPPER HALF FIRST
                else if (E_count < 16_080_000 + 20_000 + 100_000) E_init <= 1;
                else if (E_count < 16_080_000 + 20_000 + 100_000 + 100_000) E_init <= 0;
                else if (E_count < 16_080_000 + 20_000 + 100_000 + 100_000 + 20_000) data_bits <= 4'b0100; // LOWER HALF NEXT
                else if (E_count < 16_080_000 + 20_000 + 100_000 + 100_000 + 20_000 + 100_000) E_init <= 1;
                else if (E_count < 16_080_000 + 20_000 + 100_000 + 100_000 + 20_000 + 100_000 + 100_000) E_init <= 0;
                
                // Letter y
                // current accumulate: 16_520_000
                else if (E_count < 16_520_000 + 20_000) data_bits <= 4'b0111; // UPPER HALF FIRST
                else if (E_count < 16_520_000 + 20_000 + 100_000) E_init <= 1;
                else if (E_count < 16_520_000 + 20_000 + 100_000 + 100_000) E_init <= 0;
                else if (E_count < 16_520_000 + 20_000 + 100_000 + 100_000 + 20_000) data_bits <= 4'b1001; // LOWER HALF NEXT
                else if (E_count < 16_520_000 + 20_000 + 100_000 + 100_000 + 20_000 + 100_000) E_init <= 1;
                else if (E_count < 16_520_000 + 20_000 + 100_000 + 100_000 + 20_000 + 100_000 + 100_000) E_init <= 0;
                
                // Letter p
                // current accumulate: 16_960_000
                else if (E_count < 16_960_000 + 20_000) data_bits <= 4'b0111; // UPPER HALF FIRST
                else if (E_count < 16_960_000 + 20_000 + 100_000) E_init <= 1;
                else if (E_count < 16_960_000 + 20_000 + 100_000 + 100_000) E_init <= 0;
                else if (E_count < 16_960_000 + 20_000 + 100_000 + 100_000 + 20_000) data_bits <= 4'b0000; // LOWER HALF NEXT
                else if (E_count < 16_960_000 + 20_000 + 100_000 + 100_000 + 20_000 + 100_000) E_init <= 1;
                else if (E_count < 16_960_000 + 20_000 + 100_000 + 100_000 + 20_000 + 100_000 + 100_000) E_init <= 0;
                
                // letter e
                // current accumulate: 17_400_000
                else if (E_count < 17_400_000 + 20_000) data_bits <= 4'b0110; // UPPER HALF FIRST
                else if (E_count < 17_400_000 + 20_000 + 100_000) E_init <= 1;
                else if (E_count < 17_400_000 + 20_000 + 100_000 + 100_000) E_init <= 0;
                else if (E_count < 17_400_000 + 20_000 + 100_000 + 100_000 + 20_000) data_bits <= 4'b0101; // LOWER HALF NEXT
                else if (E_count < 17_400_000 + 20_000 + 100_000 + 100_000 + 20_000 + 100_000) E_init <= 1;
                else if (E_count < 17_400_000 + 20_000 + 100_000 + 100_000 + 20_000 + 100_000 + 100_000) E_init <= 0;
                
                // (space) portion
                // CURRENT ACCUMULATE: 17_840_000
                else if (E_count < 17_840_000 + 20_000) data_bits <= 4'b0010; // UPPER HALF FIRST
                else if (E_count < 17_840_000 + 20_000 + 100_000) E_init <= 1;
                else if (E_count < 17_840_000 + 20_000 + 100_000 + 100_000) E_init <= 0;
                else if (E_count < 17_840_000 + 20_000 + 100_000 + 100_000 + 20_000) data_bits <= 4'b0000; // LOWER HALF NEXT
                else if (E_count < 17_840_000 + 20_000 + 100_000 + 100_000 + 20_000 + 100_000) E_init <= 1;
                else if (E_count < 17_840_000 + 20_000 + 100_000 + 100_000 + 20_000 + 100_000 + 100_000) E_init <= 0;
                
                // Type print complete for Type Mode
                
                // Letter M
                // current accumulate: 18_280_000
                else if (E_count < 18_280_000 + 20_000) data_bits <= 4'b0100; // UPPER HALF FIRST
                else if (E_count < 18_280_000 + 20_000 + 100_000) E_init <= 1;
                else if (E_count < 18_280_000 + 20_000 + 100_000 + 100_000) E_init <= 0;
                else if (E_count < 18_280_000 + 20_000 + 100_000 + 100_000 + 20_000) data_bits <= 4'b1101; // LOWER HALF NEXT
                else if (E_count < 18_280_000 + 20_000 + 100_000 + 100_000 + 20_000 + 100_000) E_init <= 1;
                else if (E_count < 18_280_000 + 20_000 + 100_000 + 100_000 + 20_000 + 100_000 + 100_000) E_init <= 0;
                
                // letter o
                // current accumulate: 18_720_000
                else if (E_count < 18_720_000 + 20_000) data_bits = 4'b0110; // UPPER HALF FIRST
                else if (E_count < 18_720_000 + 20_000 + 100_000) E_init = 1;
                else if (E_count < 18_720_000 + 20_000 + 100_000 + 100_000) E_init <= 0;
                else if (E_count < 18_720_000 + 20_000 + 100_000 + 100_000 + 20_000) data_bits <= 4'b1111; // LOWER HALF NEXT
                else if (E_count < 18_720_000 + 20_000 + 100_000 + 100_000 + 20_000 + 100_000) E_init <= 1;
                else if (E_count < 18_720_000 + 20_000 + 100_000 + 100_000 + 20_000 + 100_000 + 100_000) E_init <= 0;
                
                // letter d
                // current accumulate: 19_160_000
                else if (E_count < 19_160_000 + 20_000) data_bits <= 4'b0110; // UPPER HALF FIRST
                else if (E_count < 19_160_000 + 20_000 + 100_000) E_init <= 1;
                else if (E_count < 19_160_000 + 20_000 + 100_000 + 100_000) E_init <= 0;
                else if (E_count < 19_160_000 + 20_000 + 100_000 + 100_000 + 20_000) data_bits <= 4'b0100; // LOWER HALF NEXT
                else if (E_count < 19_160_000 + 20_000 + 100_000 + 100_000 + 20_000 + 100_000) E_init <= 1;
                else if (E_count < 19_160_000 + 20_000 + 100_000 + 100_000 + 20_000 + 100_000 + 100_000) E_init <= 0;
                
                // letter e
                // current accumulate: 19_600_000
                else if (E_count < 19_600_000 + 20_000) data_bits = 4'b0110; // UPPER HALF FIRST
                else if (E_count < 19_600_000 + 20_000 + 100_000) E_init = 1;
                else if (E_count < 19_600_000 + 20_000 + 100_000 + 100_000) E_init = 0;
                else if (E_count < 19_600_000 + 20_000 + 100_000 + 100_000 + 20_000) data_bits <= 4'b0101; // LOWER HALF NEXT
                else if (E_count < 19_600_000 + 20_000 + 100_000 + 100_000 + 20_000 + 100_000) E_init = 1;
                else if (E_count < 19_600_000 + 20_000 + 100_000 + 100_000 + 20_000 + 100_000 + 100_000) E_init = 0;
                
                else begin
                    E_init = 0;
                    counter = 0;
                    data_bits = 4'b0000;
                    done = 1;
                    RS_init = 0;
                end
                E_count = E_count +1;
                counter = counter + 1; // check if this line works and fixes
                end
            end
        end
    end
endmodule
marie.v
31 KB
