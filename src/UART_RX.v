`timescale 1ns / 1ps

module UART_RX(
    input clk,
    input rst,
    input baud_tick,
    input rx,
    
    output reg [7:0] rx_data,
    output reg rx_done,
    output reg parity_error
    );
    
    // Internal Registers
    reg [7:0] shift_reg;
    reg [3:0] bit_counter;
    reg [3:0] sample_counter; // Counts till middle of each bit 
    reg parity_bit;
    
    reg [3:0] current_state, next_state;
    
    // FSM States
    localparam IDLE = 3'b000;
    localparam START = 3'b001;
    localparam DATA = 3'b010;
    localparam PARITY = 3'b011;
    localparam STOP = 3'b100;
    
    // Sequential FSM with registered outputs block
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            current_state <= IDLE;
            shift_reg <= 8'b0;
            bit_counter <= 0;
            sample_counter <=0;
            parity_bit <= 0;
            rx_data    <= 8'b0;
            rx_done    <= 1'b0;
            parity_error <= 1'b0;
        end
        
        else begin
            current_state <= next_state;
            
            case (current_state)
                IDLE: begin
                    bit_counter <= 0;
                    sample_counter <= 0;
                    rx_done <= 0;
                    parity_error  <= 0;
                end
                
                START: begin
                    if (baud_tick) begin
                        if (sample_counter == 8) begin
                            sample_counter <= 0;  // reset for DATA's first bit
                        end
                        else begin
                            sample_counter <= sample_counter + 1;
                        end
                    end
                end
                
                DATA: begin
                    if (baud_tick) begin
                        if (sample_counter == 15) begin
                            shift_reg <= {rx, shift_reg[7:1]}; // Each LSB enters as MSB first then shifts to reach final spot.
                            bit_counter <= bit_counter + 1;
                            sample_counter <= 0;              // reset for the next bit
                        end
                    else begin
                        sample_counter <= sample_counter + 1;
                        end
                    end
               end    
               
               PARITY: begin
                    if (baud_tick) begin
                        if (sample_counter == 15) begin
                        parity_bit <= rx; // We receive the parity bit now
                        sample_counter <= 0;
                        end
        
                        else begin
                            sample_counter <= sample_counter + 1;
                            end
                        end
                    end
                    
               STOP: begin
                    if (baud_tick) begin
                        if (sample_counter == 15) begin
                        rx_data <= shift_reg;
                        rx_done <= 1'b1;
                        sample_counter <= 0;
                        
                        // Parity check
                        if (parity_bit  == ^shift_reg)
                            parity_error <= 1'b0;
                        else
                            parity_error <= 1'b1;
                        end
                        
                        else begin
                            sample_counter <= sample_counter + 1;
                        end
                    end
               end
           endcase
        end             
    end
    
    always @(*) begin
        next_state = current_state;
        case (current_state)
            IDLE:   if (rx == 0) next_state = START;
            
            START: begin
                if (baud_tick && sample_counter == 8) begin
                    if (rx == 0)
                        next_state = DATA;   // confirmed real start bit
                    else
                        next_state = IDLE;   // false start detected
                end
            end
                        
            DATA: if (baud_tick && sample_counter == 15 && bit_counter == 7) next_state = PARITY;
            
            PARITY: if (baud_tick && sample_counter == 15) next_state = STOP;
            
            STOP:   if (baud_tick && sample_counter == 15) next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end         
endmodule
