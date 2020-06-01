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

`define NUM_SPRITE_ENGINES 16

logic [4:0] tile_pixel_out;

logic [9:0] current_column;
logic [9:0] current_line;

logic [1:0] sprite_pallets[`NUM_SPRITE_ENGINES-1:0];
logic [7:0] sprite_x_positions[`NUM_SPRITE_ENGINES-1:0];
logic [7:0] sprite_y_positions[`NUM_SPRITE_ENGINES-1:0];
logic [(`NUM_SPRITE_ENGINES-1):0] valid_bits;
logic [23:0] sprite_line_bufs[`NUM_SPRITE_ENGINES-1:0];
logic [2:0] sprite_out_colors[`NUM_SPRITE_ENGINES-1:0];

logic [4:0] valid_sprite;

assign current_column = {1'b0, true_column[9:1]};
assign current_line = {1'b0, true_line[9:1]};

clz determine_valid_sprite(.value(valid_bits), .out(valid_sprite));

genvar i;
generate
for(i = 0; i < `NUM_SPRITE_ENGINES; i = i + 1) begin
    hpu_sprite sprite_engine(
    .current_line(current_line),
    .current_column(current_column),
    .sprite_x(sprite_x_positions[i]),
    .sprite_y(sprite_y_positions[i]), 
    .line_buf('{{sprite_line_bufs[i][2:0]},
                {sprite_line_bufs[i][5:3]},
                {sprite_line_bufs[i][8:6]},
                {sprite_line_bufs[i][11:9]},
                {sprite_line_bufs[i][14:12]},
                {sprite_line_bufs[i][17:15]},
                {sprite_line_bufs[i][20:18]},
                {sprite_line_bufs[i][23:21]}
                }),
    .valid(valid_bits[i]),
    .out_color(sprite_out_colors[i]));
end
endgenerate

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
