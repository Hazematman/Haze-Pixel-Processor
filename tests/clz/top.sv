module top
(
input [15:0] value,
output [4:0] out
);

clz #(.WIDTH(16))
    clz_mod
    (.value(value), .out(out));

endmodule
