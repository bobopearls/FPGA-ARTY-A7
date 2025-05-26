// second attempt at making the initialization cleaner with states
// it is very hard to keep track of the count if the states are not specified

module 4_bit_lcd_init(
  input clk, nrst, 
  output [3:0] DB_init, // we use DB7 to DB 4
  output RS, RW, E // these are outputs that are also needed to send out
);

  // setting the states needed for initiaization | set the number of bits for these later
  parameter S_idle = d'0;
  parameter S_func_set_1 = d'1;
  parameter S_wait_4.1ms = d'2;
  parameter S_func_set_2 = d'3;
  parameter S_wait_100us = d'4;
  parameter S_func_set_3 = d'5;
  parameter S_func_set_4 = d'6;
  
  // starting the 5th func_set, there are upper and lower half nibbles we have to deal with
  parameter S_func_set_5_upper = d'7;
  parameter S_func_set_5_lower = d'8; // set N and F here (N=1 for two line disp | F=0 for 5x7 dots ? or is it 5x10)
  // starting this instruction, we have to check the BF 
  parameter S_display_off_upper = d'9;
  parameter S_display_off_lower = d'10;
  
  parameter S_clear_disp_upper = d'11;
  parameter S_clear_disp_lower = d'12;
  
  parameter S_entry_mode_upper = d'13;
  parameter S_entry_mode_lower = d'14; // I/D = 1 for increment cursor | S=0 for display shift
  
  parameter S_disp_on_upper = d'15;
  parameter S_disp_on_lower = d'16; // C=1 for show cursor location | B= for blink where the cursor is
  
  parameter S_init_done = d'17;
  
  
