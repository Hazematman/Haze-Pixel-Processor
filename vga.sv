module vga(
input clk,
input reset,
output vga_hsync,
output vga_vsync,
output vga_de,
output [9:0] vga_line,
output [9:0] vga_pixel
);

`define PIXELS_PER_LINE 10'd800
`define PIXELS_VISIBLE_PER_LINE 10'd640
`define LINES_PER_FRAME 10'd525
`define LINES_VISIBLE_PER_FRAME 10'd480
`define HORIZONTAL_FRONTPORCH 10'd656
`define HORIZONTAL_BACKPORCH 10'd752
`define VERTICAL_FRONTPORCH 10'd490
`define VERTICAL_BACKPORCH 10'd492

logic [9:0] line;
logic [9:0] pixel;
logic hsync;
logic vsync;
logic de;

assign vga_line = line;
assign vga_pixel = pixel;
assign vga_hsync = hsync;
assign vga_vsync = vsync;
assign vga_de = de;

assign hsync = pixel < (`HORIZONTAL_FRONTPORCH) || pixel >= (`HORIZONTAL_BACKPORCH);
assign vsync = line < (`VERTICAL_FRONTPORCH) || line >= (`VERTICAL_BACKPORCH);
assign de = (pixel < `PIXELS_VISIBLE_PER_LINE) && (line < `LINES_VISIBLE_PER_FRAME);

// Pixel and line counter
always @(posedge clk or posedge reset) begin
    if(reset == 1) begin
        line <= `LINES_PER_FRAME - 2;
        pixel <= `PIXELS_PER_LINE - 16;
    end
    else begin
        if(pixel == (`PIXELS_PER_LINE - 1) && line == (`LINES_PER_FRAME - 1)) begin
            line <= 0;
            pixel <= 0;
        end
        else if(pixel == `PIXELS_PER_LINE - 1) begin
            line <= line + 1;
            pixel <= 0;
        end
        else begin
            pixel <= pixel + 1;
        end
    end
end

endmodule
