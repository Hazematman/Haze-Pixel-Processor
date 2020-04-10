module hpu(
input clk,
input reset,
input [9:0] current_line,
input [9:0] current_column,
input [9:0] true_line,
input [9:0] true_column,
input [7:0] x_offset,
input [7:0] y_offset,
output [4:0] tile_pixel_out,
output [15:0] addr_out,
input [7:0] data_in
);

`define TILE_OFFSET 16'h0
`define NAMETABLE_OFFSET 16'h1800
`define ATTR_OFFSET 16'h2700
`define PALETTE_OFFSET 16'h2ac0

logic [4:0] pixel_out;
logic [15:0] addr;
logic [7:0] data;
logic [3:0] cycle_counter;
logic [4:0] tile_x;
logic [4:0] tile_y;
logic [2:0] current_x;
logic [2:0] current_y;
logic [7:0] bg_buffer;
logic [7:0] attr_buffer[1:0];
logic [15:0] line_cache;
logic [23:0] current_tile_line;
logic [2:0] current_pixel;
logic [1:0] current_pallet;

logic [4:0] next_tile_x;
logic [4:0] next_tile_y;
logic [2:0] next_y;
logic [4:0] next_pixel_tile_x;
logic [9:0] next_pixel;

logic [15:0] line_addr_buffer;

logic next_column_p8;
    
enum {
state_wait, 
state_read_bg, 
state_read_attr, 
state_calc_1,
state_calc_2,
state_calc_3,
state_read_pixel_1,
state_read_pixel_2,
state_read_pixel_3,
state_done } state;

assign tile_pixel_out = pixel_out;
assign addr_out = addr;
assign data = data_in;

assign tile_x = current_column[7:3];
assign tile_y = current_line[7:3];

assign next_column_p8 = (current_column + 8) < 256;

assign next_tile_x = next_column_p8 ? (tile_x + 1) : 0;
assign next_tile_y = (next_column_p8 || true_line[3:0] != 4'b1111) ? tile_y : ((tile_y + 1) < 60 ? (tile_y + 1) : 0);

assign current_y = current_line[2:0];
assign current_x = current_column[2:0];

assign next_y = (next_column_p8 || true_line[0] == 0) ? current_y : current_y + 1;

assign next_pixel = ((current_column + 1) < 400) ? (current_column + 1) : 0 ;
assign next_pixel_tile_x = next_pixel[7:3];

always @(next_pixel_tile_x or attr_buffer[1]) begin
    case(next_pixel_tile_x[1:0])
        0: current_pallet = attr_buffer[1][1:0];
        1: current_pallet = attr_buffer[1][3:2];
        2: current_pallet = attr_buffer[1][5:4];
        3: current_pallet = attr_buffer[1][7:6];
    endcase
end

always @(current_x or current_tile_line) begin
    case(current_x)
        0: current_pixel = current_tile_line[2:0];
        1: current_pixel = current_tile_line[5:3];
        2: current_pixel = current_tile_line[8:6];
        3: current_pixel = current_tile_line[11:9];
        4: current_pixel = current_tile_line[14:12];
        5: current_pixel = current_tile_line[17:15];
        6: current_pixel = current_tile_line[20:18];
        7: current_pixel = current_tile_line[23:21];
    endcase
end

/* Logic to increment cycle counter */
always @(posedge clk or posedge reset) begin
    if(reset == 1) begin
        cycle_counter <= 0;
    end
    else begin
        cycle_counter <= cycle_counter + 1;
    end
end

/* Logic to continuously output pixel data */
always @(posedge clk or posedge reset) begin
    if(reset == 1) begin
        pixel_out <= 0;
    end
    else begin
        /* Every other cycle get the next pixel */
        if(cycle_counter[0] == 1) begin
            pixel_out <= {current_pallet, current_pixel};
        end
    end
end


always @(posedge clk or posedge reset) begin
    if(reset) begin
        state <= state_wait;
        bg_buffer <= 0;
        attr_buffer[0] <= 0;
        attr_buffer[1] <= 0;
        line_cache <= 0;
        current_tile_line <= 0;
        line_addr_buffer <= 0;
    end
    else begin
        case(state)
            state_wait: begin
                if(cycle_counter == 5) begin
                    state <= state_read_bg;
                end
            end
            state_read_bg: begin
                addr <= `NAMETABLE_OFFSET + (({11'd0,next_tile_y} << 6) + {11'd0,next_tile_x});
                state <= state_read_attr;
            end
            state_read_attr: begin
                addr <= `ATTR_OFFSET + (({11'd0, next_tile_y} << 4) + ({11'd0, next_tile_x} >> 2));
                bg_buffer <= data;
                line_addr_buffer <= ({8'd0,data} << 4);
                state <= state_calc_1;
            end
            state_calc_1: begin
                line_addr_buffer <= line_addr_buffer + ({8'd0,bg_buffer} << 3);
                state <= state_calc_2;
            end
            state_calc_2: begin
                line_addr_buffer <= line_addr_buffer + ({13'd0,next_y} << 1);
                state <= state_calc_3;
            end
            state_calc_3: begin
                line_addr_buffer <= line_addr_buffer + {13'd0,next_y};
                state <= state_read_pixel_1;
            end
            state_read_pixel_1: begin
                addr <= `TILE_OFFSET | line_addr_buffer;
                attr_buffer[0] <= data;
                state <= state_read_pixel_2;
            end
            state_read_pixel_2: begin
                addr <= `TILE_OFFSET | line_addr_buffer + 1;
                line_cache[7:0] <= data;
                state <= state_read_pixel_3;
            end
            state_read_pixel_3: begin
                addr <= `TILE_OFFSET | line_addr_buffer + 2;
                line_cache[15:8] <= data;
                state <= state_done;
            end
            state_done: begin
                current_tile_line[15:0] <= line_cache;
                current_tile_line[23:16] <= data;
                attr_buffer[1] <= attr_buffer[0];
                state <= state_wait;
            end
        endcase
    end
end

endmodule
