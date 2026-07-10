`timescale 1ns / 1ps

module UART_TOP_tb;

    reg clk_tb, rst_tb;
    reg tx_start_tb;
    reg [7:0] tx_data_tb;
    
    wire tx_tb, tx_busy_tb;
    wire rx_done_tb;
    wire [7:0] rx_data_tb;
    wire parity_error_tb;
    
    // Instaniation 
    UART_TOP uut(.clk(clk_tb), .rst(rst_tb), .tx_start(tx_start_tb), .tx_data(tx_data_tb), .tx(tx_tb), .tx_busy(tx_busy_tb),
                 .rx_done(rx_done_tb), .rx_data(rx_data_tb), .parity_error(parity_error_tb));
    
    // Clock Generator            
    always #5 clk_tb = ~clk_tb;
    
    // Verification Variables 
    integer pass_count;
    integer fail_count;
    integer total_tests;
    
    initial begin
        clk_tb = 0;
        pass_count  = 0;
        fail_count  = 0;
        total_tests = 0;
    end
    // Waveform Dump for online EDA tools.
    initial begin
        $dumpfile("UART_TOP_tb.vcd");
        $dumpvars(0, UART_TOP_tb);
    end
    
    // Monitor
    initial begin
        $monitor(
            "Time=%0t | TX=%b | Busy=%b | RX Data=%8b | RX Done=%b | Parity Error=%b",
            $time,
            tx_tb,
            tx_busy_tb,
            rx_data_tb,
            rx_done_tb,
            parity_error_tb
        );
    end
    
    // Tasks
    
    // 1. Reset DUT
    task reset_dut;
    begin
        rst_tb = 1;
        tx_start_tb = 0;
        tx_data_tb  = 8'b0;
    
        repeat (2)
            @(posedge clk_tb);
    
        rst_tb = 0;
    
        @(posedge clk_tb);
    end
    endtask
    
    // 2. To transmit one byte through the UART
    task send_byte;
        input [7:0] data;
    begin
        tx_data_tb = data;
    
        // Generate a one-clock start pulse
        tx_start_tb = 1'b1;
        @(posedge clk_tb);
        tx_start_tb = 1'b0;
    
        // Wait until transmitter actually starts
        wait (tx_busy_tb == 1'b1);
        @(posedge clk_tb);
    
        // Wait until receiver finishes
        wait (rx_done_tb == 1'b1);
        @(posedge clk_tb);
    
        // Wait until transmitter returns to idle
        wait (tx_busy_tb == 1'b0);
        @(posedge clk_tb);
    
    end
    endtask
    
    // 3. To check result
    task check_result;
        input [7:0] expected_data;
        input expected_parity_error;
    
    begin
        total_tests = total_tests + 1;
        if ((rx_data_tb == expected_data) && (parity_error_tb == expected_parity_error)) begin
            pass_count = pass_count + 1;
            $display("----------------------------------------");
            $display("TEST %0d : PASS", total_tests);
            $display("Expected Data        : %8b", expected_data);
            $display("Received Data        : %8b", rx_data_tb);
            $display("Expected Parity Error: %b", expected_parity_error);
            $display("Received Parity Error: %b", parity_error_tb);
            $display("----------------------------------------");
        
        end
        else begin
        
            fail_count = fail_count + 1;
        
            $display("----------------------------------------");
            $display("TEST %0d : FAIL", total_tests);
            $display("Expected Data        : %8b", expected_data);
            $display("Received Data        : %8b", rx_data_tb);
            $display("Expected Parity Error: %b", expected_parity_error);
            $display("Received Parity Error: %b", parity_error_tb);
            $display("----------------------------------------");
        
        end
    end
    endtask
    
    // 4. Print test summary
    task print_summary;
    begin
        $display("\n========================================");
        $display("        UART TOP VERIFICATION");
        $display("========================================");
        $display("Total Tests : %0d", total_tests);
        $display("Passed      : %0d", pass_count);
        $display("Failed      : %0d", fail_count);
        $display("========================================");
    
        if (fail_count == 0)
            $display("OVERALL RESULT : PASS");
        else
            $display("OVERALL RESULT : FAIL");
    
        $display("========================================\n");
    end
    endtask
    
  
    initial begin
        clk_tb      = 0;
        rst_tb      = 0;
        tx_start_tb = 0;
        tx_data_tb  = 8'b0;
    
    // Test 1: Basic loopback
    reset_dut();
    send_byte(8'b10110010);
    check_result(8'b10110010, 1'b0);
    
    // Test 2: All 0's
    reset_dut();
    send_byte(8'b00000000);
    check_result(8'b00000000, 1'b0);
    
    // Test 3: All 1's
    reset_dut();
    send_byte(8'b11111111);
    check_result(8'b11111111, 1'b0);
    
    // Test 4: Back to back frames
    reset_dut();
    send_byte(8'b00110011);
    check_result(8'b00110011, 1'b0);
    
    send_byte(8'b11000011);
    check_result(8'b11000011, 1'b0);
    
    send_byte(8'b11110000);
    check_result(8'b11110000, 1'b0);
    
    // Print summary
     print_summary();
    $finish;
    end
endmodule
