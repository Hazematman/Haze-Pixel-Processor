module clz
#(
parameter WIDTH = 16,
parameter WIDTH_OUT = ($clog2(WIDTH)+1),
parameter FIXED_WIDTH = WIDTH
)(
input [WIDTH-1:0] value,
output [WIDTH_OUT-1:0] out
);

logic [WIDTH_OUT-1:0] out_value;

assign out = out_value;

generate
    if(WIDTH == 1) begin
        always @* begin
            if(value[0] == 1) begin
                out_value = (WIDTH_OUT)'(FIXED_WIDTH-1);
            end else begin
                out_value = (WIDTH_OUT)'(FIXED_WIDTH);
            end
        end
    end else begin
        logic [WIDTH_OUT-1:0] temp_out;
        clz #(.WIDTH(WIDTH-1), .WIDTH_OUT(WIDTH_OUT), .FIXED_WIDTH(FIXED_WIDTH))
        clz_out
        (.value(value[WIDTH-2:0]), .out(temp_out));
        always @* begin
            if(value[WIDTH-1] == 1) begin
                out_value = (WIDTH_OUT)'(FIXED_WIDTH - WIDTH);
            end else begin
                out_value = temp_out;
            end
        end
    end
endgenerate

endmodule
