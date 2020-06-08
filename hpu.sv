module hpu(
input clk,
input reset,
input [9:0] true_line,
input [9:0] true_column,
input [7:0] x_offset,
input [7:0] y_offset,
output [15:0] hpu_addr_out,
output [2:0] hpu_pixel_out,
output [1:0] hpu_pallet_out,
input [7:0] hpu_data_in
);

`define NUM_SPRITE_ENGINES 16

logic [2:0] pixel_out;
logic [1:0] pallet_out;
logic [15:0] addr_out;
logic [7:0] data_in;

assign hpu_pixel_out = pixel_out;
assign hpu_pallet_out = pallet_out;

logic [4:0] tile_pixel_out;

logic [9:0] current_column;
logic [9:0] current_line;

logic [1:0] sprite_pallets[`NUM_SPRITE_ENGINES-1:0];
logic [7:0] sprite_x_positions[`NUM_SPRITE_ENGINES-1:0];
logic [7:0] sprite_y_positions[`NUM_SPRITE_ENGINES-1:0];
logic [(`NUM_SPRITE_ENGINES-1):0] valid_bits;
logic [23:0] sprite_line_bufs[`NUM_SPRITE_ENGINES-1:0];
logic [2:0] sprite_out_colors[`NUM_SPRITE_ENGINES-1:0];

logic no_sprite;
logic [3:0] valid_sprite;

assign current_column = {1'b0, true_column[9:1]};
assign current_line = {1'b0, true_line[9:1]};


enum {
state_wait, 
state_load_y,
state_eval_y,
state_load_px_1,
state_load_px_2,
state_load_px_3,
state_load_palette, } state;

logic [3:0] current_internal_sprite;
logic [5:0] current_external_sprite;


clz determine_valid_sprite(.value(valid_bits), .out({no_sprite, valid_sprite}));

always @* begin
    if(no_sprite) begin
        pixel_out = tile_pixel_out[2:0];
        pallet_out = tile_pixel_out[4:3];
    end else begin
        pixel_out = sprite_out_colors[valid_sprite];
        pallet_out = sprite_pallets[valid_sprite];
    end
end

/* Logic to load internal sprite memories for drawing */
always @(posedge clk or posedge reset) begin
    if(reset) begin
        state <= state_wait;
    end else begin
        case(state)
            state_wait: begin
                if(true_column == 639) begin
                    state <= state_load_y;
                    current_internal_sprite <= 0;
                    current_external_sprite <= 0;
                end
            end
            state_load_y: begin
                /* TODO determine logic to compute where sprite
                 * Y value is in memory
                 */
                //addr_out <= 
                state <= state_eval_y;
            end
            state_eval_y: begin
                if(/* TODO true condition*/) begin
                    /* TODO we can compute addr for first pixel here */
                    //addr_out
                    state <= state_load_px_1;
                end else begin
                    state <= state_load_y;
                end
                current_external_sprite <= current_external_sprite + 1;
            end
            state_load_px_1: begin
                sprite_line_bufs[current_internal_sprite][7:0] <= data_in;
                /* TODO compute address of second pixel */
                //addr_out
                state <= state_load_px_2;
            end
            state_load_px_2: begin
                sprite_line_bufs[current_internal_sprite][15:8] <= data_in;
                /* TODO compute address of third pixel */
                //addr_out
                state <= state_load_px_3;
            end
            state_load_px_3: begin
                sprite_line_bufs[current_internal_sprite][23:16] <= data_in;
                /* TODO compute address of pallete */
                //addr_out
                state <= state_load_palette;
            end
            state_load_palette: begin
                sprite_pallets[current_internal_sprite] <= data_in[1:0];
                current_internal_sprite <= current_internal_sprite + 1;
                state <= state_load_y;
            end
        endcase
    end
end

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
