`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 24.04.2025 17:45:48
// Design Name: 
// Module Name: tb_rgb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: testbech to see if the 50ms works and if it will change color on ONE button press
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

// test bench
module tb_rgb;

    // inputs
    reg clk, nrst, dir, btn;
    
    //wire output
    wire rgb_r, rgb_g, rgb_b;
    
    // instantiate the UUT
    rgb UUT(
        .clk(clk),
        .nrst(nrst),
        .dir(dir),
        .btn(btn),
        .rgb_r(rgb_r),
        .rgb_g(rgb_g),
        .rgb_b(rgb_b)
    );
    
    // generate the clk (100MHz default clk, = 10ns clk period)
    always #5 clk = ~clk; // invert the clk signal every 5ns (half of 10ns clk period)
    
    // initial begin, initialize the input
    initial begin 
        clk = 0;
        nrst = 0;
        dir = 0;
        btn = 0;
        
        // start the stuff by resetting the system first for a few rounds
        #50; nrst = 1;
        
        // set the direction of the switch
        #100 dir = 0; // test first if the dir is 0
        // actual button testing starts here (simulate noise too)
        #50 btn = 1; // initial button press recorded, then add the noise
        repeat (5000) begin // bouncing for 50ms where it is toggled every 1us
            #1000 btn = ~btn; // noise simulator for 50ms to see if the debounce module works
            // the initial button press (the previous one) should not be affected by the noise here
        end
        #50_000_000 btn = 1; // stable already
        #100 btn = 0; //button released after the inital press with the noise in the middle
        
        #200 btn = 1; //press again
        #100 btn = 0; // release
        
        #100 dir = 1;
        
        #50 btn = 1; // press
        repeat (5000) begin // Simulate bouncing for 50ms noise
            #1000 btn = ~btn; // Toggle btn for noise simulation
        end
        #100 btn = 0; // Release button
        
        #10000000;
        $finish;
    end
endmodule
