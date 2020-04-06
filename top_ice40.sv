`default_nettype none // Strictly enforce all nets to be declared

module top
(
input CLK,
output LEDR_N,
output LEDG_N,
input BTN_N,
output P1A1, P1A2, P1A3, P1A4, P1A7, P1A8, P1A9, P1A10,
output P1B1, P1B2, P1B3, P1B4, P1B7, P1B8, P1B9, P1B10
);

logic reset;
logic clk_20m;
logic hsync;
logic vsync;
logic de;
logic [9:0] x;
logic [9:0] y;
logic [7:0] r;
logic [7:0] g;
logic [7:0] b;
logic [7:0] r_out;
logic [7:0] g_out;
logic [7:0] b_out;

logic [4:0] pixel_out;

logic [15:0] addr;
logic [7:0] data;
logic [5:0] col_index;
logic [23:0] colors[63:0];
logic [7:0] ram [8191:0];
logic [47:0] palettes [3:0];

assign reset = ~BTN_N;
assign LEDR_N = 1;
assign LEDG_N = 1;

assign r_out = (x < 512 && y < 480) ? r : 0;
assign g_out = (x < 512 && y < 480) ? g : 0;
assign b_out = (x < 512 && y < 480) ? b : 0;

assign {P1A1,   P1A2,   P1A3,   P1A4,   P1A7,   P1A8,   P1A9,   P1A10} = 
       {r_out[7],   r_out[5],   g_out[7],   g_out[5],   r_out[6],   r_out[4],   g_out[6],   g_out[4]};
assign {P1B1,   P1B2,   P1B3,   P1B4,   P1B7,   P1B8,   P1B9,   P1B10} = 
       {b_out[7],   clk_20m, b_out[4],   hsync, b_out[6],   b_out[5],   de, vsync};
             
initial begin
    $readmemh("ppu_data/palettes.mem", palettes);
    $readmemh("ppu_data/palette.bin", colors);
    $readmemh("ppu_data/out.mem", ram);
end

always @(col_index) begin
    r = colors[col_index][23:16];
    g = colors[col_index][15:8];
    b = colors[col_index][7:0];
end

always @(pixel_out) begin
    case(pixel_out[2:0])
        0: col_index = palettes[pixel_out[4:3]][5:0];
        1: col_index = palettes[pixel_out[4:3]][11:6];
        2: col_index = palettes[pixel_out[4:3]][17:12];
        3: col_index = palettes[pixel_out[4:3]][23:18];
        4: col_index = palettes[pixel_out[4:3]][29:24];
        5: col_index = palettes[pixel_out[4:3]][35:30];
        6: col_index = palettes[pixel_out[4:3]][41:36];
        7: col_index = palettes[pixel_out[4:3]][47:42];
    endcase
end

assign data = ram[addr[12:0]];

SB_PLL40_PAD #(
  .DIVR(4'b0000),
  .DIVF(7'b1000010),
  .DIVQ(3'b101),
  .FILTER_RANGE(3'b001),
  .FEEDBACK_PATH("SIMPLE"),
  .DELAY_ADJUSTMENT_MODE_FEEDBACK("FIXED"),
  .FDA_FEEDBACK(4'b0000),
  .DELAY_ADJUSTMENT_MODE_RELATIVE("FIXED"),
  .FDA_RELATIVE(4'b0000),
  .SHIFTREG_DIV_MODE(2'b00),
  .PLLOUT_SELECT("GENCLK"),
  .ENABLE_ICEGATE(1'b0)
) usb_pll_inst (
  .PACKAGEPIN(CLK),
  .PLLOUTCORE(clk_20m),
  //.PLLOUTGLOBAL(),
  .EXTFEEDBACK(),
  .DYNAMICDELAY(),
  .RESETB(1'b1),
  .BYPASS(1'b0),
  .LATCHINPUTVALUE(),
  //.LOCK(),
  //.SDI(),
  //.SDO(),
  //.SCLK()
);

hpu hpu_core(
.clk(clk_20m),
.reset(reset),
.current_line({1'd0,y[9:1]}),
.current_column({1'd0,x[9:1]}),
.true_line(y),
.true_column(x),
.tile_pixel_out(pixel_out),
.addr_out(addr),
.data_in(data)
);

vga vga_core(
.clk(clk_20m),
.reset(reset),
.vga_hsync(hsync),
.vga_vsync(vsync),
.vga_de(de),
.vga_line(y),
.vga_pixel(x)
);

endmodule
