`timescale 1ns/1ns

module TB_SegmentEncoder;

initial begin
    $dumpfile ("./Build/TB_SegmentEncoder.vcd");
    $dumpvars;
end

// 输入
reg [3:0] data_1, data_2;

// 输出
wire [8:0] seg_1, seg_2;

reg clk;

initial begin
    clk = 0;
    data_1 = 4'd0;
    data_2 = 4'd1;

    #215 $finish;
end

always #5 clk = ~clk; // 周期 10ns 100MHz

always @(posedge clk) begin
    data_1 <= (data_1 == 4'd10) ? 4'd0 : data_1 + 4'd1;
    data_2 <= (data_2 == 4'd10) ? 4'd0 : data_2 + 4'd1;
end

SegmentEncoder u_SegmentEncoder(
    .data_1 (data_1 ),
    .data_2 (data_2 ),
    .seg_1  (seg_1  ),
    .seg_2  (seg_2  )
);


endmodule //TB_SegmentEncoder