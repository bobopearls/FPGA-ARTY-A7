
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04.04.2025 16:18:42
// Design Name: 
// Module Name: rgb
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

`timescale 1ns / 1ps
module rgb(
    input clk, nrst,
    input dir, btn,
    output rgb_r, rgb_g, rgb_b
    );
    
    // ordered in terms of R_G_B, accounted for the 50% duty cycle where 7F is the top value (equivalent to FF but its half)
    localparam red = 24'h7F_00_00;
    localparam orange = 24'h7F_52_00;
    localparam yellow = 24'h7F_7F_00;
    localparam green = 24'h00_7F_00;
    localparam blue = 24'h00_00_7F;
    localparam indigo = 24'h25_00_41;
    localparam violet = 24'h77_41_77;
    
    wire wire_100Hz_clk_out; // instantiate the 100Hz clock switching frequency for the led to blink fast enough
    mod_100Hz_fdiv inst_100Hz_clk(
        .clk(clk),
        .nrst(nrst), 
        .div_clk(wire_100Hz_clk_out)
    );
    
    // instantiating the button debouncer module (input is the actual button press but output is the debounced button that controls it)
    wire btn_debounced; // use this as the new button input (stable version)
    debounce_button u_debounce_button(
        .clk(clk),
        .nrst(nrst),
        .button_in(btn),
        .button_out(btn_debounced)
    );
    
    // check the rising edge of btn
    wire btn_edge;
    reg btn_prev;
    always@(posedge clk or negedge nrst)begin
        if(!nrst)
            btn_prev <= 0;
        else
            btn_prev <= btn_debounced; // uses debounced button input instead of the raw button input
    end 
    assign btn_edge = (btn_debounced && !btn_prev); // the rising edge
                                                    // checking the rising edge only of the button (since the button press high might last for multiple clock cycles)
    
    // for the 100 Hz, the PWM is on if its 1 and off if its 0
    reg prev_100Hz_clk;
    always@(posedge clk or negedge nrst) begin
        if(!nrst) begin
            prev_100Hz_clk <= 0;
            // add later color at reset is red
        end else begin
            if(wire_100Hz_clk_out && !prev_100Hz_clk)begin
                // color is something
            end
            prev_100Hz_clk <= wire_100Hz_clk_out; // update the prev clk to take the value
        end
    end
    
    // state machine to know what the next color is depending on dir, button press, and previous color state
    reg [0:2] color_sel; // there are 7 colors to choose from
    always@(*) begin
        case(color_sel)
            
    end
    
    
endmodule

