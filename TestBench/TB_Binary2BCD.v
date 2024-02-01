`timescale 1ns/1ps

module TB_Binary2BCD;

initial begin
    $dumpfile ("./Build/TB_Binary2BCD.vcd");
    $dumpvars;
end

reg  [9:0]  bitcode;    // 输入
wire [15:0] bcdcode;    // 输出

reg clk;

wire [3:0] thousands, hundreds, tens, ones;    

assign thousands = bcdcode[15:12];
assign hundreds  = bcdcode[11:8];
assign tens      = bcdcode[7:4];
assign ones      = bcdcode[3:0];

initial begin
    bitcode = 10'd0;
    clk = 1'b0;

    #200;

    #102401 $finish;
end

always #50 clk = ~clk;  // 10MHz，周期为 100ns

always @(posedge clk) begin
    bitcode <= bitcode + 10'd1;
    $display ("%d -> %d%d%d%d", bitcode, thousands, hundreds, tens, ones);
end

Binary2BCD u_Binary2BCD (
    .bitcode (bitcode),
    .bcdcode (bcdcode)
);

endmodule