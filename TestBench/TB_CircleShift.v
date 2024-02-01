`timescale 1ns/1ps

module TB_CircleShift;

initial begin
    $dumpfile ("./Build/TB_CircleShift.vcd");
    $dumpvars;
end

// 输入
reg        clk, rstn, enable;
reg  [3:0] in_digit_2,  in_digit_1,  in_digit_0;

// 输出
wire [3:0] out_digit_1, out_digit_0;

initial begin
    clk = 1'b0;
    rstn = 1'b0;
    enable = 1'b0;
    in_digit_2 = 4'd9;
    in_digit_1 = 4'd5;
    in_digit_0 = 4'd2;

    #200 rstn = 1'b1;

    #400 enable = 1'b1;

    #900 $finish;    // 运行9个时钟周期
end

always #50 clk = ~clk;  // 10MHz，周期为 100ns

always @(posedge clk) begin
    $display ("%d(ns): %d%d%d -> %d %d", $time, in_digit_2, in_digit_1, in_digit_0, out_digit_1, out_digit_0);
end

CircleShift u_CircleShift(
    .clk         (clk         ),
    .rstn        (rstn        ),
    .enable      (enable      ),
    .in_digit_2  (in_digit_2  ),
    .in_digit_1  (in_digit_1  ),
    .in_digit_0  (in_digit_0  ),
    .out_digit_1 (out_digit_1 ),
    .out_digit_0 (out_digit_0 )
);

endmodule