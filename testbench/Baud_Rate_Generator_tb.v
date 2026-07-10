`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06.07.2026 22:51:45
// Design Name: 
// Module Name: Baud_Rate_Generator_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module Baud_Rate_Generator_tb;

    reg clk_tb;
    reg rst_tb;
    wire baud_tick_tb;
    
    //-------------------------------------------------------------------------
    // Parameter override is used to reduce simulation time.
    // Original values:
        //   CLK_FREQ  = 100_000_000 Hz
        //   BAUD_RATE = 9600
        
    // Testbench values:
        //   CLK_FREQ  = 1600 Hz
        //   BAUD_RATE = 10x
        
        // NOTE: BAUD_DIV must be at least 1.
    //-------------------------------------------------------------------------
    Baud_Rate_Generator #(.CLK_FREQ(1600), .BAUD_RATE(10))
     uut(
        .clk(clk_tb), .rst(rst_tb), .baud_tick(baud_tick_tb));

    always #5 clk_tb = ~clk_tb;
    
    initial begin
        $dumpfile("baud_Rate_Generator_tb.vcd");
        $dumpvars(0, Baud_Rate_Generator_tb);
    end
    
    initial begin
        $monitor("Time=%0t rst=%b counter=%0d baud_tick=%b", $time, rst_tb, uut.counter, baud_tick_tb);
    end
    
    initial begin
        // Initialize signals
        clk_tb = 0;
        rst_tb = 1;
        
        // Hold reset for two clock cycles
        #20;
        rst_tb = 0;

        // Observe multiple baud tick pulses
        #300;
        $finish;
    end
    
endmodule