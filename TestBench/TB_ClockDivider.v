`timescale 1ns/1ps

module TB_ClockDivider;

initial begin
    $dumpfile ("./Build/TB_ClockDivider.vcd");
    $dumpvars;
end

// 输入
reg clk_12MHz, rstn;

// 输出
wire clk_1KHz, clk_2Hz;

initial begin
    clk_12MHz = 1'b0;
    rstn = 1'b0;

    #200 rstn = 1'b1;

    #1_000_000_100 $finish;    // 运行9个时钟周期
end

always #41.667 clk_12MHz = ~clk_12MHz;  // 12MHz，周期为 83.333ns

ClockDivider u_ClockDivider(
    .rstn      (rstn      ),
    .clk_12MHz (clk_12MHz ),
    .clk_1KHz  (clk_1KHz  ),
    .clk_2Hz   (clk_2Hz   )
);


endmodule