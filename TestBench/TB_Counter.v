`timescale 1ns/1ns

module TB_Counter;

initial begin
    $dumpfile ("./Build/TB_Counter.vcd");
    $dumpvars;
end

// 输入
reg clk, rstn, enable, clear;

// 输出
wire [15:0] count;
wire        carry_out;

initial begin
    clk = 1'b0;
    rstn = 1'b0;
    enable = 1'b1;
    clear = 1'b0;

    #10 rstn = 1;
    #50 enable = 0;
    #10 enable = 1;
    #50 clear  = 1;
    #10 clear  = 0;

    #655360 $finish;
end

always #5 clk = ~clk;   // 周期10ns, 100MHz

Counter u_Counter(
    .clk       (clk       ),
    .rstn      (rstn      ),
    .enable    (enable    ),
    .clear     (clear     ),
    .count     (count     ),
    .carry_out (carry_out )
);


endmodule