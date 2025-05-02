`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02.05.2025 16:28:07
// Design Name: 
// Module Name: send_4bit_nibble
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

// this will take the 10 bit input, and then divide it into the ff
// the enable and r/w bits, then the lower and upper halves.
// after, we assign the bits to certain parts and this becomes the output to the LCD
// this is for initalization
module send_4bit_nibble(
    input clk, nrst,
    output reg RS_init_out, RW_init_out, enable,
    output reg DB7_init_out, DB6_init_out, DB5_init_out, DB4_init_out // these outputs will be sent over to the LCD
    );
    
    parameter count_15ms = 1_500_000; // these are the wait times for the init set up
    parameter count_4_1ms = 410_000;
    parameter count_100us = 10_000;
    
    parameter count_15_2ms = 1_520_000; // these are the max wait times for the different functions
    parameter count_40us = 40_000;
    
    // so depending on the series of condtions, we output certain stuff 
    reg [20:0] counter;
    always@(posedge clk or negedge nrst)begin
        if(!nrst) begin
            RS_init_out <= 0;
            RW_init_out <= 0;
            enable <= 0;
            DB7_init_out <= 0;
            DB6_init_out <= 0;
            DB5_init_out <= 0;
            DB4_init_out <= 0; // basically do not enable anything.
        end else begin
            counter <= counter + 1;
            if(counter == count_15ms) begin // the first 15ms
                {DB7_init_out, DB6_init_out, DB5_init_out, DB4_init_out} <= 4'b0011;
                enable <= 1; 
            end else if(counter == count_15ms + 5) begin // count + some small delay just to reset the enable
                enable <= 0;
            end
            
            if(counter == count_15ms + count_4_1ms)begin // this is moving forward in time
                {DB7_init_out, DB6_init_out, DB5_init_out, DB4_init_out} <= 4'b0011;
                enable <= 1;
            end else if(counter == count_15ms + count_4_1ms + 5) begin
                enable <= 0;
            end
            
            if(counter == count_15ms + count_4_1ms + count_100us)begin
                {DB7_init_out, DB6_init_out, DB5_init_out, DB4_init_out} <= 4'b0011;
                enable <= 1;
            end else if (counter == count_15ms + count_4_1ms + count_100us + 5) begin
                enable <= 0;
            end
            
            
            
        end
    end 
    
    
endmodule
