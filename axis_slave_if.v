module axis_slave_if #(
    parameter WORD_LENGTH = 16)
   (input wire clk,
    input wire                     clk_i2s,
    input wire                     rst,
    input wire [WORD_LENGTH-1:0] axis_data,
    input wire                     axis_valid,
    input wire                     i2s_ready,
    output reg                    i2s_valid,
    output reg                    axis_ready,
    output reg [2*WORD_LENGTH-1:0] i2s_data);

   localparam STATE_INIT = 0;
   localparam STATE_WAITING = 1;
   localparam STATE_RECEIVED = 2;
   localparam STATE_SYNC = 3;

   reg [1:0] state;
   reg falling_edge;
   reg i2s_d;

   wire transfer_from_axis;
   wire transfer_to_i2s;

   assign transfer_from_axis = axis_valid & axis_ready;
   assign transfer_to_i2s = i2s_valid & i2s_ready;

   always @(posedge clk) begin

      i2s_d <= clk_i2s;

      if(i2s_d & !clk_i2s) begin
         falling_edge <= 1;
      end
      else begin
         falling_edge <= 0;
      end
      
      case (state)
         STATE_INIT: begin
            axis_ready <= 1;
            i2s_valid <= 0;
            state <= STATE_WAITING;
         end

         STATE_WAITING: begin
            if (transfer_from_axis) begin
               i2s_data <= {axis_data, axis_data};
               axis_ready <= 0;
               i2s_valid <= 1;
               state <= STATE_RECEIVED;
            end
         end

         STATE_RECEIVED: begin
            if (transfer_to_i2s & clk_i2s) begin
               i2s_valid <= 0;
               state <= STATE_SYNC;
            end
         end

         STATE_SYNC: begin
            if (falling_edge) begin
               axis_ready <= 1;
               state <= STATE_WAITING;
            end
         end
      endcase

      if (rst) begin
         i2s_valid <= 0;
         axis_ready <= 0;
         state <= STATE_INIT;
      end
   end


endmodule