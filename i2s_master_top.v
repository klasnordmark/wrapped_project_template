module i2s_master_top
   (input wire clk,
    input wire                     rst,
    input wire [15:0] divisor,
    input wire [15:0] axis_data,
    input wire                     axis_valid,
    output reg                     axis_ready,
    output wire clk_i2s_out,
    output reg                     serial_data,
    output reg                     word_select);

   wire                     clk_i2s;
   wire [31:0] i2s_data;
   wire                     i2s_ready;
   wire                     i2s_valid;

   assign clk_i2s_out = clk_i2s;

   clk_divider clk_divider_0 (
     .clk_in(clk),
     .rst(rst),
     .divisor(divisor),
     .clk_out(clk_i2s));

   axis_slave_if #(
     .WORD_LENGTH(16)
   ) axi4s_slave_0 (
     .clk(clk),
     .clk_i2s(clk_i2s),
     .rst(rst),
     .axis_data(axis_data),
     .axis_valid(axis_valid),
     .i2s_ready(i2s_ready),
     .i2s_valid(i2s_valid),
     .axis_ready(axis_ready),
     .i2s_data(i2s_data));
   

   i2s_master #(
     .WORD_LENGTH(16)
   ) i2s_master_0 (
     .clk(clk_i2s),
     .rst(rst),
     .data(i2s_data),
     .data_valid(i2s_valid),
     .data_ready(i2s_ready),
     .serial_data(serial_data),
     .word_select(word_select));

endmodule