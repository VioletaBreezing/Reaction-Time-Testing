`timescale 1ns/1ns

module TB_PWM;

initial begin
    $dumpfile ("./Build/TB_PWM.vcd");
    $dumpvars;
end

// 输入
reg clk, rstn, bright;

// 输出
wire pwm_div256;

initial begin
    clk = 1'b0;
    rstn = 1'b0;
    bright = 1'b0;

    #10 rstn = 1'b1;
    #5130 bright = 1'b1;
    #5130 $finish;
end

always #5 clk = ~clk;  // 周期10ns, 100MHz

PWM u_PWM(
    .clk        (clk        ),
    .rstn       (rstn       ),
    .bright     (bright     ),
    .pwm_div256 (pwm_div256 )
);


endmodule