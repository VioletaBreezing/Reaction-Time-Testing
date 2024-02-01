`timescale 1ns/1ns

module TB_RanGen;

initial begin
    $dumpfile ("./Build/TB_RanGen.vcd");
    $dumpvars;
end

// 输入
reg clk, rstn, reload;

// 输出
wire [15:0] rand;

initial begin
    clk = 1'b0;
    rstn = 1'b0;
    reload = 1'b0;

    #10 rstn = 1'b1;
    #10 reload = 1'b1;
    #5130 $finish;
end

always #5 clk = ~clk;  // 周期10ns, 100MHz

RanGen u_RanGen(
    .clk    (clk    ),
    .rstn   (rstn   ),
    .reload (reload ),
    .rand   (rand   )
);

endmodule