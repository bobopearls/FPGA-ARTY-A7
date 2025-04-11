`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08.04.2025 11:07:47
// Design Name: 
// Module Name: pwm
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

// reusable 8-bit pwm module
module pwm(
    input clk, nrst,
    input [7:0] duty_cycle, // duty cycle of 0 to 255
    output reg pwm_out
    );
    
    reg [7:0] counter; 
    
    always@(posedge clk or negedge nrst) begin
        if(!nrst)
            counter <= 0;
        else
            counter <= counter +1;
    end
    
    always@(posedge clk) begin
        pwm_out <= (counter < duty_cycle);
        // is the current counter less than the duty cycle?
        // if yes, pwm out is 1, else it is 0
        // comparator circuit that is synthesizable !
    end
endmodule
