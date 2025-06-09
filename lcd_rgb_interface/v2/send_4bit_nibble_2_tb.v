`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Maria Louise Quitoriano
// Testbench for send_4bit_nibble_2 - 4-bit Initialization for Dot Matrix LCD
//////////////////////////////////////////////////////////////////////////////////

module send_4bit_nibble_2_tb();

    // Inputs
    reg clk;
    reg nrst;

    // Outputs
    wire RS_init;
    wire E_init;
    wire [3:0] data_bits;

    // Instantiate the Unit Under Test (UUT)
    send_4bit_nibble_2 uut (
        .clk(clk),
        .nrst(nrst),
        .RS_init(RS_init),
        .E_init(E_init),
        .data_bits(data_bits)
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
        $display("Time\tclk\tnrst\tRS_init\tE_init\tdata_bits");
        $monitor("%0t\t%b\t%b\t%b\t%b\t%04b", $time, clk, nrst, RS_init, E_init, data_bits);
    end

endmodule
