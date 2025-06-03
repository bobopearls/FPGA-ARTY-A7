`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Maria Louise Quitoriano
// Testbench for send_4bit_nibble - 4-bit Initialization for Dot Matrix LCD
//////////////////////////////////////////////////////////////////////////////////

module send_4bit_nibble_2_tb();

    // Inputs
    reg clk;
    reg nrst;

    // Outputs
    wire RS;
    wire E;
    wire DB7;
    wire DB6;
    wire DB5;
    wire DB4;

    // Instantiate the Unit Under Test (UUT)
    send_4bit_nibble_2 uut (
        .clk(clk),
        .nrst(nrst),
        .RS(RS),
        .E(E),
        .DB7(DB7),
        .DB6(DB6),
        .DB5(DB5),
        .DB4(DB4)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100MHz clock period (10ns)
    end

    // Reset and simulation sequence
    initial begin
        // Initial values
        nrst = 0;

        // Wait a short time and release reset
        #50;
        nrst = 1;

        // Wait enough time to allow all initialization sequences
        #210_000_000; // 20 ms simulated time

        // Stop the simulation
        $finish;
    end

    // Monitor signal changes
    initial begin
        $display("Time\tclk\tnrst\tRS\tE\tDB7 DB6 DB5 DB4");
        $monitor("%0t\t%b\t%b\t%b\t%b\t%b   %b   %b   %b", $time, clk, nrst, RS, E, DB7, DB6, DB5, DB4);
    end

endmodule
