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
module send_4bit_nibble_2(
    input clk, nrst,
    output RS, E,
    output DB7, DB6, DB5, DB4 // these outputs will be sent over to the LCD, check constraints later
    );
    
    reg RS_init, E_init;
    reg [3:0] data_bits;
    assign DB7 = data_bits[3];
    assign DB6 = data_bits[2];
    assign DB5 = data_bits[1];
    assign DB4 = data_bits[0];
    assign RS = RS_init;
    assign E = E_init;
    
//    parameter count_15ms = 1_500_000; // these are the wait times for the init set up
//    parameter count_4_1ms = 410_000;
//    parameter count_100us = 10_000;
    
//    parameter count_15_2ms = 1_520_000; // these are the max wait times for the different functions
//    parameter count_40us = 40_000;
//    // i gave up tracking this, im gonan hard code the counts
    
    // so depending on the series of condtions, we output certain stuff 
    reg [30:0] counter;
    reg [30:0] E_count; // separate counter for enable and the rest of the logic (this was also another issue)
    // issue I had with this was that the Enable and Commands (data_bits) cannot be outputted at the same time due to non-idealities 
    // I should check out the timing diagram properly next time - no need to be accurate with the numbers since its better if it is a bit over
    // advice given (ty sir allen): there is just one part where there is a max, but everything else has a minimum. recall that there is a slope in actual application
    reg done; // done signal needed to know if the initialization is complete
    always@(posedge clk or negedge nrst)begin
        if(!nrst) begin
            RS_init <= 0;
            //RW_init <= 0;
            E_init <= 0;
            data_bits <= 4'b0000;
            done <= 0;
            counter <= 0;
            E_count <= 0;
        end else begin
            if(!done) begin // if not done, or if done == 0 
                if(counter < 10_000_000) begin // wait 100 ms, do not start counting immediately (i think this was the start up problem before)
                    counter <= counter + 1; // implement an increment instead of a decrement counter (easier to keep track of stuff increaseing that decreasing kasi)
                    E_count <= 0;
                    RS_init <= 0; // call everything we need for this process
                end else begin
                    done <= 1;
                    E_count <= 0;
                end
            end
            else if (counter >= 10_000_000) begin
                //counter = counter + 1; we actually dont need this since the rest of the code is E_count
               //  E_count = E_count + 1; move down
                // Note: that the timing parameters are now not exactly the same as the previous attempts because of the non-idealities in timing diagrams
                // now this is where we start the sending out of the data bits and the enable pulse bits (with proper timing)
                if(E_count < 20_000) data_bits <= 4'b0011; // send data bits | no need to actually reset it back to 0 since it need to pulse only
                else if (E_count < 100_000) E_init <= 1; // pulse high
                else if (E_count < 100_000 + 600_000) E_init <= 0; // pulse low
                // repeat this pattern for the rest of the hard coding
                else if (E_count < 100_000 + 600_000 + 100_000) E_init <= 1;  // do it again
                else if (E_count < 100_000 + 600_000 + 100_000 + 100_000) E_init <= 0; 
                else if (E_count < 100_000 + 600_000 + 100_000 + 100_000 + 100_000) E_init <= 1;
                else if (E_count < 100_000 + 600_000 + 100_000 + 100_000 + 100_000 + 100_000 + 120_000) E_init <= 0;
                // so, we are adding around 100_000 to the count if we are enabling bits
                // first round of sending bits, complete
                
                // count accumulated: 100_000 + 600_000 + 100_000 + 100_000 + 100_000 + 100_000 + 20_000 = 1_120_000 | use so that its easier
                // the FUNCTION SET portion that lets our 8-bit become a 4-bit thingy (N and F bits are set here)
                else if (E_count < 1_120_000 + 20_000) data_bits <= 4'b0010; 
                else if (E_count < 1_120_000 + 20_000 + 50_000) E_init <= 1;
                else if (E_count < 1_120_000 + 20_000 + 50_000 + 50_000) E_init <= 0; // similar to previous iteration with the states, split enable 
                else if (E_count < 1_120_000 + 20_000 + 50_000 + 50_000 + 50_000) E_init <= 1;
                else if (E_count < 1_120_000 + 20_000 + 50_000 + 50_000 + 50_000 + 50_000) E_init <= 0; // then one more
                
                else if (E_count < 1_120_000 + 20_000 + 100_000 + 100_000 + 20_000) data_bits <= 4'b1000;
                else if (E_count < 1_120_000 + 20_000 + 100_000 + 100_000 + 20_000 + 100_000) E_init <= 1;
                else if (E_count < 1_120_000 + 20_000 + 100_000 + 100_000 + 20_000 + 100_000 + 100_000) E_init <= 0;
                
                // function set complete. continue to DISPLAY OFF:
                else if(E_count < 1_560_000 + 20_000) data_bits <= 4'b0000;
                else if(E_count < 1_560_000 + 20_000 + 100_000) E_init <= 1;
                else if(E_count < 1_560_000 + 20_000 + 100_000 + 100_000) E_init <= 0;
                else if(E_count < 1_560_000 + 20_000 + 100_000 + 100_000 + 20_000) data_bits <= 4'b1000;
                else if(E_count < 1_560_000 + 20_000 + 100_000 + 100_000 + 20_000 + 100_000) E_init <= 1; 
                else if(E_count < 1_560_000 + 20_000 + 100_000 + 100_000 + 20_000 + 100_000 + 100_000) E_init <= 0;
                
                // display off complete, continue to clear display
                // count accumulate; 2_000_000
                else if (E_count < 2_000_000 + 2_000_000) data_bits <= 4'b0000;
                else if (E_count < 2_000_000 + 2_000_000 + 100_000) E_init <= 1;
                else if (E_count < 2_000_000 + 2_000_000 + 100_000 + 100_000) E_init <= 0;
                else if (E_count < 2_000_000 + 2_000_000 + 100_000 + 100_000 + 2_000_000) data_bits  <= 4'b0001;
                else if (E_count < 2_000_000 + 2_000_000 + 100_000 + 100_000 + 2_000_000 + 100_000) E_init <= 1;
                else if (E_count < 2_000_000 + 2_000_000 + 100_000 + 100_000 + 2_000_000 + 100_000 + 100_000) E_init <= 0;
                
                // clear display function complete, proceed with entry mode
                // count accumulate : 6_400_000
                else if (E_count < 6_400_000 + 2_000_000) data_bits <= 4'b0000;
                else if (E_count < 6_400_000 + 2_000_000 + 100_000) E_init <= 1;
                else if (E_count < 6_400_000 + 2_000_000 + 100_000 + 100_000) E_init <= 0;
                else if (E_count < 6_400_000 + 2_000_000 + 100_000 + 100_000 + 2_000_000) data_bits <= 4'b0110;
                else if (E_count < 6_400_000 + 2_000_000 + 100_000 + 100_000 + 2_000_000 + 100_000) E_init <= 1;
                else if (E_count < 6_400_000 + 2_000_000 + 100_000 + 100_000 + 2_000_000 + 100_000 + 100_000) E_init <= 0;
                
                // entry mode complete, proceed with display on
                // count accumulate: 10_800_000
                else if (E_count < 10_800_000 + 20_000) data_bits <= 4'b0000;
                else if (E_count < 10_800_000 + 20_000 + 100_000) E_init <= 1;
                else if (E_count < 10_800_000 + 20_000 + 100_000 + 100_000) E_init <= 0;
                else if (E_count < 10_800_000 + 20_000 + 100_000 + 100_000 + 20_000) data_bits <= 4'b1111;
                else if (E_count < 10_800_000 + 20_000 + 100_000 + 100_000 + 20_000 + 100_000) E_init <= 1;
                else if (E_count < 10_800_000 + 20_000 + 100_000 + 100_000 + 20_000 + 100_000 + 80_000) E_init <= 0; // split E_init time and RS (kinda)
                else if (E_count < 10_800_000 + 20_000 + 100_000 + 100_000 + 20_000 + 100_000 + 80_000 + 20_000) RS_init <= 1; // YASSSS FINALLY INITIALIZATION COMPLETE
                
                //////////////////////////////////////////////////////////////////////////////////////////////////////////////
                
                // NEXT THING TO DO IS TO HAVE COLOR MODE ON TOP
                // LETTER C, SEND UPPER THEN LOWER BITS (has to overlap a bit with the previous)
                else if (E_count < 10_800_000 + 20_000 + 100_000 + 100_000 + 20_000 + 100_000 + 100_000 + 20_000) data_bits <= 4'b0100; // UPPER HALF FIRST
                else if (E_count < 10_800_000 + 20_000 + 100_000 + 100_000 + 20_000 + 100_000 + 100_000 + 20_000 + 100_000) E_init <= 1;
                else if (E_count < 10_800_000 + 20_000 + 100_000 + 100_000 + 20_000 + 100_000 + 100_000 + 20_000 + 100_000 + 100_000) E_init <= 0;
                else if (E_count < 10_800_000 + 20_000 + 100_000 + 100_000 + 20_000 + 100_000 + 100_000 + 20_000 + 100_000 + 100_000) data_bits <= 4'b0011; // LOWER HALF NEXT
                else if (E_count < 11_240_000 + 20_000 + 100_000 + 100_000 + 20_000 + 100_000) E_init <= 1;
                else if (E_count < 11_240_000 + 20_000 + 100_000 + 100_000 + 20_000 + 100_000 + 100_000) E_init <= 0;
                
                // LETTER o
                else if (E_count < 11_680_000 + 20_000) data_bits <= 4'b0100; // UPPER HALF FIRST
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
                else if (E_count < 12_560_000 + 20_000) data_bits <= 4'b0100; // UPPER HALF FIRST
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
                else if (E_count < 13_440_000 + 20_000) data_bits <= 4'b0000; // UPPER HALF FIRST
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
                else if (E_count < 13_880_000 + 20_000 + 100_000 + 100_000 + 20_000) data_bits <= 4'b0110; // LOWER HALF NEXT
                else if (E_count < 13_880_000 + 20_000 + 100_000 + 100_000 + 20_000 + 100_000) E_init <= 1;
                else if (E_count < 13_880_000 + 20_000 + 100_000 + 100_000 + 20_000 + 100_000 + 100_000) E_init <= 0;
                
                // o portion
                // current accumulate: 14_320_000
                else if (E_count < 14_320_000 + 20_000) data_bits <= 4'b0100; // UPPER HALF FIRST
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
                else if (E_count < 17_840_000 + 20_000) data_bits <= 4'b0000; // UPPER HALF FIRST
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
                else if (E_count < 18_280_000 + 20_000 + 100_000 + 100_000 + 20_000) data_bits <= 4'b0110; // LOWER HALF NEXT
                else if (E_count < 18_280_000 + 20_000 + 100_000 + 100_000 + 20_000 + 100_000) E_init <= 1;
                else if (E_count < 18_280_000 + 20_000 + 100_000 + 100_000 + 20_000 + 100_000 + 100_000) E_init <= 0;
                
                // letter o
                // current accumulate: 18_720_000
                else if (E_count < 18_720_000 + 20_000) data_bits <= 4'b0100; // UPPER HALF FIRST
                else if (E_count < 18_720_000 + 20_000 + 100_000) E_init <= 1;
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
                else if (E_count < 19_600_000 + 20_000) data_bits <= 4'b0110; // UPPER HALF FIRST
                else if (E_count < 19_600_000 + 20_000 + 100_000) E_init <= 1;
                else if (E_count < 19_600_000 + 20_000 + 100_000 + 100_000) E_init <= 0;
                else if (E_count < 19_600_000 + 20_000 + 100_000 + 100_000 + 20_000) data_bits <= 4'b0101; // LOWER HALF NEXT
                else if (E_count < 19_600_000 + 20_000 + 100_000 + 100_000 + 20_000 + 100_000) E_init <= 1;
                else if (E_count < 19_600_000 + 20_000 + 100_000 + 100_000 + 20_000 + 100_000 + 100_000) E_init <= 0;
                
                else begin
                    E_init <= 0;
                    counter <= 0;
                    data_bits <= 4'b0000;
                    done <= 1;
                    RS_init <= 0;
                end
                E_count <= E_count +1;             
            end
        end
    end
endmodule
