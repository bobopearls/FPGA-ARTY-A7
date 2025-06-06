// second attempt at making the initialization cleaner with states
// it is very hard to keep track of the count if the states are not specified

module four_bit_lcd_init(
  input clk, nrst, 
  input DB7, DB6, DB5, DB4, // we use DB7 to DB 4 {DB7, DB6, DB5, DB4} // inout because there are reads and writes
  output RS, RW, E // these are outputs that are also needed to send out
);
    reg [3:0] DB_init;
    reg RS_init, RW_init, E_init;
    assign DB7 = DB_init[3];
    assign DB6 = DB_init[2];
    assign DB5 = DB_init[1];
    assign DB4 = DB_init[0];
    
    assign RS = RS_init;
    assign RW = RW_init;
    assign E = E_init;
    
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
    
    parameter S_write_data_upper = 5'd18;
    parameter S_write_data_lower = 5'd19;
    
    // additional important states:
    parameter S_check_BF = 5'd20; // this state will check the BUSY FLAG, (usually stored in the DB7 | section 3.1.9 | if DB7 = 1, its busy)
    parameter S_exit_init = 5'd21;
    // start of how the states will work together
    reg [20:0] count;
    reg [4:0] S_after_BF; // need to show the state after BF for the checking
    reg done_write; // tells us we should not go back to the idle state
    reg start_timer_bit; // bit used to start the actual sending of initialization bits (issue was we skipped over state 1 and 2)
    reg count_sent_bit; // need a separate bit to tell the states that their count conditions for decrement were sent over already
    reg [4:0] curr_state, next_state; // our states are 5 bits total
    
    always@(posedge clk or negedge nrst)begin // sequential decrementing
        if(!nrst)begin
            curr_state <= S_idle;
            count <= 0;
            start_timer_bit <= 0;
            count_sent_bit <= 0;
        end else begin
            if(!count_sent_bit) begin
                case(next_state)
                    S_idle:             count <= count_15ms;
                    S_func_set_1:       count <= count_40us;
                    S_wait_4_1ms:       count <= count_4_1ms;
                    S_func_set_2:       count <= count_40us;
                    S_wait_100us:       count <= count_100us;
                    S_func_set_3:       count <= count_40us;
                    S_func_set_4:       count <= count_40us;
                    S_func_set_5_upper: count <= count_40us;
                    S_func_set_5_lower: count <= count_40us;
                    S_display_off_upper:count <= count_40us;
                    S_display_off_lower:count <= count_40us;
                    S_clear_disp_upper: count <= count_40us;
                    S_clear_disp_lower: count <= count_15_2ms;
                    S_entry_mode_upper: count <= count_40us;
                    S_entry_mode_lower: count <= count_40us;
                    S_disp_on_upper:    count <= count_40us;
                    S_disp_on_lower:    count <= count_40us;
                    S_write_data_upper: count <= count_40us;
                    S_write_data_lower: count <= count_40us;
                    S_check_BF:         count <= count_40us;
                    default:            count <= 0;
                endcase
                count_sent_bit <= 1; // the count for the specific state has already been sent
                
            end else if (count > 0 && !count_sent_bit) begin
                count <= count - 1;
            end else begin
                // if count_sent_bit is 1
                curr_state <= next_state;
                count_sent_bit <= 0; // reset
                
            end
        end 
    end
    
    // because now we have to read from DB7, we set it as an inout wire and then check the condition if it is R/W
//    reg DB7_read;

//    always @(posedge clk) begin
//        if (RW_init && E_init) begin
//            DB7_read <= DB7; // DB7 is inout and externally driven by LCD
//        end
//    end
   
    always@(*)begin
        // Default outputs
        DB_init = 4'b0000;
        RS_init = 0;
        RW_init = 0;
        E_init = 0;
        next_state = curr_state;  // default stay in same state
        
        // combinational logic for the states
        case(curr_state)
            S_idle: begin
                if(done_write) begin
                    next_state = S_write_data_upper;
                end else begin
                    DB_init = 4'b0000; // do not send out any data bits yet
                    next_state = S_func_set_1; // this happens after the count decrements
                end
                //count = count_15ms; // send this out, it will do the count and then if it is 0, that is when we go to the next state
            end
            
            S_func_set_1: begin
                DB_init = 4'b0011;
                next_state = S_wait_4_1ms;
                //count = count_40us;
            end
            
            S_wait_4_1ms: begin
                DB_init = 4'b0000; // do not send out data at this time
                next_state = S_func_set_2;
                //count = count_4_1ms;
            end
            
            S_func_set_2: begin
                DB_init = 4'b0011;
                next_state = S_wait_100us;
                //count = count_40us;
            end
            
            S_wait_100us: begin
                DB_init = 4'b0000;
                next_state = S_func_set_3;
                //count = count_100us;
            end
            
            S_func_set_3: begin
                DB_init = 4'b0011;
                next_state = S_func_set_4;
                //count = count_40us;
            end
            
            S_func_set_4: begin
                DB_init = 4'b0010;
                next_state = S_func_set_5_upper;
                //count = count_40us;
            end
            
            S_func_set_5_upper: begin
                DB_init = 4'b0010;
                next_state = S_func_set_5_lower;
                //count = count_40us;
            end
            
            S_func_set_5_lower: begin
                DB_init = 4'b1000; // 10xx
                next_state = S_display_off_upper;
                //count = count_40us;
            end
            
            S_check_BF: begin
                RS_init = 0; // select DB7 reg to be read
                RW_init = 1; // read operation
                E_init = 1; // set E to 1 to check RW to see if we are reading or writing
                
                if(DB_init[3] == 1) begin
                    next_state = S_check_BF; // to itself
                end else begin
                    RW_init = 0;
                    E_init = 0; //resets
                    next_state = S_after_BF;
                end
                //count <= count_40us;
            end
            
            S_display_off_upper: begin // can start checking BF flag here
                DB_init = 4'b0000;
                next_state = S_check_BF;
                S_after_BF = S_display_off_lower;
                //count = count_40us;
            end
            
            S_display_off_lower: begin
                DB_init = 4'b1000;
                next_state = S_check_BF;
                S_after_BF = S_clear_disp_upper;
                //count = count_40us;
            end
            
            S_clear_disp_upper: begin
                DB_init = 4'b0000;
                next_state = S_check_BF;
                S_after_BF = S_clear_disp_lower;
                //count = count_40us;
            end
            
            S_clear_disp_lower: begin
                DB_init = 4'b1000;
                next_state = S_check_BF;
                S_after_BF = S_entry_mode_upper;
                //count = count_15_2ms;
            end
            
            S_entry_mode_upper: begin
                DB_init = 4'b0000;
                next_state = S_check_BF;
                S_after_BF = S_entry_mode_lower;
                //count = count_40us;
            end
            
            S_entry_mode_lower: begin
                DB_init = 4'b0110; // increment cursor and display shift
                next_state = S_check_BF;
                S_after_BF = S_disp_on_upper;
                //count = count_40us;
            end
           
            S_disp_on_upper: begin
                DB_init = 4'b0000;
                next_state = S_check_BF;
                S_after_BF = S_disp_on_lower;
                //count = count_40us;
            end 
            
            S_disp_on_lower: begin
                DB_init = 4'b1111;
                next_state = S_check_BF;
                S_after_BF = S_init_done;
                //count = count_40us;
            end
            
            S_init_done: begin
                next_state <= S_write_data_upper;
            end
            
            S_write_data_upper: begin
                RS_init = 1;
                RW_init = 1;
                E_init = 0;
                DB_init = 4'b0100;
                next_state = S_write_data_lower;
            end
            
            S_write_data_lower: begin
                RS_init = 1;
                RW_init = 0;
                E_init = 0;
                DB_init = 4'b0001;
                done_write = 1;
                next_state = S_check_BF;
                S_after_BF = S_idle;
            end
            
//            S_exit_init: begin
//                RS_init = 0;
//                RW_init = 0;
//                E_init = 0;
//                next_state = S_exit_init;
                
//            end
            
            default: begin
                RS_init = 0;
                RW_init = 0;
                E_init = 0;
                DB_init = 4'b0000;
                next_state = S_idle;
            end
        endcase
        
    end
endmodule

  
  
  
  
