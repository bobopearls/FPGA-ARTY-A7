`timescale 1ns/1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 28.03.2025 17:21:22
// Design Name: 
// Module Name: updown_ssd
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

module updown_ssd(
    input clk, nrst, dir, // clk is the 100MHz, reset, dir = 1 count up and 0 is count down
    output segA, segB, segC, segD, segE, segF, segG,
    output reg sel
    );
    wire clk_1Hz, clk_50Hz;
    fdiv_1Hz_clk fdiv_1 (.clk(clk), .nrst(nrst), .clk_1Hz_out(clk_1Hz));
    fdiv_50Hz_clk fdiv_50 (.clk(clk), .nrst(nrst), .clk_50Hz_out(clk_50Hz));
    reg [7:0] count = 8'd0; // 8 bit counter (0-255)
    
    // up and down dir count
    always@(posedge clk_1Hz or negedge nrst)begin // note that the count has to change for 1 second
        if(!nrst)
            count <= 8'h00; // reset the count
        else if (dir && count == 8'hFF)
            count <= 8'h00; // go back to 0
        else if (!dir && count == 8'h00)
            count <= 8'hFF; // decrement / go backwards
        else if (dir)
            count <= count + 1; // increment the caount going up
        else
            count <= count - 1; // decrement the count going down
    end
    
    // flickering changes (similar to how we do clk where we use ~)
    always@(posedge clk_50Hz or negedge nrst)begin // changes every 20ms
        if(!nrst)
            sel <= 1'b0;
        else
            sel <= ~sel; // going back and fourth between the displays
    end

    // selecting what digit (either left or right) to display when sel is either 0 or 1 and what digit (left or right) we will display
    reg [3:0] digit;
    always@(*)begin
        if(sel)// if sel is 1, we will display the left_MSB digit (can be changed if it is the opposite display)
            digit = count[7:4];
        else // if sel is 0, we will display the right_LSB digit
            digit = count[3:0];
            // so if the count is 13, we need to display hex "0d". 0000 | 1101 we can take the upper half of the count to be the tens
            // then the lower half of the count bits to display the ones
            // another example when we want to display 69 in hex which is 4 | 5, same as 0100 | 0101
    end
    
    // 7 segment cases for 0 to F (single digits first)
    reg [6:0] display_seg;
    always@(*)begin
        case(digit)
            // choose which segments to enable based on the digit / number
            4'h0: display_seg = 7'b1111110; // enabling all segments except G
            4'h1: display_seg = 7'b0110000; // only enabling segments B and C
            4'h2: display_seg = 7'b1101101; // enabling A,B,D,E,G
            4'h3: display_seg = 7'b1111001; // enabling A,B,G,C,D
            4'h4: display_seg = 7'b0110010; // enabling B,C,G,F
            4'h5: display_seg = 7'b1011010; // A,F,G,C,D
            4'h6: display_seg = 7'b1011111; // all except B are enabled
            4'h7: display_seg = 7'b1110000; // only ABC are enabled
            4'h8: display_seg = 7'b1111111; // enable all
            4'h9: display_seg = 7'b1110011; // all except E and D
            4'hA: display_seg = 7'b1110111; // all except D
            4'hB: display_seg = 7'b0011111; // all except A and B
            4'hC: display_seg = 7'b1001110; // all exceptr BGC
            4'hD: display_seg = 7'b0111101; // all except for A and F
            4'hE: display_seg = 7'b1001111; // all except B and C
            4'hF: display_seg = 7'b1000111; // all except B,C,D
            default: display_seg = 7'b0000000; // off
        endcase
    end
    // display seg bits are formatted as: A,B,C,D,E,F,G
    assign segA = display_seg[6];
    assign segB = display_seg[5];
    assign segC = display_seg[4];
    assign segD = display_seg[3];
    assign segE = display_seg[2];
    assign segF = display_seg[1];
    assign segG = display_seg[0];
    
endmodule    

module fdiv_1Hz_clk(
    input clk, nrst,
    output clk_1Hz_out
    );
    //instantiate clk divider modules (be careful which clk we are using)
    fdiv_1Hz fdiv_1Hz_inst(.clk(clk), .nrst(nrst), .div_clk(clk_1Hz_out)); // for the 1 second change
endmodule

module fdiv_50Hz_clk(
    input clk, nrst,
    output clk_50Hz_out
    );
    //instantiate clk divider modules (be careful which clk we are using)
    fdiv_50Hz fdiv_50Hz_inst(.clk(clk), .nrst(nrst), .div_clk(clk_50Hz_out)); // for the alternating lights / flickering
endmodule
