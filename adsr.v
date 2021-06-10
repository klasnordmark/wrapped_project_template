`default_nettype none
`timescale 1ns/1ns

module adsr #(parameter COUNTER_WIDTH = 26)
             (input wire clk,
              input wire reset,
              input wire [26:0] attack,
              input wire [15:0] sustain,
              input wire [26:0] decay,
              input wire [26:0] fade,
              input wire trigger,
              output reg tvalid,
              output wire [15:0] tdata,
              input wire tready);
    
    localparam STATE_IDLE    = 0;
    localparam STATE_ATTACK  = 1;
    localparam STATE_DECAY   = 2;
    localparam STATE_SUSTAIN = 3;
    localparam STATE_RELEASE = 4;
    
    wire transaction;
    
    reg [4:0] state;
    reg [COUNTER_WIDTH:0] envelope_counter;
    reg trigger_d;
    reg start_envelope;
    reg [15:0] out_of_range;
    
    assign transaction = tvalid & tready;
    // This trick should be cheaper than keeping a comparator around or something
    assign tdata       = envelope_counter[COUNTER_WIDTH] ? out_of_range : {1'b0, envelope_counter[COUNTER_WIDTH-1:COUNTER_WIDTH-15]};
    
    // Trigger edge detection
    always @(posedge clk) begin
        if ((trigger_d == 0) && (trigger == 1)) begin
            start_envelope <= 1;
        end
        else begin
            start_envelope <= 0;
        end
        trigger_d <= trigger;
    end
    
    // Envelope generation
    always @(posedge clk) begin
        if (reset) begin
            state            <= STATE_IDLE;
            envelope_counter <= 0;
            tvalid           <= 0;
        end
        else begin
            tvalid <= 1;
            case(state)
                STATE_IDLE: begin
                    envelope_counter <= 0;
                end
                
                STATE_ATTACK: begin
                    out_of_range <= {1'b0, {15{1'b1}}};
                    if (transaction) begin
                        envelope_counter <= envelope_counter + attack[26:0];
                    end
                    if (envelope_counter[COUNTER_WIDTH] == 1) begin
                        envelope_counter <= {1'b0, {26{1'b1}}};
                        state <= STATE_DECAY;
                    end
                end
                
                STATE_DECAY: begin
                    out_of_range <= {16{1'b0}};
                    if (transaction) begin
                        envelope_counter <= envelope_counter - decay[26:0];
                    end
                    if (envelope_counter[COUNTER_WIDTH-1:COUNTER_WIDTH-16] <= sustain[15:0]) begin
                        state <= STATE_SUSTAIN;
                    end
                end
                
                STATE_SUSTAIN: begin
                    envelope_counter <= {1'b0, sustain[15:0], {COUNTER_WIDTH-16{1'b0}}};
                    if (!trigger) begin
                        state <= STATE_RELEASE;
                    end
                end
                
                STATE_RELEASE: begin
                    out_of_range <= {16{1'b0}};
                    if (transaction) begin
                        envelope_counter <= envelope_counter - fade[26:0];
                    end
                    if (envelope_counter == 0) begin
                        state <= STATE_IDLE;
                    end
                end
                
                default: begin
                    state <= STATE_IDLE;
                end
            endcase
            if (start_envelope) begin
                envelope_counter <= 0;
                state            <= STATE_ATTACK;
            end
        end
    end
    
endmodule
