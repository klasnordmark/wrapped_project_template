`default_nettype none
`timescale 1ns/1ns

module synth_top #(parameter DATA_BYTES = 2)
                  (input wire clk,
                   input wire reset,
                   input wire [31:0] divisor,
                   input wire [7:0] duty,
                   input wire waveform,
                   input wire [26:0] attack,
                   input wire [15:0] sustain,
                   input wire [26:0] decay,
                   input wire [26:0] fade,
                   input wire [17:0] cutoff,
                   input wire [17:0] resonance,
                   input wire trigger,
                   output wire tvalid,
                   output wire [15:0] tdata,
                   input wire tready);
    
    wire osc_to_mult_tvalid;
    wire osc_to_mult_tready;
    wire [15:0] osc_to_mult_tdata;
    
    wire adsr_to_mult_tvalid;
    wire adsr_to_mult_tready;
    wire [15:0] adsr_to_mult_tdata;

    wire mult_to_filter_tvalid;
    wire mult_to_filter_tready;
    wire [15:0] mult_to_filter_tdata;

    audio_oscillator #(.WORD_BYTES(DATA_BYTES)
    ) audio_oscillator_inst (
    .clk(clk),
    .reset(reset),
    .divisor(divisor),
    .duty(duty),
    .waveform(waveform),
    .tvalid(osc_to_mult_tvalid),
    .tdata(osc_to_mult_tdata),
    .tready(osc_to_mult_tready)
    );
    
    adsr #(.COUNTER_WIDTH(26)
    ) adsr_inst (
    .clk(clk),
    .reset(reset),
    .attack(attack),
    .sustain(sustain),
    .decay(decay),
    .fade(fade),
    .trigger(trigger),
    .tvalid(adsr_to_mult_tvalid),
    .tdata(adsr_to_mult_tdata),
    .tready(adsr_to_mult_tready)
    );
    
    axi4s_multiplier #(.DATA_BYTES(DATA_BYTES)
    ) multiplier_inst (
    .clk(clk),
    .reset(reset),
    .tvalid_slave_1(osc_to_mult_tvalid),
    .tdata_slave_1(osc_to_mult_tdata),
    .tready_slave_1(osc_to_mult_tready),
    .tvalid_slave_2(adsr_to_mult_tvalid),
    .tdata_slave_2(adsr_to_mult_tdata),
    .tready_slave_2(adsr_to_mult_tready),
    .tvalid_master(mult_to_filter_tvalid),
    .tdata_master(mult_to_filter_tdata),
    .tready_master(mult_to_filter_tready)
    );

    sv_filter filter_inst (
        .clk(clk),
        .reset(reset),
        .cutoff(cutoff),
        .resonance(resonance),
        .tvalid_slave(mult_to_filter_tvalid),
        .tready_slave(mult_to_filter_tready),
        .tdata_slave(mult_to_filter_tdata),
        .tvalid_master(tvalid),
        .tready_master(tready),
        .tdata_master(tdata)
    );
    
endmodule
