`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08.04.2025 11:37:26
// Design Name: 
// Module Name: debounce_button
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

// debouncing works as a counter (we need to give the button sometime to go back to 
// 0 after it is pressed to count as only one button press)
module debounce_button(
    input clk, nrst, button_in,
    output reg button_out // debounced output
    );
    
    parameter DEBOUNCE_COUNT = 20'd1_000_000; // adjust the count for debounce delay
    
    reg [15:0] count;
    reg button_sync_0, button_sync_1; // synch input and the clock
    
    // sync the clock and the button input to eliminate timing issues
    always@(posedge clk or negedge nrst)begin
        if(!nrst) begin
            button_sync_0 <= 0;
            button_sync_1 <= 0;
        end else begin
            button_sync_0 <= button_in;
            button_sync_1 <= button_sync_0; // make sure that these are updated at the same clock cycle
        end 
    end
    
    // debouncing logic
    always@(posedge clk or negedge nrst) begin
        if(!nrst) begin
            count <= 0;
            button_out <= 0;
        end else begin
            // if no debouncing detected:
            if (button_sync_1 == button_out)begin
                // increment until delay is met
                if(count < DEBOUNCE_COUNT)begin
                    count <= count + 1;
                end else begin
                    button_out <= button_sync_1;
                end
            end else begin
                count <= 0; //reset if state change is detected 
            end
        end
    end
endmodule
