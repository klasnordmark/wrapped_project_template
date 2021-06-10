module synth_wrapper (
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

    // Output interface
    output wire clk_i2s,
    output wire serial_data,
    output wire word_select);

    wire [31:0] divisor;
    wire [7:0] duty;
    wire [26:0] attack;
    wire [15:0] sustain;
    wire [26:0] decay;
    wire [26:0] fade;
    wire [17:0] cutoff;
    wire [17:0] resonance;
    wire trigger;
    wire waveform;
    wire [15:0] i2s_divisor;

    wire tvalid;
    wire [15:0] tdata;
    wire tready;

    wishbone_if wb_if_inst (
        .wb_clk_i(wb_clk_i),
        .wb_rst_i(wb_rst_i),
        .wbs_stb_i(wbs_stb_i),
        .wbs_cyc_i(wbs_cyc_i),
        .wbs_we_i(wbs_we_i),
        .wbs_sel_i(wbs_sel_i),
        .wbs_dat_i(wbs_dat_i),
        .wbs_adr_i(wbs_adr_i),
        .wbs_ack_o(wbs_ack_o),
        .wbs_dat_o(wbs_dat_o),
        .divisor(divisor),
        .duty(duty),
        .attack(attack),
        .sustain(sustain),
        .decay(decay),
        .fade(fade),
        .cutoff(cutoff),
        .resonance(resonance),
        .trigger(trigger),
        .waveform(waveform),
        .i2s_divisor(i2s_divisor)
    );

    synth_top synth (
        .clk(wb_clk_i),
        .reset(wb_rst_i),
        .divisor(divisor),
        .duty(duty),
        .waveform(waveform),
        .attack(attack),
        .sustain(sustain),
        .decay(decay),
        .fade(fade),
        .cutoff(cutoff),
        .resonance(resonance),
        .trigger(trigger),
        .tvalid(tvalid),
        .tdata(tdata),
        .tready(tready)
    );

    i2s_master_top i2s (
        .clk(wb_clk_i),
        .rst(wb_rst_i),
        .divisor(i2s_divisor),
        .axis_data(tdata),
        .axis_valid(tvalid),
        .axis_ready(tready),
        .clk_i2s_out(clk_i2s),
        .serial_data(serial_data),
        .word_select(word_select)
    );

endmodule