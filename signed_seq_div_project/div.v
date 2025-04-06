`timescale 1ns / 1ps

// function: signed sequential divider using a non restoring division algoritm (for 32 bit input and output)
// top module, div
// Quitoriano 2022*****, CoE 111 ME5

module div(
    input clk, nrst, en,
    input signed [31:0] opA, opB,
    output done,
    output [31:0] res
);
    wire init, shift_left, addt, subt, res_LSB, latch; // control wires
    wire sign_bit, sign_bit_choose_addsub, prev_res_MSB; // LSB and MSBs. combinational.
    wire [5:0] count;
    wire [32:0] temp_out, divisor_out;
    wire [31:0] res_out; // temp, divisor, and res are outputs
    
    //instantiating the registers and controller
    // dp = datapath, ctrl = controller
    res_mod dp_res(
        .clk(clk), .nrst(nrst), .init(init), .res_LSB(res_LSB),
        .done(done), .shift_left(shift_left), .latch(latch),
        .opA(opA), .opB(opB),
        .sign_bit(sign_bit),
        .res(res_out),
        .prev_res_MSB(prev_res_MSB)
    );
    
    divisor dp_divisor(
        .clk(clk), .nrst(nrst), .init(init),
        .opB(opB),
        .divisor(divisor_out)
    );
    
    temp dp_temp(
        .clk(clk), .nrst(nrst), .init(init), .shift_left(shift_left), .addt(addt), .subt(subt),
        .divisor(divisor_out),
        .prev_res_MSB(prev_res_MSB),
        .sign_bit(sign_bit), .sign_bit_choose_addsub(sign_bit_choose_addsub),
        .temp(temp_out)
    );
    
    counter dp_counter(
        .clk(clk), .nrst(nrst), .init(init), .dec_counter(res_LSB),
        .count(count)
    );
    
    div_controller div_ctrl(
        .clk(clk), .nrst(nrst), .en(en), .sign_bit(sign_bit), .sign_bit_choose_addsub(sign_bit_choose_addsub),
        .count(count), .opA(opA), .opB(opB),
        .init(init), .shift_left(shift_left), .addt(addt), .subt(subt), .res_LSB(res_LSB), .latch(latch), .done(done)
    );
    
    assign res = res_out;
endmodule

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// start of the datapath
// module, res: this is where we compute all of the results
module res_mod(
    input clk, nrst, init, res_LSB, done, // last 3 are control signals
    input shift_left, latch,
    input signed [31:0] opA, opB, // we only need opB for the MSB for xor
    input sign_bit, // this is the updated bit from temp (after addt or subt)
    output reg [31:0] res,
    output wire prev_res_MSB
);
    wire sign;
    assign sign = opA[31] ^ opB[31];
    
    assign prev_res_MSB = res[31]; // also combinational now for the same reasons that sign bits in temp are combinational
    always@(posedge clk or negedge nrst)begin
        if(!nrst)begin
            res <= 32'b0;  // clear res
            //prev_res_MSB <= 1'b0;
        end else begin
            if(init)begin
                if(opA == 32'b0 && opB == 32'b0)begin
                    res <= 32'h00000001; // because we cannot divide when the thing we want to divide is 0
                    // but we still need to continue the division
                end else begin
                    //sign <= opA[31] ^ opB[31];
                    res <= opA[31] ? -opA : opA; // getting the abs. value
                    //prev_res_MSB <= 1'b0;
                end
            end else if (res_LSB) begin
                //prev_res_MSB <= res[31]; // but this one needs the bit from the old res fix: take from the addt subt
                res <= {res[30:0], sign_bit ? 1'b0 : 1'b1}; // this already uses the new res
                // replacing the last bit based on the temp MSB from the addt or subt stage
            end else if(latch) begin
                res <= (sign) ? -res : res; // sign correction
                                            // this is the actual final answer where done = 1
            end
        end
    end
endmodule

// module, divisor: this is where the opB changes happen in the beginning
module divisor(
    input clk, nrst, init, 
    input [31:0] opB,
    output reg signed [32:0] divisor // 33 bits because we account for the extra one bit at the MSB
);
    always@(posedge clk or negedge nrst)begin
        if(!nrst)
            divisor <= 33'b0; // clearing it
        else if(init)
            divisor <= opB[31] ? {1'b0, -opB} : {1'b0, opB}; 
            // abs. value of opB with sign extend since divisor is 33 bits, and opB is only 32
            // properly handles 33 bits and in the case that opB is 0 in decimal
    end
endmodule

// module, temp: this is where the temporary value is stored for the left blocks
module temp(
    input clk, nrst, init, shift_left, addt, subt,
    input [32:0] divisor,
    input prev_res_MSB,
    output wire sign_bit, sign_bit_choose_addsub,
    output reg signed [32:0] temp
);

    //reg [32:0] divisor;
    //reg [31:0] res;
    //reg sign_bit_prev; // previous sign bit
    //assign sign_bit = temp[32]; // directly assign instead
    // better implementation! now it purely handles temp only
    //reg signed [32:0] temp_addt_subt;
    assign sign_bit_choose_addsub = temp[32]; // now combinational. get the old sign bit before we start the implementation.
    always@(posedge clk or negedge nrst)begin
        if(!nrst)begin
            temp <= 33'b0;
        end else if(init)begin
            temp <= 33'b0;
        end else if(shift_left)begin
            temp <= {temp[31:0], prev_res_MSB};
            //sign_bit <= temp[32]; also combinational now
        end else if(addt)begin
            temp <= temp + divisor; 
            //sign_bit <= temp[32]; // update after all that for the res_LSB (also changed to combinational)
        end else if(subt)begin
            temp <= temp - divisor;
            //sign_bit <= temp[32]; // update after all that for the res_LSB (changed to combinational)
        end // sign bit needed to determine the res lsb
    end 
    assign sign_bit = temp[32]; // this is combinational logic that will immediately give the correct temp MSB to determine res LSB
                                // get the new sign bit AFTER the calculation
    
endmodule

// module, counter: decrements counts for every iteration
module counter(
    input clk, nrst, init, dec_counter,
    output reg [5:0] count // max we will set the count to is 32 (in decimal)
);
    //reg [5:0] count;
    always@(posedge clk or negedge nrst)begin
        if(!nrst)
            count <= 6'b0;
        else if(init)
            count <= 6'd32;
        else if (dec_counter)
            count <= count - 6'd1;
    end
endmodule

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// start of the controller
module div_controller(
    input clk, nrst, en, sign_bit, sign_bit_choose_addsub,
    input [5:0] count,
    input [31:0] opA, opB, // in the case if both are 0, indeterminate or if opA is 0, cannot divide
    output reg init, shift_left, addt, subt, res_LSB, dec_counter, latch, done
);
    //reg [5:0] count;
    // states:
    parameter S_idle = 3'b000; //0, we are just in this state until en is asserted as 1
    parameter S_shift_left = 3'b001; //1, this is for 
    parameter S_add_sub = 3'b010; // 2, combine addt and subt to one state since only one should be active at a time anyway
    //parameter S_addt = 3'b011;
    //parameter S_subt = 3'b100;
    parameter S_res_LSB = 3'b011; //3
    parameter S_dec_count = 3'b100; //4
    parameter S_latch = 3'b101; //5, new state so that the answer is correct even before done is asserted
    parameter S_wait = 3'b110; //6, new state: buffer
    parameter S_done = 3'b111; //7
    
    reg [2:0] curr_state, next_state;
    always@(posedge clk or negedge nrst)begin
        if(!nrst)begin
            curr_state <= S_idle;
        end else begin
            curr_state <= next_state;
        end
    end

    // Register the done signal so it only updates on posedge clk
    always @(posedge clk or negedge nrst) begin
        if (!nrst) begin
            done <= 1'b0;
        end else begin
            case (curr_state)
                S_idle: begin
                    if (en) 
                        done <= 1'b0; // Clear done when operation starts
                    else 
                        done <= 1'b1; // Hold done high until next operation
                end
                S_latch: begin
                    done <= 1'b0; // Ensure done is cleared
                end
                S_done: begin
                    done <= 1'b1; // Assert done on posedge clk
                end
                default: begin
                    done <= done; // Hold previous state
                end
            endcase
        end
    end

    // next state, combinational logic
    always@(*)begin
        next_state = curr_state;
        case(curr_state)
            S_idle: begin
                if(en) begin
                    if(opA == 32'b0 && opB == 32'b0)begin
                        next_state = S_latch;
                    end else begin
                        next_state = S_shift_left;
                    end
                end
            end
            S_shift_left: begin
                next_state = S_add_sub;
            end   
            S_add_sub: begin
                next_state = S_res_LSB;
            end
            S_res_LSB: begin
                next_state = S_dec_count;
            end
            S_dec_count: begin
                if (count == 6'd0) next_state = S_latch; // latch and hold on to the value before we assert done
                else next_state = S_shift_left;
            end
            S_latch: begin
                next_state = S_wait;
            end
            S_wait:begin
                next_state = S_done;
            end
            S_done: begin
                if(!en) next_state = S_idle;
            end
            default: next_state = S_idle;
        endcase
    end
    
    // output ctrl signals
    always@(*)begin
        init = 1'b0;
        shift_left = 1'b0;
        addt = 1'b0;
        subt = 1'b0;
        res_LSB = 1'b0;
        dec_counter = 1'b0;
        //done = 1'b0;
        latch = 1'b0;

        case(curr_state)
            S_idle: begin
                if(en) init = 1;
                //else done = 1; // continuation of the done signal from the previous inputs before en is enabled again
            end
            S_shift_left: begin
                shift_left = 1'b1;
            end
            S_add_sub: begin
                if(sign_bit_choose_addsub) addt = 1'b1;
                else subt = 1'b1;
            end
            S_res_LSB: begin
                res_LSB = 1'b1;
            end
            S_dec_count: begin
                dec_counter = 1'b1;
            end
            S_latch: begin
                latch = 1'b1; // this is for the condition in res
                //done = 1'b0; // ensures that done will never be set to 1
            end
            S_wait: begin
                latch = 1'b0;
                //done = 1'b0; // ensures that done will never be set to 1 (not really needed, I just want to make sure)
            end
            //S_done: begin
                //done = 1'b1; // the done signal has to continue until the next inputs
            //end
        endcase
    end
endmodule
