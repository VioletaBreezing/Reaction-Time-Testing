`timescale 1ms/100us

module TB_Timer;

initial begin
    $dumpfile ("./Build/TB_Timer.vcd");
    $dumpvars;
end

// 输入
reg clk, rstn;
reg [2:0] machine_state;
reg [13:0] rand_num;

// 输出
wire signal_start, signal_overflow, signal_cleared;
wire [9:0] react_time;

// 时钟 1KHz
always #0.5 clk = ~clk;

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

// 初始化
initial begin
    clk = 0;
    rstn = 0;
    machine_state = IDLE;
    rand_num = 38;

    #5    rstn = 1; machine_state = WAIT;
    #60   machine_state = CLR_CNT1;
    #5    machine_state = START;
    #1010 machine_state = STORAGE;
    #5    machine_state = CLR_CNT2;
    #5    machine_state = START;
    #20   machine_state = STORAGE;

    #10 $finish;
end

Timer u_Timer(
    .clk             (clk             ),
    .rstn            (rstn            ),
    .machine_state   (machine_state   ),
    .rand_num        (rand_num        ),
    .signal_start    (signal_start    ),
    .signal_overflow (signal_overflow ),
    .signal_cleared  (signal_cleared  ),
    .react_time      (react_time      )
);


endmodule //TB_Timer