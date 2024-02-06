module StateMachine (
    input  wire       clk, rstn,
    input  wire       cur_player,
    input  wire [6:0] signals,
    input  wire [9:0] react_time,

    output wire [2:0] out_machine_state,
    output wire [9:0] avr_react_time_A, avr_react_time_B,
    output wire [2:0] test_turn_A, test_turn_B
);

    // 状态机输入信号
    wire   signal_action, signal_react, signal_average, signal_compare;   // 4 个按键：启动、反应、平均、比较
    wire   signal_start,  signal_overflow, signal_cleared;                // start: 随机延时结束，开始测量计时
                                                                          // overflow: 测量超时溢出
                                                                          // cleared: 计时器清零完成

    assign signal_action  = signals[6];
    assign signal_react   = signals[5];
    assign signal_average = signals[4];
    assign signal_compare = signals[3];

    assign signal_start    = signals[2];
    assign signal_overflow = signals[1];
    assign signal_cleared  = signals[0];

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

    // 状态机变量
    reg  [2:0]  machine_state;          // 状态寄存器
    reg  [12:0] sum_react_time [1:0];   // 累加时间寄存器
    reg  [2:0]  test_turn      [1:0];   // 测试轮次寄存器

    assign out_machine_state = machine_state;
    assign sum_react_time_A  = sum_react_time[PLAYER_A];
    assign sum_react_time_B  = sum_react_time[PLAYER_B];
    assign avr_react_time_A  = sum_react_time[PLAYER_A][12:3];
    assign avr_react_time_B  = sum_react_time[PLAYER_B][12:3];
    assign test_turn_A       = test_turn[PLAYER_A];
    assign test_turn_B       = test_turn[PLAYER_B];

    // 状态转移逻辑
    always @(posedge clk or negedge rstn) begin
        if (!rstn)
            machine_state <= IDLE;
        else begin
            case (machine_state)
            IDLE   : begin
                sum_react_time[PLAYER_A] <= 12'd0;
                sum_react_time[PLAYER_B] <= 12'd0;
                test_turn[PLAYER_A]      <= 3'd0;
                test_turn[PLAYER_B]      <= 3'd0;

                machine_state <= signal_action ? WAIT : machine_state;
            end
            WAIT   : begin
                machine_state <= signal_start ? CLR_CNT1 : machine_state;
            end
            CLR_CNT1: begin
                machine_state <= signal_cleared ? START : machine_state;
            end
            START  : begin
                if (signal_react || signal_overflow) begin
                    machine_state <= STORAGE;
                    sum_react_time[cur_player] <= sum_react_time[cur_player] + react_time;
                end
                else machine_state <= machine_state;
            end
            STORAGE: begin
                if (test_turn[cur_player] == 3'd7 && signal_average)
                    machine_state <= AVERAGE;
                else if (test_turn[cur_player] != 3'd7 && signal_action) begin
                    machine_state <= CLR_CNT2;
                    test_turn[cur_player] <= test_turn[cur_player] + 3'd1;
                end
                else machine_state <= machine_state;
            end
            CLR_CNT2: begin
                machine_state <= signal_cleared ? WAIT : machine_state;
            end
            AVERAGE: begin
                if (test_turn[PLAYER_A] == 3'd7 && test_turn[PLAYER_B] == 3'd7 && signal_compare)
                    machine_state <= COMPARE;
                else if (test_turn[cur_player] != 3'd7 && signal_action)
                    machine_state <= WAIT;
                else machine_state <= machine_state;
            end
            COMPARE: machine_state <= machine_state;
            default: machine_state <= IDLE;
            endcase
        end
    end

endmodule //StateMachine