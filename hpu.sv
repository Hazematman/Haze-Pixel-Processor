module hpu(
input clk,
input reset,
input [9:0] true_line,
input [9:0] true_column,
input [7:0] x_offset,
input [7:0] y_offset,
output [15:0] addr_out,
input [7:0] data_in
);

logic [4:0] tile_pixel_out;


hpu_tile tile_core(
.clk(clk),
.reset(reset),
.true_line(true_line),
.true_column(true_column),
.x_offset(x_offset),
.y_offset(y_offset),
.tile_pixel_out(tile_pixel_out),
.addr_out(addr_out),
.data_in(data_in)
);

endmodule
