`timescale 1ns / 1ps

// -----------------------------------------------------------------------------
// NOTE:
// This testbench intentionally uses manual frame generation to visualize UART
// timing and protocol behavior during module-level verification.
//
// The integrated UART_TOP_tb contains a reusable task-based verification
// environment for regression testing.
// -----------------------------------------------------------------------------

module UART_RX_tb;

    reg clk_tb, rst_tb;
    reg baud_tick_tb;
    reg rx_tb;
    
    wire [7:0] rx_data_tb;
    wire rx_done_tb;
    wire parity_error_tb;
    
    // One UART bit = 16 baud ticks = 16 × 50 ns = 800 ns
    localparam BIT_TIME = 800;
    
    UART_RX uut(.clk(clk_tb), .rst(rst_tb), .baud_tick(baud_tick_tb), .rx(rx_tb), .rx_data(rx_data_tb), .rx_done(rx_done_tb),
                .parity_error(parity_error_tb));

    always #5 clk_tb = ~clk_tb;
    
    // Baud Tick Generator (for simulation only) - now 16x oversampling tick
    initial begin
        baud_tick_tb = 0;
        forever begin
            #40 baud_tick_tb = 1;
            #10 baud_tick_tb = 0;
        end
    end
    
    initial begin
        $dumpfile("UART_RX_tb.vcd");
        $dumpvars(0, UART_RX_tb);
    end
    
    initial begin
        $monitor("Time=%0t | State=%0d | RX=%b | Data=%b | Done=%b | Parity Error = %0d | Counter=%0d | ShiftReg=%b | Parity=%b",
                  $time,
                  uut.current_state,
                  rx_tb,
                  rx_data_tb,
                  rx_done_tb,
                  uut.parity_error,
                  uut.bit_counter,
                  uut.shift_reg,
                  uut.parity_bit);
    end
    
    initial begin
        clk_tb = 0;
        rst_tb = 1;
        rx_tb  = 1;    // Idle line is HIGH
    
        // Reset
        #20;
        rst_tb = 0;
        
        // -----------------------------------------------------------------------------
        // Test 1: False Start Detection
        // Receiver should ignore this glitch.
        #100;
        rx_tb = 0;
        
        // Goes HIGH before a valid half-bit
        #200;
        rx_tb = 1;
        
        #BIT_TIME;
        
        // -----------------------------------------------------------------------------
        // Test 2: Valid UART Frame (Correct Even Parity)
        // Start bit
        #100;
        rx_tb = 0;
        
        // (LSB First)
        #BIT_TIME rx_tb = 0;
        #BIT_TIME rx_tb = 1;
        #BIT_TIME rx_tb = 0;
        #BIT_TIME rx_tb = 0;
        #BIT_TIME rx_tb = 1;
        #BIT_TIME rx_tb = 1;
        #BIT_TIME rx_tb = 0;
        #BIT_TIME rx_tb = 1;
       
        // Even Parity
        #BIT_TIME rx_tb = 0;
       
        // Stop Bit
        #BIT_TIME rx_tb = 1;
       
        #BIT_TIME;
        
        // -----------------------------------------------------------------------------
        // Test 3: Wrong Parity Detection
        #100;
        rx_tb = 1;   // idle
        
        #100;
        rx_tb = 0;
        
        // Same Data
        #BIT_TIME rx_tb = 0;
        #BIT_TIME rx_tb = 1;
        #BIT_TIME rx_tb = 0;
        #BIT_TIME rx_tb = 0;
        #BIT_TIME rx_tb = 1;
        #BIT_TIME rx_tb = 1;
        #BIT_TIME rx_tb = 0;
        #BIT_TIME rx_tb = 1;

        // Wrong Parity
        #BIT_TIME rx_tb = 1;  
        
        // Stop Bit
        #BIT_TIME rx_tb = 1;
        
        #BIT_TIME;
        // -----------------------------------------------------------------------------
        
        
        $finish;
    end
endmodule
