`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: CoE 111 ME 7
// Engineer: Quitoriano, Maria Louise
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
    
    parameter DEBOUNCE_COUNT = 20'd5_000_000; // adjust the count for debounce delay (double check this if we need to change this for 50ms)
    // 50ms is nicer for the button press (standard is 50ms or 100ms)
    // 50ms uses 5_000_000 and then 100ms would use 10_000_000
    
    reg [19:0] count;
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
    
    // edge detection
    reg button_out_prev;
    wire button_pressed;
    
    assign button_pressed = button_out && !button_out_prev;
    
    always @(posedge clk or negedge nrst) begin
        if (!nrst)
            button_out_prev <= 0;
        else
            button_out_prev <= button_out;
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
