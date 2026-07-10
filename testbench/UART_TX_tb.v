`timescale 1ns / 1ps

// -----------------------------------------------------------------------------
// NOTE:
// This testbench intentionally uses manual stimulus generation to visualize
// UART transmission timing and FSM behavior during module-level verification.
//
// The integrated UART_TOP_tb contains a reusable task-based verification
// environment for regression testing.
// -----------------------------------------------------------------------------

module UART_TX_tb;

    reg clk_tb, rst_tb;
    reg tx_start_tb;
    reg [7:0] tx_data_tb;
    reg baud_tick_tb;

    wire tx_tb, tx_busy_tb;

    // -------------------------------------------------------------------------
    // Timing Parameters
    // One UART bit = 16 baud ticks
    // Baud tick period = 50 ns
    // Therefore:
    //     BIT_TIME   = 16 × 50 ns = 800 ns
    //     FRAME_TIME = Start + 8 Data + Parity + Stop = 11 bits
    // -------------------------------------------------------------------------
    localparam BIT_TIME   = 800;
    localparam FRAME_TIME = 11 * BIT_TIME;

    UART_TX uut(.clk(clk_tb), .rst(rst_tb), .tx_start(tx_start_tb), .tx_data(tx_data_tb), .baud_tick(baud_tick_tb),
                .tx(tx_tb), .tx_busy(tx_busy_tb));

    always #5 clk_tb = ~clk_tb;

    // Baud Tick Generator (for simulation)
    initial begin
    baud_tick_tb = 0;
        forever begin
            #40 baud_tick_tb = 1;
            #10 baud_tick_tb = 0;
        end
    end

    initial begin
        $dumpfile("UART_TX_tb.vcd");
        $dumpvars(0, UART_TX_tb);
    end

    initial begin
        $monitor("Time=%0t | State=%0d | TX=%b | Busy=%b | Counter=%0d | ShiftReg=%b | Parity=%b",
                  $time,
                  uut.current_state,
                  tx_tb,
                  tx_busy_tb,
                  uut.bit_counter,
                  uut.shift_reg,
                  uut.parity_bit);
    end

    initial begin
        clk_tb      = 0;
        rst_tb      = 1;
        tx_start_tb = 0;
        tx_data_tb  = 8'b0;

        // Reset
        #20;
        rst_tb = 0;

        // ---------------------------------------------------------------------
        // Test 1 : Single Byte Transmission (Even Parity)
        
        tx_data_tb = 8'b1011_0010;
        #10;
        tx_start_tb = 1;
        #10;
        tx_start_tb = 0;

        #FRAME_TIME;

        // ---------------------------------------------------------------------
        // Test 2 : Single Byte Transmission (Odd Parity)
        
        tx_data_tb = 8'b1111_0010;
        #10;
        tx_start_tb = 1;
        #10;
        tx_start_tb = 0;

        #FRAME_TIME;

        // ---------------------------------------------------------------------
        // Test 3 : Back-to-Back Transmission

        tx_data_tb = 8'b1100_1100;
        #10;
        tx_start_tb = 1;
        #10;
        tx_start_tb = 0;

        // Start second frame immediately after the first one completes
        #FRAME_TIME;

        tx_data_tb = 8'b0011_0011;
        #10;
        tx_start_tb = 1;
        #10;
        tx_start_tb = 0;

        #FRAME_TIME;

        // ---------------------------------------------------------------------
        // Test 4 : Hold tx_start High
        
        tx_data_tb = 8'b1010_1010;
        #10;
        tx_start_tb = 1;

        // Keep asserted for multiple clock cycles
        #200;

        tx_start_tb = 0;

        #FRAME_TIME;

        // ---------------------------------------------------------------------
        // Test 5 : Reset During Transmission
        
        tx_data_tb = 8'b1111_0000;
        #10;
        tx_start_tb = 1;
        #10;
        tx_start_tb = 0;

        // Reset after a few transmitted bits
        #(3 * BIT_TIME);

        rst_tb = 1;
        #20;
        rst_tb = 0;

        #FRAME_TIME;

        $finish;
    end

endmodule