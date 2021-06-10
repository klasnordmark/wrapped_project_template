`default_nettype none
`timescale 1ns/1ns

module shift_and_add_multiplier #(parameter WIDTH = 16)
                                 (input wire clk,
                                  input wire reset,
                                  input signed [WIDTH-1:0] factor_a,
                                  input signed [WIDTH-1:0] factor_b,
                                  input wire input_valid,
                                  output signed [2*WIDTH:0] product,
                                  output reg ready);
    
    localparam COUNTER_MAX = WIDTH;
    
    reg signed [WIDTH-1:0] input_a;
    reg [$clog2(WIDTH-1):0] counter;
    reg signed [2*WIDTH:0] product_internal;
    wire signed [2*WIDTH:0] product_shifted;
    
    wire transaction;
    
    assign transaction = input_valid;
    assign product_shifted = product_internal >>> 1;
    assign product = product_shifted;
    
    always @(posedge clk) begin
        if (transaction) begin
            if (factor_a < 0) begin
                input_a            <= ~factor_a+1;
                product_internal[WIDTH-1:0] <= ~factor_b+1;
            end
            else begin
                input_a <= factor_a;
                product_internal[WIDTH-1:0] <= factor_b;
            end
            product_internal[2*WIDTH:WIDTH]   <= {input_a[WIDTH-1], {(WIDTH){1'b0}}};
            counter                  <= 1;
            ready                    <= 0;
        end
        
        ready <= 0;

        if (counter > 0) begin
            if (product_internal[0] == 1) begin
                if (counter == COUNTER_MAX) begin
                    product_internal[2*WIDTH:WIDTH] <= product_shifted[2*WIDTH:WIDTH] - input_a;
                    product_internal[WIDTH-1:0] <= product_shifted[WIDTH-1:0];
                end
                else begin
                    product_internal[2*WIDTH:WIDTH] <= product_shifted[2*WIDTH:WIDTH] + input_a;
                    product_internal[WIDTH-1:0] <= product_shifted[WIDTH-1:0];
                end
            end
            else begin
                product_internal <= product_shifted;
            end
            if (counter == COUNTER_MAX) begin
                    ready <= 1;
                    counter <= 0;
            end
            else begin
                    counter <= counter + 1;
            end
        end
        
        if (reset) begin
            input_a <= 0;
            counter <= 0;
            product_internal <= 0;
            ready   <= 0;
        end
        
    end
    
endmodule