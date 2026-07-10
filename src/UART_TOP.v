`timescale 1ns / 1ps

module UART_TOP(
    input clk,
    input rst,
    input tx_start,
    input [7:0] tx_data,
    
    output tx,
    output tx_busy,
    
    output [7:0] rx_data,
    output rx_done,
    output parity_error
    );
    
    wire baud_tick;
    wire serial_line; // Internal Connection between TX and RX
    
    // Instantiating modules
    Baud_Rate_Generator BRG(.clk(clk), .rst(rst), .baud_tick(baud_tick));
    
    // Transmitter
    UART_TX TX(.clk(clk), .rst(rst), .baud_tick(baud_tick), .tx_start(tx_start), .tx_data(tx_data), .tx(serial_line),
               .tx_busy(tx_busy));
    
    assign tx = serial_line;
    
    // Receiver 
    UART_RX RX(.clk(clk), .rst(rst), .baud_tick(baud_tick), .rx_data(rx_data), .rx_done(rx_done), .parity_error(parity_error),
               .rx(serial_line));
    
endmodule
