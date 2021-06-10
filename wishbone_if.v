`default_nettype none
`timescale 1ns/1ns

module wishbone_if (
    // Wishbone signals
    input wire wb_clk_i,
    input wire wb_rst_i,
    input wire wbs_stb_i,
    input wire wbs_cyc_i,
    input wire wbs_we_i,
    input wire [3:0] wbs_sel_i,
    input wire [31:0] wbs_dat_i,
    input wire [31:0] wbs_adr_i,
    output reg wbs_ack_o,
    output reg [31:0] wbs_dat_o,

    // Output to synth registers
    output reg [31:0] divisor,
    output reg [7:0] duty,
    output reg [26:0] attack,
    output reg [15:0] sustain,
    output reg [26:0] decay,
    output reg [26:0] fade,
    output reg [17:0] cutoff,
    output reg [17:0] resonance,
    output reg trigger,
    output reg waveform,
    output reg [15:0] i2s_divisor);

    reg [1:0] bsel;
    reg ack;

    wire valid;
    wire [3:0] wstrb;

    assign valid = wbs_stb_i;
    assign wstrb = wbs_sel_i & {4{wbs_we_i}};
    assign wbs_ack_o = ack & valid;

    always @(posedge wb_clk_i) begin

        ack <= 0;

        if (valid) begin
            ack <= 1;
            case (wbs_adr_i[7:0])
                0: begin
                    if (wstrb[0]) divisor[7:0]   <= wbs_dat_i[7:0];
                    if (wstrb[1]) divisor[15:8]  <= wbs_dat_i[15:8];
                    if (wstrb[2]) divisor[23:16] <= wbs_dat_i[23:16];
                    if (wstrb[3]) divisor[31:24] <= wbs_dat_i[31:24];
                    wbs_dat_o <= divisor;
                end
                4: begin
                    if (wstrb[0]) duty   <= wbs_dat_i[7:0];
                    wbs_dat_o <= {24'b0, duty};
                end
                8: begin
                    if (wstrb[0]) attack[7:0]   <= wbs_dat_i[7:0];
                    if (wstrb[1]) attack[15:8]  <= wbs_dat_i[15:8];
                    if (wstrb[2]) attack[23:16] <= wbs_dat_i[23:16];
                    if (wstrb[3]) attack[26:24] <= wbs_dat_i[26:24];
                    wbs_dat_o <= {5'b0, attack};
                end
                12: begin
                    if (wstrb[0]) sustain[7:0]   <= wbs_dat_i[7:0];
                    if (wstrb[1]) sustain[15:8]  <= wbs_dat_i[15:8];
                    wbs_dat_o <= {16'b0, sustain};
                end
                16: begin
                    if (wstrb[0]) decay[7:0]   <= wbs_dat_i[7:0];
                    if (wstrb[1]) decay[15:8]  <= wbs_dat_i[15:8];
                    if (wstrb[2]) decay[23:16] <= wbs_dat_i[23:16];
                    if (wstrb[3]) decay[26:24] <= wbs_dat_i[26:24];
                    wbs_dat_o <= {5'b0, decay};
                end
                20: begin
                    if (wstrb[0]) fade[7:0]   <= wbs_dat_i[7:0];
                    if (wstrb[1]) fade[15:8]  <= wbs_dat_i[15:8];
                    if (wstrb[2]) fade[23:16] <= wbs_dat_i[23:16];
                    if (wstrb[3]) fade[26:24] <= wbs_dat_i[26:24];
                    wbs_dat_o <= {5'b0, fade};
                end
                24: begin
                    if (wstrb[0]) cutoff[7:0]   <= wbs_dat_i[7:0];
                    if (wstrb[1]) cutoff[15:8]  <= wbs_dat_i[15:8];
                    if (wstrb[2]) cutoff[17:16] <= wbs_dat_i[17:16];
                    wbs_dat_o <= {14'b0, cutoff};
                end
                28: begin
                    if (wstrb[0]) resonance[7:0]   <= wbs_dat_i[7:0];
                    if (wstrb[1]) resonance[15:8]  <= wbs_dat_i[15:8];
                    if (wstrb[2]) resonance[17:16] <= wbs_dat_i[17:16];
                    wbs_dat_o <= {14'b0, resonance};
                end
                32: begin
                    if (wstrb[0]) trigger   <= wbs_dat_i[0];
                    wbs_dat_o <= {31'b0, trigger};
                end
                36: begin
                    if (wstrb[0]) waveform   <= wbs_dat_i[0];
                    wbs_dat_o <= {31'b0, waveform};
                end
                40: begin
                    if (wstrb[0]) i2s_divisor[7:0] <= wbs_dat_i[7:0];
                    if (wstrb[1]) i2s_divisor[15:8] <= wbs_dat_i[15:8];
                    wbs_dat_o <= {16'b0, i2s_divisor};
                end
                default: begin
                end
            endcase
        end
        
        if (wb_rst_i) begin
            ack <= 0;
            wbs_dat_o <= 0;
            divisor <= 0;
            duty <= 0;
            attack <= 0;
            sustain <= 0;
            decay <= 0;
            fade <= 0;
            cutoff <= 0;
            resonance <= 0;
            trigger <= 0;
            waveform <= 0;
        end
    end

endmodule