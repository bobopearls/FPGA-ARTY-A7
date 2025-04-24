
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
    // this is because we want the 50% duty cycle
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
        .button_out(btn_debounced) // the output here is already correct
    );
    
    // for the 100 Hz, the PWM is on if its 1 and off if its 0
    reg prev_100Hz_clk;
    reg [2:0] color_sel; // there are 7 colors to choose from
    reg prev_btn_debounced; //WE NEED EDGE DETECTION SO THE COLOR DOESNT ALWAYS SWITCH REGARDLESS IF WE ARE JUST HOLDING DOWN THE BUTTON
    always@(posedge clk or negedge nrst) begin
        if(!nrst) begin
            prev_100Hz_clk <= 0;
            color_sel <= 0; // make a case where red is = 0
            prev_btn_debounced <= 0;
        end else begin
            if(btn_debounced && !prev_btn_debounced)begin
                // probing the 100Hz clk, prev clk, and the btn edge since it determines when we change colors
                // if the direction is 1, we move backwards (violet -> indigo -> blue -> green -> yellow -> orange -> red)
                if(dir) begin
                    color_sel <= (color_sel == 0) ?  6 : color_sel - 1;
                    // assume that we always start from reset so if the color is red, then we move to 6
                    // else, whatever the color is, we move one step back
                end else begin // else if dir is 0 (regular upwards ordering)
                    color_sel <= (color_sel == 0) ? 1 : color_sel + 1;
                    // assume we start in reset, so if the color is red, then we move to one,
                    // else if the color is not red, then we move one step up from where it was from
                end
            end
            prev_btn_debounced <= btn_debounced; 
        end
    end
    
    reg [7:0] dutyc_r, dutyc_g, dutyc_b; // the colors are 8 bits each
    // state machine to know what the next color is depending on dir, button press, and previous color state
    // If `dir` is 1, cycle backward through the colors (e.g., violet -> indigo -> blue).
    // If `dir` is 0, cycle forward through the colors (e.g., red -> orange -> yellow).
    always@(*) begin
        case(color_sel) // these states are used in the selecting of what color to display
            // 0 = red, 1 = orange, 2 = yellow, 3= green, 4 = blue, 5 = indigo, 6 = violet
            // decompose the localparameters and extract the duty cycles from them 
            3'd0: {dutyc_r, dutyc_g, dutyc_b} = red;
            3'd1: {dutyc_r, dutyc_g, dutyc_b} = orange;
            3'd2: {dutyc_r, dutyc_g, dutyc_b} = yellow;
            3'd3: {dutyc_r, dutyc_g, dutyc_b} = green;
            3'd4: {dutyc_r, dutyc_g, dutyc_b} = blue;
            3'd5: {dutyc_r, dutyc_g, dutyc_b} = indigo;
            3'd6: {dutyc_r, dutyc_g, dutyc_b} = violet;
            default: {dutyc_r, dutyc_g, dutyc_b} = red; // default at reset red
            // the duty cycle values will be fed to the pwm module 
        endcase
    end
    
    pwm r_pwm(
        .clk(clk),
        .nrst(nrst),
        .duty_cycle(dutyc_r),
        .pwm_out(rgb_r) // the actual output to the board
    );
    
    pwm g_pwm(
        .clk(clk),
        .nrst(nrst),
        .duty_cycle(dutyc_g),
        .pwm_out(rgb_g) // the actual output to the board
    );
    
    pwm b_pwm(
        .clk(clk),
        .nrst(nrst),
        .duty_cycle(dutyc_b),
        .pwm_out(rgb_b) // the actual output to the board
    );
    
    
endmodule

