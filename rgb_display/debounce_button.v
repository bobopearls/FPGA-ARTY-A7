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
    ); // 2 flip flops ?
    
    parameter DEBOUNCE_COUNT = 20'd5_000_000; // adjust the count for debounce delay (double check this if we need to change this for 50ms)
    // 50ms is nicer for the button press (standard is 50ms or 100ms)
    // 50ms uses 5_000_000 and then 100ms would use 10_000_000
    
    reg [19:0] count;
    reg stable_state, last_stable_state; // need to check the last stable state because without it, the button press will remain 1 forever
    reg button_sync_0, button_sync_1; // record the raw value of the button_in when the clk reaches the posedge | capture the value of sync_0 on the next clk cycle (aka stable version)
    // note: the button_in (raw button press, unstable button with noise) is an asynch button press.
    // so we need to synch the button press with the clk (which is why we have button_sync_0 and 1)
    
    // WE WAIT 50MS AFTER THE NOISE HAS SETTLED DOWN TO CHECK
    
    // sync the clock and the button input to eliminate timing issues
    always@(posedge clk or negedge nrst)begin
        if(!nrst) begin
            button_sync_0 <= 0;
            button_sync_1 <= 0;
            count <= 0;
            stable_state <= 0;
            last_stable_state <= 0;
            button_out <= 0;
            
        end else begin
            button_sync_0 <= button_in;
            button_sync_1 <= button_sync_0; //stable version of button input saved
            
            // debounce logic
            if(button_sync_1 == stable_state)begin // THIS MEANS THAT WE DO NOT DO ANYTHING BECAUSE THERE HAS BEEN NO INTERRUPT
                count <= 0; // no change detected, reset the counter 
                
            end else begin
                count <= count + 1; // so if the rising button interrupt edge is detected, it then starts counting 50ms to give a buffer time
                // this count helps wait for the button to be stable (so we are making sure that no unstable button value wrongrly triggers)
                
                if(count >= DEBOUNCE_COUNT) begin // so now we finished waiting for 50ms, we know the button is stable and we can perform the ff:
                    stable_state <= button_sync_1;
                    
                    if(last_stable_state == 0 && button_sync_1 == 1)begin
                        // so now, if we detect a stable rising edge (button pressed) we can then say the stable button out is 1
                        button_out <= 1;
                    end else if (last_stable_state == 1 && button_sync_1 == 0)begin
                        button_out <= 0; // else if we detect the negative edge, that means we have released the button 
                    end
                    last_stable_state <= button_sync_1;
                end else begin
                    button_out <= 0;
                end
            end
        end 
    end
endmodule
    
