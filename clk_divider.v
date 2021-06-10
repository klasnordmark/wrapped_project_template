module clk_divider
  (input wire clk_in,
   input wire rst,
   input wire [15:0] divisor,
   output reg clk_out);

   reg [15:0] counter;

   always @(posedge clk_in) begin
         if (counter < divisor-1) begin
            counter <= counter + 1;
         end else begin
            clk_out <= ~clk_out;//clk_out + 1;
            counter <= 0;
         end
         if (rst) begin
            counter <= 0;
            clk_out <= 0;
         end
   end

endmodule