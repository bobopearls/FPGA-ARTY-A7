// LCD initialization with hardcoded text on two lines
// Line 1: "COLOR MODE"
// Line 2: "TYPE MODE"

module four_bit_lcd_init(
  input clk, nrst, 
  output DB7, DB6, DB5, DB4,
  output RS, E
);
    reg [3:0] DB_init;
    reg RS_init, E_init;
    assign DB7 = DB_init[3];
    assign DB6 = DB_init[2];
    assign DB5 = DB_init[1];
    assign DB4 = DB_init[0];
    
    assign RS = RS_init;
    assign E = E_init;
    
    // timing parameters
    parameter count_15ms = 1_500_000;
    parameter count_4_1ms = 410_000;
    parameter count_100us = 10_000;
    parameter count_15_2ms = 1_520_000;
    //parameter count_40us = 4_000; //change this now that we have the split with pulses
    parameter count_20us = 2_000; // set and then pulse add up to 40us total


    // existing initialization states from attempt 2
    parameter S_idle = 6'd0;
    
    // need to add pulses because E_init has to go from 0 to 1 ever state (set, reset)
    parameter S_func_set_1          = 6'd1;
    parameter S_func_set_1_pulse    = 6'd2; // so every state has a deciated E_init = 0, and E_init = 1
    parameter S_wait_4_1ms          = 6'd3;
   
    parameter S_func_set_2          = 6'd4;
    parameter S_func_set_2_pulse    = 6'd5;
    parameter S_wait_100us          = 6'd6;
    
    parameter S_func_set_3          = 6'd7;
    parameter S_func_set_3_pulse    = 6'd8;
    
    parameter S_func_set_4          = 6'd9;
    parameter S_func_set_4_pulse    = 6'd10;
    
    parameter S_func_set_5_upper    = 6'd11;
    parameter S_func_set_5_upper_pulse = 6'd12;
    parameter S_func_set_5_lower    = 6'd13;
    parameter S_func_set_5_lower_pulse = 6'd14;
    
    parameter S_display_off_upper   = 6'd15;
    parameter S_display_off_upper_pulse = 6'd16;
    parameter S_display_off_lower   = 6'd17;
    parameter S_display_off_lower_pulse = 6'd18;
    
    parameter S_clear_disp_upper    = 6'd19;
    parameter S_clear_disp_upper_pulse = 6'd20;
    parameter S_clear_disp_lower    = 6'd21;
    parameter S_clear_disp_lower_pulse = 6'd22;
    
    parameter S_entry_mode_upper    = 6'd23;
    parameter S_entry_mode_upper_pulse = 6'd24;
    parameter S_entry_mode_lower    = 6'd25;
    parameter S_entry_mode_lower_pulse = 6'd26;
    
    parameter S_disp_on_upper       = 6'd27;
    parameter S_disp_on_upper_pulse = 6'd28;
    parameter S_disp_on_lower       = 6'd29;
    parameter S_disp_on_lower_pulse = 6'd30;
    
    parameter S_init_done           = 6'd31;

    // Line 1 setup and write
    parameter S_set_line1_addr_upper    = 6'd32;
    parameter S_set_line1_addr_upper_pulse = 6'd33;
    parameter S_set_line1_addr_lower    = 6'd34;
    parameter S_set_line1_addr_lower_pulse = 6'd35;
    
    parameter S_write_line1_upper       = 6'd36;
    parameter S_write_line1_upper_pulse = 6'd37;
    parameter S_write_line1_lower       = 6'd38;
    parameter S_write_line1_lower_pulse = 6'd39;
    
    // Line 2 setup and write
    parameter S_set_line2_addr_upper    = 6'd40;
    parameter S_set_line2_addr_upper_pulse = 6'd41;
    parameter S_set_line2_addr_lower    = 6'd42;
    parameter S_set_line2_addr_lower_pulse = 6'd43;
    
    parameter S_write_line2_upper       = 6'd44;
    parameter S_write_line2_upper_pulse = 6'd45;
    parameter S_write_line2_lower       = 6'd46;
    parameter S_write_line2_lower_pulse = 6'd47;
    
    parameter S_complete                = 6'd48;
    // Character data for "COLOR MODE" and "TYPE MODE"
    reg [7:0] line1_chars [0:9]; // "COLOR MODE"
    reg [7:0] line2_chars [0:8];  // "TYPE MODE"
    
    initial begin
        // Line 1: "COLOR MODE"
        line1_chars[0] = 8'h43; // 'C'
        line1_chars[1] = 8'h4F; // 'O'
        line1_chars[2] = 8'h4C; // 'L'
        line1_chars[3] = 8'h4F; // 'O'
        line1_chars[4] = 8'h52; // 'R'
        line1_chars[5] = 8'h20; // ' ' (space)
        line1_chars[6] = 8'h4D; // 'M'
        line1_chars[7] = 8'h4F; // 'O'
        line1_chars[8] = 8'h44; // 'D'
        line1_chars[9] = 8'h45; // 'E'
        
        // Line 2: "TYPE MODE"
        line2_chars[0] = 8'h54; // 'T'
        line2_chars[1] = 8'h59; // 'Y'
        line2_chars[2] = 8'h50; // 'P'
        line2_chars[3] = 8'h45; // 'E'
        line2_chars[4] = 8'h20; // ' ' (space)
        line2_chars[5] = 8'h4D; // 'M'
        line2_chars[6] = 8'h4F; // 'O'
        line2_chars[7] = 8'h44; // 'D'
        line2_chars[8] = 8'h45; // 'E'
    end
    
    reg [20:0] count;
    reg [5:0] curr_state, next_state;
    reg [3:0] char_index; // index for character being written
    reg writing_line1, writing_line2; // flags to track which line we're writing
    reg count_sent_bit;
    reg [7:0] current_char;
    //reg [3:0] curr_state_E, next_state_E;
    
    always@(posedge clk or negedge nrst) begin
        if(!nrst) begin
            curr_state <= S_idle;
            count <= 0;
            count_sent_bit <= 0;
            char_index <= 0;
            //writing_line1 <= 0;
            //writing_line2 <= 0;
        end else begin
            if(!count_sent_bit) begin
                case(next_state)
                    S_idle:                 count <= count_15ms;
                    S_func_set_1:           count <= count_20us;
                    S_wait_4_1ms:           count <= count_4_1ms;
                    S_func_set_2:           count <= count_20us;
                    S_wait_100us:           count <= count_100us;
                    S_func_set_3:           count <= count_20us;
                    S_func_set_4:           count <= count_20us;
                    S_func_set_5_upper:     count <= count_20us;
                    S_func_set_5_lower:     count <= count_20us;
                    S_display_off_upper:    count <= count_20us;
                    S_display_off_lower:    count <= count_20us;
                    S_clear_disp_upper:     count <= count_20us;
                    S_clear_disp_lower:     count <= count_20us;
                    S_entry_mode_upper:     count <= count_20us;
                    S_entry_mode_lower:     count <= count_20us;
                    S_disp_on_upper:        count <= count_20us;
                    S_disp_on_lower:        count <= count_20us;
                    S_set_line1_addr_upper: count <= count_20us;
                    S_set_line1_addr_lower: count <= count_20us;
                    S_write_line1_upper:    count <= count_20us;
                    S_write_line1_lower:    count <= count_20us;
                    S_set_line2_addr_upper: count <= count_20us;
                    S_set_line2_addr_lower: count <= count_20us;
                    S_write_line2_upper:    count <= count_20us;
                    S_write_line2_lower:    count <= count_20us;
                    //S_Einit_Zeroset:        count <= count_40us;
                    
                    // new PULSE conditions
                    S_func_set_1_pulse:        count <= count_20us;
                    S_func_set_2_pulse:        count <= count_20us;
                    S_func_set_3_pulse:        count <= count_20us;
                    S_func_set_4_pulse:        count <= count_20us;
                    S_func_set_5_upper_pulse:  count <= count_20us;
                    S_func_set_5_lower_pulse:  count <= count_20us;
                    
                    S_display_off_upper_pulse: count <= count_20us;
                    S_display_off_lower_pulse: count <= count_20us;
                    
                    S_clear_disp_upper_pulse:  count <= count_20us;
                    S_clear_disp_lower_pulse:  count <= count_20us;
                    
                    S_entry_mode_upper_pulse:  count <= count_20us;
                    S_entry_mode_lower_pulse:  count <= count_20us;
                    
                    S_disp_on_upper_pulse:     count <= count_20us;
                    S_disp_on_lower_pulse:     count <= count_20us;
                    
                    S_set_line1_addr_upper_pulse:  count <= count_20us;
                    S_set_line1_addr_lower_pulse:  count <= count_20us;
                    
                    S_write_line1_upper_pulse:     count <= count_20us;
                    S_write_line1_lower_pulse:     count <= count_20us;
                    
                    S_set_line2_addr_upper_pulse:  count <= count_20us;
                    S_set_line2_addr_lower_pulse:  count <= count_20us;
                    
                    S_write_line2_upper_pulse:     count <= count_20us;
                    S_write_line2_lower_pulse:     count <= count_20us;

                    default:                count <= 0;
                endcase
                count_sent_bit <= 1;
            end else if (count > 0) begin
                count <= count - 1;
            end else begin
                curr_state <= next_state;
                count_sent_bit <= 0;
            end
        end 
    end
   
    always@(*) begin
        // Default outputs
        DB_init = 4'b0000;
        RS_init = 0;
        E_init = 0;
        next_state = curr_state;
        
        case(curr_state)
            S_idle: next_state = S_func_set_1;
            S_func_set_1: begin
                DB_init = 4'b0011;
                E_init = 1;
                RS_init = 0;
                next_state = S_func_set_1_pulse;
            end
            S_func_set_1_pulse: begin
                DB_init = 4'b0011;
                RS_init = 0;
                E_init = 0;
                next_state = S_wait_4_1ms;
            end
            S_wait_4_1ms: begin
                E_init = 0;
                next_state = S_func_set_2;
            end
            S_func_set_2: begin
                DB_init = 4'b0011;
                RS_init = 0;
                E_init = 1;
                next_state = S_func_set_2_pulse;
            end
            S_func_set_2_pulse: begin
                DB_init = 4'b0011;
                RS_init = 0;
                E_init = 0;
                next_state = S_wait_100us;
            end
            S_wait_100us: begin
                E_init = 0;
                next_state = S_func_set_3;
            end 
            S_func_set_3: begin
                DB_init = 4'b0011;
                RS_init = 0;
                E_init = 1;
                next_state = S_func_set_3_pulse;
            end
            S_func_set_3_pulse: begin
                DB_init = 4'b0011;
                RS_init = 0;
                E_init = 0;
                next_state = S_func_set_4;
            end
            S_func_set_4: begin
                DB_init = 4'b0010;
                RS_init = 0;
                E_init = 1;
                next_state = S_func_set_4_pulse;
            end
            S_func_set_4_pulse: begin
                DB_init = 4'b0010;
                RS_init = 0;
                E_init = 0;
                next_state = S_func_set_5_upper;
            end
            S_func_set_5_upper: begin
                DB_init = 4'b0010;
                RS_init = 0;
                E_init = 1;
                next_state = S_func_set_5_upper_pulse;
            end
            S_func_set_5_upper_pulse: begin
                DB_init = 4'b0010;
                RS_init = 0;
                E_init = 0;
                next_state = S_func_set_5_lower;
            end
            S_func_set_5_lower: begin
                DB_init = 4'b1000; // 4-bit mode, 2 lines, 5x7 dots
                RS_init = 0;
                E_init = 1;
                next_state = S_func_set_5_lower_pulse;
            end
            S_func_set_5_lower_pulse: begin
                E_init = 0;
                DB_init = 4'b1000; // 4-bit mode, 2 lines, 5x7 dots
                RS_init = 0;
                next_state = S_display_off_upper;
            end
            S_display_off_upper: begin
                DB_init = 4'b0000;
                RS_init = 0;
                E_init = 1;
                next_state = S_display_off_upper_pulse;
            end
            S_display_off_upper_pulse: begin
                DB_init = 4'b0000;
                RS_init = 0;
                E_init = 0;
                next_state = S_display_off_lower;
            end
            S_display_off_lower: begin
                E_init = 1;
                DB_init = 4'b1000;
                RS_init = 0;
                next_state = S_display_off_lower_pulse;
            end
            S_display_off_lower_pulse: begin
                E_init = 0;
                DB_init = 4'b1000;
                RS_init = 0;
                next_state = S_clear_disp_upper;
            end
            S_clear_disp_upper: begin
                DB_init = 4'b0000;
                E_init = 1;
                RS_init = 0;
                next_state = S_clear_disp_upper_pulse;
            end
            S_clear_disp_upper_pulse: begin
                DB_init = 4'b0000;
                E_init = 0;
                RS_init = 0;
                next_state = S_clear_disp_lower;
            end
            S_clear_disp_lower: begin
                DB_init = 4'b0001;
                E_init = 1;
                RS_init = 0;
                next_state = S_clear_disp_lower_pulse;
            end
            S_clear_disp_lower_pulse: begin
                DB_init = 4'b0001;
                E_init = 0;
                RS_init = 0;
                next_state = S_entry_mode_upper;
            end
            S_entry_mode_upper: begin
                DB_init = 4'b0000;
                E_init = 1;
                RS_init = 0;
                next_state = S_entry_mode_upper_pulse;
            end
            S_entry_mode_upper_pulse: begin
                DB_init = 4'b0000;
                RS_init = 0;
                E_init = 0;
                next_state = S_entry_mode_lower;
            end
            S_entry_mode_lower: begin
                DB_init = 4'b0110; // increment cursor, no display shift
                RS_init = 0;
                E_init = 1;
                next_state = S_entry_mode_lower_pulse;
            end
           S_entry_mode_lower_pulse: begin
                DB_init = 4'b0110; // increment cursor, no display shift
                RS_init = 0;
                E_init = 0;
                next_state = S_disp_on_upper;
           end
            S_disp_on_upper: begin
                DB_init = 4'b0000;
                RS_init = 0;
                E_init = 1;
                next_state = S_disp_on_upper_pulse;
            end 
            S_disp_on_upper_pulse: begin
                DB_init = 4'b0000;
                RS_init = 0;
                E_init = 0;
                next_state = S_disp_on_lower;
            end
            S_disp_on_lower: begin
                DB_init = 4'b1111; // display on, cursor on, blink on
                RS_init = 0;
                E_init = 1;
                next_state = S_disp_on_lower_pulse;
            end
            S_disp_on_lower_pulse: begin
                DB_init = 4'b1111; // display on, cursor on, blink on
                RS_init = 0;
                E_init = 0;
                next_state = S_set_line1_addr_upper_pulse; // DDRAM line 1
            end
//            S_init_done: begin
//                next_state = S_set_line1_addr_upper;
//            end
            
            // Set cursor to line 1, position 0 (0x80)
            S_set_line1_addr_upper: begin
                RS_init = 0; // command mode
                DB_init = 4'b1000; // upper nibble of 0x80
                E_init = 1;
                next_state = S_set_line1_addr_upper_pulse;
            end
            S_set_line1_addr_upper_pulse: begin
                RS_init = 0; // command mode
                DB_init = 4'b1000; // upper nibble of 0x80
                E_init = 0;
                next_state = S_set_line1_addr_lower;
            end 
            S_set_line1_addr_lower: begin
                RS_init = 0;
                DB_init = 4'b0000; // lower nibble of 0x80
                E_init = 1;
                next_state = S_set_line1_addr_lower_pulse;
            end
            S_set_line1_addr_lower_pulse: begin
                RS_init = 0;
                DB_init = 4'b0000; // lower nibble of 0x80
                E_init = 0;
                next_state = S_write_line1_upper;
            end
            
            // Write characters for line 1 - COLOR MODE
            S_write_line1_upper: begin
                //E_init = 0;
                RS_init = 1; // data mode FINALLY 1 NA RIN SIYA
                current_char = line1_chars[char_index];
                DB_init = current_char[7:4]; // upper nibble
                E_init = 1;
                next_state = S_write_line1_upper_pulse;
            end
            S_write_line1_upper_pulse: begin
                //E_init = 0;
                RS_init = 1; // data mode FINALLY 1 NA RIN SIYA
                current_char = line1_chars[char_index];
                DB_init = current_char[7:4]; // upper nibble
                E_init = 0; // pls parang awa mo na E_init 
                next_state = S_write_line1_lower;
            end
            S_write_line1_lower: begin
                //E_init = 0;
                RS_init = 1;
                DB_init = current_char[3:0]; // lower nibble
                E_init = 1;
                next_state = S_write_line1_lower_pulse;
            end
            S_write_line1_lower_pulse: begin
                RS_init = 1;
                DB_init = current_char[3:0]; // lower nibble
                E_init = 0;
                if (char_index < 9) begin
                    next_state = S_write_line1_upper; // continue with next character
                end else begin
                    next_state = S_set_line2_addr_upper; // move to line 2
                end
            end
            
            // Set cursor to line 2, position 0 (0xC0)
            S_set_line2_addr_upper: begin
                //E_init = 0;
                RS_init = 0;
                DB_init = 4'b1100; // upper nibble of 0xC0
                E_init = 1;
                next_state = S_set_line2_addr_upper_pulse;
            end
            S_set_line2_addr_upper_pulse: begin
                //E_init = 0;
                RS_init = 0;
                DB_init = 4'b1100; // upper nibble of 0xC0
                E_init = 0;
                next_state = S_set_line2_addr_lower;
            end
            S_set_line2_addr_lower: begin
                //E_init = 0;
                RS_init = 0;
                DB_init = 4'b0000; // lower nibble of 0xC0
                E_init = 1;
                next_state = S_set_line2_addr_lower_pulse;
            end
            S_set_line2_addr_lower_pulse: begin
                //E_init = 0;
                RS_init = 0;
                DB_init = 4'b0000; // lower nibble of 0xC0
                E_init = 0;
                next_state = S_write_line2_upper;
            end
            
            // Write characters for line 2 - TYPE MODE
            S_write_line2_upper: begin
                //E_init = 0;
                RS_init = 1;
                current_char = line2_chars[char_index - 10]; // adjust index for line 2
                DB_init = current_char[7:4];
                E_init = 1;
                next_state = S_write_line2_upper_pulse;
            end
            S_write_line2_upper_pulse: begin
                DB_init = current_char[7:4]; 
                RS_init = 1;
                E_init = 0;
                next_state = S_write_line2_lower;
            end
            S_write_line2_lower: begin
                //E_init = 0;
                RS_init = 1;
                DB_init = current_char[3:0];
                E_init = 1;
                next_state = S_write_line2_lower_pulse;
            end
            S_write_line2_lower_pulse: begin
                RS_init = 1;
                DB_init = current_char[3:0];
                E_init = 0;
                if (char_index < 19) begin // total characters: 10 + 9 = 19
                    next_state = S_write_line2_upper;
                end else begin
                    next_state = S_complete;
                end
            end
            
            
            S_complete: begin // yay
                // Stay in this state - text display is complete
                next_state = S_complete;
            end
            
            default: begin
                next_state = S_idle;
            end
        endcase
    end
    
    // Character counter 
    always @(posedge clk or negedge nrst) begin
        if (!nrst) begin
            char_index <= 0;
        end else begin
            if ((curr_state == S_write_line1_lower_pulse && next_state == S_write_line1_upper) ||
                (curr_state == S_write_line2_lower_pulse && next_state == S_write_line2_upper)) begin
                char_index <= char_index + 1;
            end else if (curr_state == S_set_line2_addr_upper) begin
                char_index <= 10; // reset for line 2 (starting at index 10)
            end
        end
    end

endmodule
