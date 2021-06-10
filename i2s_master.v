module i2s_master #(
    parameter WORD_LENGTH = 16
) (
    input wire clk,
    input wire rst,
    input wire [2*WORD_LENGTH-1:0] data,
    input wire data_valid,
    output reg data_ready,
    output reg serial_data,
    output reg word_select
   );

   localparam START = 0;
   localparam INPUT = 1;
   localparam OUTPUT_LEFT = 2;
   localparam OUTPUT_RIGHT = 3;
   // To please Verilator
   localparam LENGTH_M1 = WORD_LENGTH-1;

   integer                        i2s_state;
   reg [WORD_LENGTH-1:0]          data_left;
   reg [WORD_LENGTH-1:0]          data_right;
   reg [$clog2(WORD_LENGTH)-1:0]    data_counter;
    reg serial_data_pre;
    reg word_select_pre;


   always @(negedge clk) begin
      serial_data <= serial_data_pre;
      word_select <= word_select_pre;
   end

   always @(posedge clk) begin
     if (rst) begin
       data_left <= 0;
       data_right <= 0;
       data_ready <= 0;
       serial_data_pre <= 0;
       word_select_pre <= 1;
       i2s_state <= START;
       data_counter <= LENGTH_M1[3:0];
     end else begin
       case (i2s_state)
         
         START:
           begin
             data_ready <= 1;
             word_select_pre <= 1;
             i2s_state <= INPUT;
           end
         
         INPUT:
           begin
             if (data_valid == 1) begin
               data_left <= data[2*WORD_LENGTH-1:WORD_LENGTH];
               data_right <= data[WORD_LENGTH-1:0];
               data_ready <= 0;
               word_select_pre <= 0; 
               i2s_state <= OUTPUT_LEFT;
             end
           end
         
         OUTPUT_LEFT:
           begin
             serial_data_pre <= data_left[data_counter];
             if (data_counter > 0) begin
                data_counter <= data_counter-1;
             end else begin
               data_counter <= LENGTH_M1[3:0];
               i2s_state <= OUTPUT_RIGHT;
               word_select_pre <= 1; 
             end
           end
         
         OUTPUT_RIGHT:
           begin
             serial_data_pre <= data_right[data_counter];
             if (data_counter > 1) begin
               data_counter <= data_counter-1;
             end else if (data_counter == 1) begin
               data_ready <= 1;
               data_counter <= data_counter-1;
             end else begin
               data_counter <= LENGTH_M1[3:0];
               if (data_valid == 1) begin
                 data_left <= data[2*WORD_LENGTH-1:WORD_LENGTH];
                 data_right <= data[WORD_LENGTH-1:0];
                 data_ready <= 0;
                 word_select_pre <= 0;
                 i2s_state <= OUTPUT_LEFT; 
               end else begin
                 i2s_state <= INPUT;
               end
             end
           end
         
       endcase
     end
   end
   
endmodule