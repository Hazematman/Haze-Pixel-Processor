module hpu_sprite(
input [9:0] current_line,
input [9:0] current_column,
input [7:0] sprite_x,
input [7:0] sprite_y, 
input [2:0] line_buf[7:0],
output valid,
output [2:0] out_color
);

assign out_color = line_buf[current_column[2:0]];
assign valid = (out_color != 3'b000) &&
               (current_column >= {2'b00, sprite_x}) && (current_column < ({2'b00, sprite_x} + 8)) &&
               (current_line >= {2'b00, sprite_y}) && (current_line < ({2'b00, sprite_y} + 8));

endmodule
