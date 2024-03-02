`timescale 1ns/1ns

module TB_Random;

initial begin
    $dumpfile ("./Build/TB_Random.vcd");
    $dumpvars;
end

// 输入
reg clk, rstn;
reg [2:0] machine_state;

// 输出
wire [13:0] rand_num;

// 时钟
always #5 clk = ~clk;

// 状态机参数
parameter IDLE     = 3'd0;
parameter WAIT     = 3'd1;
parameter CLR_CNT1 = 3'd2;
parameter START    = 3'd3;
parameter STORAGE  = 3'd4;
parameter CLR_CNT2 = 3'd5;
parameter AVERAGE  = 3'd6;
parameter COMPARE  = 3'd7;
parameter PLAYER_A = 1'b1;
parameter PLAYER_B = 1'b0;


initial begin
    clk = 0;
    rstn = 0;
    machine_state = IDLE;

    #20 rstn = 1;
    #2000 $finish;
end

always @(posedge clk) begin
    machine_state <= machine_state + 1;
end

Random u_Random(
    .clk           (clk           ),
    .rstn          (rstn          ),
    .machine_state (machine_state ),
    .rand_num      (rand_num      )
);


endmodule //TB_StateMachine