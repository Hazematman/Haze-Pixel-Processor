module top(
input clk,
input reset,
output [9:0] line,
output [9:0] column,
output [7:0] r_out,
output [7:0] g_out,
output [7:0] b_out,
output [15:0] addr_out,
input [7:0] data_in,
input [7:0] x_offset,
input [7:0] y_offset,
input [47:0] palettes [3:0],
output [4:0] pix_out,
input [31:0] sprite_data[63:0]
);

logic hsync;
logic vsync;
logic de;
logic [9:0] x;
logic [9:0] y;
logic [7:0] r;
logic [7:0] g;
logic [7:0] b;

logic [4:0] pixel_out;

logic [15:0] addr;
logic [7:0] data;
logic [5:0] col_index;
logic [23:0] colors[63:0];

assign column = x;
assign line = y;
assign r_out = (x < 512 && y < 480) ? r : 0;
assign g_out = (x < 512 && y < 480) ? g : 0;
assign b_out = (x < 512 && y < 480) ? b : 0;

assign addr_out = addr;
assign data = data_in;
assign pix_out = pixel_out;


initial begin
    $readmemh("ppu_data/palette.bin", colors);
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

hpu hpu_core(
.clk(clk),
.reset(reset),
.true_line(y),
.true_column(x),
.x_offset(x_offset),
.y_offset(y_offset),
.tile_pixel_out(pixel_out),
.addr_out(addr),
.data_in(data),
.sprite_data(sprite_data)
);

vga vga_core(
.clk(clk),
.reset(reset),
.vga_hsync(hsync),
.vga_vsync(vsync),
.vga_de(de),
.vga_line(y),
.vga_pixel(x)
);


endmodule
