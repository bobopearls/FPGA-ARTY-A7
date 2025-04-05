// taken from ME1, edited for ME6

`timescale 1ns/1ps

module fdiv_1Hz(
    input      clk, // clk input on board 100 MHz. 100MHz to 1Hz for changing every 1s
    input      nrst,
    output reg div_clk
);
    
    reg [31:0] count;
    
    localparam [31:0] delay = 32'd50_000_000; // toggle every 1M cycles (2,000,000 cycles /2)
    
    always @(posedge clk or negedge nrst) begin
        if (!nrst) begin
            count   <= 0;
            div_clk <= 0;
        end else begin
            if (count == delay - 1) begin
                count   <= 0;
                div_clk <= ~div_clk;
            end else begin
                count   <= count + 1'b1;
            end
        end
    end
    
endmodule