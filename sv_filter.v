`default_nettype none
`timescale 1ns/1ns

module sv_filter (input wire clk,
                input wire reset,
                input signed [17:0] cutoff,
                input signed [17:0] resonance,
                input wire tvalid_slave,
                output reg tready_slave,
                input signed [15:0] tdata_slave,
                output reg tvalid_master,
                input wire tready_master,
                output reg signed [15:0] tdata_master);

    localparam STATE_INIT = 0;
    localparam STATE_IO = 1;
    localparam STATE_MULT = 2;
    reg [1:0] state;

    reg signed [17:0] input_with_fb;
    reg signed [36:0] input_product;
    reg signed [35:0] post_delay;
    wire signed [17:0] post_delay_reduced;
    reg signed [36:0] output_product;
    reg signed [38:0] feedback_product;
    reg signed [35:0] output_delayed;
    wire signed [35:0] feedback;

    reg mult_valid;
    reg decimate; // throw away every other sample, we've been oversampling up until here
    wire mult_input_ready;
    wire mult_output_ready;
    wire mult_feedback_ready;
    wire transfer_from_master;
    wire transfer_to_slave;

    wire [17:0] scaled_input;

    assign transfer_from_master = tvalid_slave & tready_slave;
    assign transfer_to_slave = tvalid_master & tready_master;

    shift_and_add_multiplier #(.WIDTH(18)
    ) input_multiplier (
        .clk(clk),
        .reset(reset),
        .factor_a(input_with_fb),
        .factor_b(cutoff),
        .input_valid(mult_valid),
        .product(input_product),
        .ready(mult_input_ready)
    );

    shift_and_add_multiplier #(.WIDTH(18)
    ) output_multiplier (
        .clk(clk),
        .reset(reset),
        .factor_a(post_delay_reduced),
        .factor_b(cutoff),
        .input_valid(mult_valid),
        .product(output_product),
        .ready(mult_output_ready)
    );

    shift_and_add_multiplier #(.WIDTH(19)
    ) feedback_multiplier (
        .clk(clk),
        .reset(reset),
        .factor_a({post_delay_reduced[17], post_delay_reduced}),
        .factor_b({1'b0, resonance}),
        .input_valid(mult_valid),
        .product(feedback_product),
        .ready(mult_feedback_ready)
    );

    assign scaled_input = {{2{tdata_slave[15]}}, tdata_slave};
    assign post_delay_reduced = post_delay[35:18];
    assign feedback = {scaled_input, 18'b0} - feedback_product[35:0] - output_delayed;

    always @(posedge clk) begin
        
        case (state)

            STATE_INIT: begin
                tready_slave <= 1;
                tvalid_master <= 1;
                state <= STATE_IO;
            end

            STATE_IO: begin
                if (transfer_from_master) begin
                    tready_slave <= 0;

                    input_with_fb <= feedback[35:18];

                    post_delay <= input_product[35:0] + post_delay;
                    output_delayed <= output_product[35:0] + output_delayed;
                    tdata_master <= output_delayed[35:20];

                    if (!tvalid_master | transfer_to_slave) begin
                        mult_valid <= 1;
                        state <= STATE_MULT;
                    end
                end
                if (transfer_to_slave) begin
                    tvalid_master <= 0;
                    if (!tready_slave) begin
                        mult_valid <= 1;
                        state <= STATE_MULT;
                    end
                end
            end

            STATE_MULT: begin
                mult_valid <= 0;
                if (mult_input_ready) begin
                    tready_slave <= 1;
                    if (!decimate) begin
                        decimate <= 1;
                        tvalid_master <= 1;
                    end
                    else begin
                        decimate <= 0;
                    end
                    state <= STATE_IO;
                end
            end

        endcase

        if (reset) begin
            state <= STATE_INIT;
            tready_slave <= 0;
            tvalid_master <= 0;
            input_with_fb <= 0;
            post_delay <= 0;
            output_delayed <= 0;
            tdata_master <= 0;
            mult_valid <= 0;
            decimate <= 0;
        end
    end

endmodule
