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
module send_4bit_nibble(
    input clk, nrst,
    output reg RS_init_out, RW_init_out, enable,
    output reg DB7_init_out, DB6_init_out, DB5_init_out, DB4_init_out // these outputs will be sent over to the LCD, check constraints later
    );
    
    parameter count_15ms = 1_500_000; // these are the wait times for the init set up
    parameter count_4_1ms = 410_000;
    parameter count_100us = 10_000;
    
    parameter count_15_2ms = 1_520_000; // these are the max wait times for the different functions
    parameter count_40us = 40_000;
    
    // so depending on the series of condtions, we output certain stuff 
    reg [20:0] counter;
    always@(posedge clk or negedge nrst)begin
        if(!nrst && counter != count_15ms + 5) begin
            RS_init_out <= 0;
            RW_init_out <= 0;
            enable <= 0;
            DB7_init_out <= 0;
            DB6_init_out <= 0;
            DB5_init_out <= 0;
            DB4_init_out <= 0; // basically do not enable anything.
        end else begin
            counter <= counter + 1;
            RS_init_out <= 0;
            RW_init_out <= 0; // both of these are always 0 output
            
            if(
            counter == count_15ms + 5 || // func set command 1 that reaches the time requirements 
            counter == count_15ms + count_40us + count_4_1ms +  5 || // wait for a bit more than 4.1 ms
            counter == count_15ms + count_40us + count_4_1ms + count_100us + 5 // wait a bit for more than 100us
            ) begin /// these are all the different cases where we send out the 8-bit stuff to the LCD
                {DB7_init_out, DB6_init_out, DB5_init_out, DB4_init_out} <= 4'b0011; 
                // they all send out the same bits (we need to send it 3 times)
                enable <= 1; 
                
            end else if(
            counter == count_15ms + 10 || // this is after the power on
            counter == count_15ms + count_4_1ms + 10 || // func set cmd 1
            counter == count_15ms + count_4_1ms + count_100us + 10 // 
            ) begin // count + some small delay just to reset the enable
                enable <= 0;
            end
            
            if(
            counter == count_15ms + count_40us + count_4_1ms + count_100us + count_40us + 5 ||
            counter == count_15ms + count_4_1ms + count_100us + count_40us + count_40us + count_40us + 5
            )begin // function set, max wait time is 40us (which is why subtract 5 because we do not want to go over or near the max)
                {DB7_init_out, DB6_init_out, DB5_init_out, DB4_init_out} <= 4'b0010; // setting to the 4 bit interface input, twice
            end
            
            if(
            counter == count_15ms + count_40us + count_4_1ms + count_40us + count_100us + count_40us + count_40us + count_40us + 5
            ) begin
                {DB7_init_out, DB6_init_out, DB5_init_out, DB4_init_out} <= 4'b1100; // N F X X, N = 2 lines, F = 5x10 dots
            end
            
            // first half of display off, clear display, entry mode set, and display on are all 0000
            if(
            counter == count_15ms + count_40us + count_4_1ms + count_40us + count_100us + count_40us + count_40us + count_40us + count_40us + 5 || // display off 
            counter == count_15ms + count_40us + count_4_1ms + count_40us + count_100us + count_40us + count_40us + count_40us + count_40us + count_40us + count_40us + 5 || // clear display
            counter == count_15ms + count_40us + count_4_1ms + count_40us + count_100us + count_40us + count_40us + count_40us + count_40us + count_40us + count_40us + count_40us + count_40us + 5 || // entry mode set
            counter == count_15ms + count_40us + count_4_1ms + count_40us + count_100us + count_40us + count_40us + count_40us + count_40us + count_40us + count_40us + count_40us + count_40us + count_40us + 5 // display on
            ) begin
                {DB7_init_out, DB6_init_out, DB5_init_out, DB4_init_out} <= 4'b0000;
            end
            
            // the following are for the second half of display off, clear display, entry mode set, and display on          
            if(
            counter == count_15ms + count_40us + count_4_1ms + count_40us + count_100us + 
            count_40us + count_40us + count_40us + count_40us + count_40us + 5
            )begin
                {DB7_init_out, DB6_init_out, DB5_init_out, DB4_init_out} <= 4'b1000; // second half of display off
            end
            
            if(
            counter == count_15ms + count_40us + count_4_1ms + count_40us + count_100us + 
            count_40us + count_40us + count_40us + count_40us + count_40us + count_40us + count_40us + 5
            ) begin
                {DB7_init_out, DB6_init_out, DB5_init_out, DB4_init_out} <= 4'b0001; // second half of clear display
            end
            
            if(
            counter == count_15ms + count_40us + count_4_1ms + count_40us + count_100us + 
            count_40us + count_40us + count_40us + count_40us + count_40us + count_40us + count_40us + count_40us + count_40us + 5
            ) begin
                {DB7_init_out, DB6_init_out, DB5_init_out, DB4_init_out} <= 4'b0111; // second half of entry mode set
                                                                                     // 0 1 I/D S | I/D if 1 is increment, S if 1 will accompany display shift
                                                                                     // increment meaning to the right? accompany display shift meaning we will be moving the display later as intended?
            end
            
            if(
            counter == count_15ms + count_40us + count_4_1ms + count_40us + count_100us + 
            count_40us + count_40us + count_40us + count_40us + count_40us + count_40us + count_40us + count_40us + count_40us + count_40us + count_40us + 5 
            ) begin
                {DB7_init_out, DB6_init_out, DB5_init_out, DB4_init_out} <= 4'b1111; // second half of display on
                                                                                     // 1 1 C B | C if 1, enables the cursor, then B if 1, enables the blink
            end
        end
    end 
    
    
endmodule
