// second attempt at making the initialization cleaner with states
// it is very hard to keep track of the count if the states are not specified

module four_bit_lcd_init(
  input clk, nrst, 
  output [3:0] DB_init, // we use DB7 to DB 4 {DB7, DB6, DB5, DB4}
  output RS, RW, E // these are outputs that are also needed to send out
);
    // timing parameters for readability with the 100MHz board clock
    parameter count_15ms = 1_500_000; // these are the wait times for the init set up
    parameter count_4_1ms = 410_000;
    parameter count_100us = 10_000;
    parameter count_15_2ms = 1_520_000; // these are the max wait times for the different functions
    parameter count_40us = 40_000;

    // setting the states needed for initiaization | set the number of bits for these later
    parameter S_idle = 5'd0;
    parameter S_func_set_1 = 5'd1;
    parameter S_wait_4_1ms = 5'd2;
    parameter S_func_set_2 = 5'd3;
    parameter S_wait_100us = 5'd4;
    parameter S_func_set_3 = 5'd5;
    parameter S_func_set_4 = 5'd6;
    
    // starting the 5th func_set, there are upper and lower half nibbles we have to deal with
    parameter S_func_set_5_upper = 5'd7;
    parameter S_func_set_5_lower = 5'd8; // set N and F here (N=1 for two line disp | F=0 for 5x7 dots ? or is it 5x10)
    
    // starting this instruction, we have to check the BF 
    parameter S_display_off_upper = 5'd9;
    parameter S_display_off_lower = 5'd10;
    
    parameter S_clear_disp_upper = 5'd11;
    parameter S_clear_disp_lower = 5'd12;
    
    parameter S_entry_mode_upper = 5'd13;
    parameter S_entry_mode_lower = 5'd14; // I/D = 1 for increment cursor | S=0 for display shift
    
    parameter S_disp_on_upper = 5'd15;
    parameter S_disp_on_lower = 5'd16; // C=1 for show cursor location | B= for blink where the cursor is
    
    parameter S_init_done = 5'd17;
    
    // additional important states:
    parameter S_check_BF = 5'd18; // this state will check the BUSY FLAG, (usually stored in the DB7 | section 3.1.9 | if DB7 = 1, its busy)
    
    // start of how the states will work together
    reg [20:0] count;
    reg [4:0] curr_state, next_state; // our states are 5 bits total
    always@(posedge clk or negedge nrst)begin
        if(!nrst)begin
            curr_state <= S_idle;
            count <= 0;
            // implement a decrement counter here. so when a state sends out a count number, it will decrement until it reaches 0 (instead of increment)
        end else begin
            if(count == 0) begin
            end
        end
  end
endmodule

  
  
  
  
