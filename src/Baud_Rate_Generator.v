`timescale 1ns / 1ps

module Baud_Rate_Generator(
    input clk,
    input rst,
    output reg baud_tick
    );
    
    // CLK_FREQ & BAUD_RATE are declared as parameters to change their values if needed without touching source module
    parameter CLK_FREQ = 100_000_000; // 100 MHz
    parameter BAUD_RATE = 9600;
    
    // Number of system clock cycles per UART bit
    localparam BAUD_DIV = CLK_FREQ/(16 * BAUD_RATE);
    
    reg [$clog2(BAUD_DIV) - 1: 0]counter; // SystemVerilog feature to directly calculate the number of bits required.
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            counter   <= 0;
            baud_tick <= 0;
        end
        else begin
            if (counter == BAUD_DIV - 1) begin
                counter   <= 0;
                baud_tick <= 1;
            end
            else begin
                counter   <= counter + 1;
                baud_tick <= 0;
            end
        end
    end
endmodule
