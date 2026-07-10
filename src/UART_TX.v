`timescale 1ns / 1ps

module UART_TX(
    input clk,
    input rst,
    input baud_tick,
    input tx_start,
    input [7:0] tx_data,
    output reg tx,
    output reg tx_busy
    );
    
    // Internal registers
    reg [7:0] shift_reg;
    reg [2:0] bit_counter;
    reg [3:0] tick_counter;  // counts 0-15 within each bit period
    reg parity_bit;
    
    reg [2:0] current_state, next_state;
    
    // FSM States
    localparam IDLE = 3'b000;
    localparam START = 3'b001;
    localparam DATA = 3'b010;
    localparam PARITY = 3'b011;
    localparam STOP = 3'b100;
    
    // Sequential Logic Block
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            current_state <= IDLE;
            bit_counter <= 0;
            tick_counter <= 0;
            tx <= 1'b1;
            tx_busy <= 1'b0;
            shift_reg <= 8'b0;
            parity_bit <= 1'b0;
        end
        
        else begin
            current_state <= next_state; 
            
            case (current_state)
            
                IDLE: begin
                    tx <= 1'b1;
                    tx_busy <= 1'b0;
                    tick_counter <= 0;
                    if (tx_start) begin
                        shift_reg   <= tx_data;
                        parity_bit  <= ^tx_data; // Reduction XOR operator. It XOR's all the bits and check whether parity is 0 or 1.
                        bit_counter <= 0;
                    end
                end
            
                START: begin
                    tx <= 1'b0;
                    tx_busy <= 1'b1;
                    if (baud_tick) begin
                        if (tick_counter == 15) begin
                            tick_counter <= 0;
                        end
                        else begin
                            tick_counter <= tick_counter + 1;
                        end
                    end
                end
                
                DATA: begin
                    tx      <= shift_reg[0]; 
                    tx_busy <= 1'b1;
                    if (baud_tick) begin
                        if (tick_counter == 15) begin
                            tx <= shift_reg[0];
                            shift_reg <= shift_reg >> 1;
                            bit_counter <= bit_counter + 1;
                            tick_counter <= 0;
                        end
                        else begin
                            tick_counter <= tick_counter + 1;
                        end
                    end
                end
                
                PARITY: begin
                    tx      <= parity_bit;
                    tx_busy <= 1'b1;
                    if (baud_tick) begin
                        if (tick_counter == 15) begin
                            tx <= parity_bit;
                            tick_counter <= 0;
                        end
                        else begin
                            tick_counter <= tick_counter + 1;
                        end
                    end
                end
            
                STOP: begin
                    tx      <= 1'b1;
                    tx_busy <= 1'b1;
                    if (baud_tick) begin
                        if (tick_counter == 15) begin
                            tx <= 1'b1;
                            tick_counter <= 0;
                        end
                        else begin
                            tick_counter <= tick_counter + 1;
                        end
                    end
                end
            endcase
        end
    end
    
    // Combinational Next-State Logic Block
    always @(*) begin
        next_state = current_state; // Default
        
        case(current_state)
            IDLE: if (tx_start)
                    next_state = START;
                    
            START: if (baud_tick && tick_counter == 15) next_state = DATA;
            
            DATA: if (baud_tick && tick_counter == 15 && bit_counter == 7)
                    next_state = PARITY;
                    
            PARITY: if (baud_tick && tick_counter == 15) next_state = STOP;
            
            STOP: if (baud_tick && tick_counter == 15) next_state = IDLE;
            default:
                  next_state = IDLE;
        endcase           
    end
    
    // Output Combinational Block- Not needed as the FSM design is Moore FSM with registered outputs.
    
endmodule
