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
    reg button_sync_0, button_sync_1; // record the raw value of the button_in when the clk reaches the posedge | capture the value of sync_0 on the next clk cycle (aka stable version)
    // note: the button_in (raw button press, unstable button with noise) is an asynch button press.
    // so we need to synch the button press with the clk (which is why we have button_sync_0 and 1)
    
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

    // next, add the debouncing logic
    always@(posedge clk or negedge nrst) begin
        if(!nrst)begin
            count <= 0;
            button_out <= 0;
        end else begin
            // need to check if the sync is stable. if it is, then we can start the required count for it to be known as stable
            // choose 50ms first
            if(button_sync_1 == button_out) begin 
                // so if they both are the same, start the count time
                if(count < DEBOUNCE_COUNT)begin
                    count <= count + 1; // increment count
                end else begin
                    // else if the count is now more than debounce count or equal to it, then we latch to the value we need
                    button_out <= button_sync_1; // then button out is the latched value or the last stable value of the button
                end
            end else begin
                // if button_sync_1 is not equal to button_out, then count is 0 (do not count)
                count <= 0;
            end
        end
    end

endmodule
    
