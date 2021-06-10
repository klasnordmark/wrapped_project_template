`default_nettype none
`timescale 1ns/1ns

module axi4s_multiplier #(parameter DATA_BYTES = 2)
                         (input wire clk,
                          input wire reset,
                          input wire tvalid_slave_1,
                          input signed [8*DATA_BYTES-1:0] tdata_slave_1,
                          output reg tready_slave_1,
                          input wire tvalid_slave_2,
                          input signed [8*DATA_BYTES-1:0] tdata_slave_2,
                          output reg tready_slave_2,
                          output reg tvalid_master,
                          output reg signed [8*DATA_BYTES-1:0] tdata_master,
                          input wire tready_master);

    localparam STATE_INIT = 0;
    localparam STATE_IO = 1;
    localparam STATE_MULT = 2;

    wire signed [2*8*DATA_BYTES:0] product;
    wire transfer_from_master_1;
    wire transfer_from_master_2;
    wire transfer_to_slave;

    reg signed [8*DATA_BYTES-1:0] input_a;
    reg signed [8*DATA_BYTES-1:0] input_b;
    reg [1:0] state;
    reg mult_valid;
    reg mult_ready;

    assign transfer_from_master_1 = tvalid_slave_1 & tready_slave_1;
    assign transfer_from_master_2 = tvalid_slave_2 & tready_slave_2;
    assign transfer_to_slave = tvalid_master & tready_master;

    shift_and_add_multiplier #(.WIDTH(8*DATA_BYTES)
    ) mult_inst (
        .clk(clk),
        .reset(reset),
        .factor_a(input_a),
        .factor_b(input_b),
        .input_valid(mult_valid),
        .product(product),
        .ready(mult_ready)
    );

    always @(posedge clk) begin

        case (state)

            STATE_INIT: begin
                tready_slave_1 <= 1;
                tready_slave_2 <= 1;
                tvalid_master <= 1;
                state <= STATE_IO;
            end

            STATE_IO: begin
                if (transfer_from_master_1) begin
                    input_a <= tdata_slave_1;
                    tready_slave_1 <= 0;
                    if ((transfer_from_master_2 | !tready_slave_2) & (transfer_to_slave | !tvalid_master)) begin
                        mult_valid <= 1;
                        state <= STATE_MULT;    
                    end             
                end
                if (transfer_from_master_2) begin
                    input_b <= tdata_slave_2;
                    tready_slave_2 <= 0;
                    if ((transfer_from_master_1 | !tready_slave_1) & (transfer_to_slave | !tvalid_master)) begin
                        mult_valid <= 1;
                        state <= STATE_MULT;
                    end 
                end
                if (transfer_to_slave) begin
                    tvalid_master <= 0;
                    if ((transfer_from_master_1 | !tready_slave_1) & (transfer_from_master_2 | !tready_slave_2)) begin
                        mult_valid <= 1;
                        state <= STATE_MULT;
                    end 
                end
            end

            STATE_MULT: begin
                mult_valid <= 0;
                if (mult_ready) begin
                    tdata_master <= product[2*8*DATA_BYTES-2:8*DATA_BYTES-1];
                    tready_slave_1 <= 1;
                    tready_slave_2 <= 1;
                    tvalid_master <= 1;
                    state <= STATE_IO;
                end
            end

        endcase

        if (reset) begin
            state <= STATE_INIT;
            tready_slave_1 <= 0;
            tready_slave_2 <= 0;
            tvalid_master <= 0;
            input_a <= 0;
            input_b <= 0;
            mult_valid <= 0;
            tdata_master <= 0;
        end
    end
    
endmodule