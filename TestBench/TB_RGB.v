`timescale 1ns/1ps

module TB_RGB;

initial begin
    $dumpfile ("./Build/TB_RGB.vcd");
    $dumpvars;
end

// 输入
reg clk, rstn, cur_player;
reg [9:0] react_time [1:0];
reg signal_action, signal_react, signal_average, signal_compare, signal_start,  signal_overflow, signal_cleared;
wire [6:0] signals;
assign signals = {signal_action, signal_react, signal_average, signal_compare, signal_start,  signal_overflow, signal_cleared};


// 输出
wire [2:0] machine_state;
wire [9:0] avr_react_time_A, avr_react_time_B;
wire [2:0] test_turn_A, test_turn_B;
wire [2:0] rgb1, rgb2;

reg cnt;

initial begin
    clk = 0;
    rstn = 0;
    cnt = 0;
    cur_player = PLAYER_A;
    react_time[PLAYER_A] = 10'd999;
    react_time[PLAYER_B] = 10'd499;
    {signal_action, signal_react, signal_average, signal_compare, signal_start,  signal_overflow, signal_cleared} = 7'b0;

    #100 rstn = 1;
end

always #41.667 clk = ~clk;       // 12MHz

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

wire [2:0] test_turn [1:0];
assign test_turn[PLAYER_A] = test_turn_A;
assign test_turn[PLAYER_B] = test_turn_B;

always @(posedge clk ) begin
    cnt <= cnt + 1;
    case (machine_state)
    IDLE: begin
        signal_action <= 1;
    end
    WAIT: begin
        signal_cleared <= 0;
        signal_action <= 0;
        signal_start <= 1;
    end
    CLR_CNT1: begin
        signal_start <= 0;
        signal_action <= 0;
        signal_cleared <= 1;
    end
    START: begin
        signal_cleared <= 0;
        signal_react <= 1;
        //signal_overflow <= ~signal_react;
    end
    STORAGE: begin
        signal_react <= 0;
        signal_overflow <= 0;
        if (test_turn[cur_player] == 3'd7) begin
            signal_average <= 1;
        end
        else signal_action <= 1;
    end
    CLR_CNT2: begin
        signal_action <= 0;
        signal_cleared <= 1;
    end
    AVERAGE: begin
        signal_average <= 0;
        if (test_turn_A == 3'd7 && test_turn_B == 3'd7) signal_compare <= 1;
        else if (test_turn[~cur_player] != 3'd7)begin
            signal_action <= 1;
            cur_player <= ~cur_player;
        end
    end
    COMPARE: begin
        #83 $finish;
        signal_compare <= 0;
    end
    endcase
end

StateMachine u_StateMachine(
    .clk               (clk              ),
    .rstn              (rstn             ),
    .cur_player        (cur_player       ),
    .signals           (signals          ),
    .react_time        (react_time[cur_player]),

    .out_machine_state (machine_state    ),
    .avr_react_time_A  (avr_react_time_A ),
    .avr_react_time_B  (avr_react_time_B ),
    .test_turn_A       (test_turn_A      ),
    .test_turn_B       (test_turn_B      )
);

RGB u_RGB(
    .clk              (clk              ),
    .rstn             (rstn             ),
    .cur_player       (cur_player       ),
    .machine_state    (machine_state    ),
    .test_turn_A      (test_turn_A      ),
    .test_turn_B      (test_turn_B      ),
    .avr_react_time_A (avr_react_time_A ),
    .avr_react_time_B (avr_react_time_B ),
    .rgb1             (rgb1             ),
    .rgb2             (rgb2             )
);

endmodule //TB_RGB