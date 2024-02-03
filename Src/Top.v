module Top (
    input  wire       clk_12MHz,
    input  wire [3:0] key, swi,
    output reg  [7:0] led,
    output wire [2:0] rgb1, rgb2,
    output wire [8:0] seg1, seg2
);
    // 系统输入
    wire   sys_clk, rstn;
    assign sys_clk = clk_12MHz;   // 系统时钟
    assign rstn    = swi[3];      // 系统复位

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

    // 状态机输入信号
    wire   signal_action, signal_react, signal_average, signal_compare;   // 4 个按键：启动、反应、平均、比较
    wire   signal_start,  signal_overflow, signal_cleared;                // start: 随机延时结束，开始测量计时
                                                                          // overflow: 测量超时溢出
                                                                          // cleared: 计时器清零完成

    assign signal_action  = ~key[0];
    assign signal_react   = ~key[1];
    assign signal_average = ~key[2];
    assign signal_compare = ~key[3];

    wire   cur_player;
    assign cur_player = swi[0];         // 切换队友

    // 状态机变量
    reg  [2:0]  machine_state;          // 状态寄存器
    reg  [12:0] sum_react_time [1:0];   // 累加时间寄存器
    reg  [2:0]  test_turn      [1:0];   // 测试轮次寄存器
    wire [15:0] react_time;             // 单次测量时间

    // 状态转移逻辑
    always @(posedge sys_clk or negedge rstn) begin
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
                    sum_react_time[cur_player] <= sum_react_time[cur_player] + react_time[12:0];
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

    // 时钟分频
    wire clk_1KHz, clk_2Hz;
    ClockDivider u_ClockDivider (
    	.rstn      (rstn     ),
        .clk_12MHz (clk_12MHz),
        .clk_1KHz  (clk_1KHz ),
        .clk_2Hz   (clk_2Hz  )
    );

    // 随机数生成
    wire [15:0] rand_num_raw;       // 随机数生成器的原始输出 0~65535
    reg         rand_reload;        // 置高，随机数重载
    reg  [15:0] rand_num;           // 重整过范围的随机数 1000~9999

    always @(posedge sys_clk or negedge rstn) begin
        if (!rstn) begin 
            rand_reload <= 1'd1;
            rand_num    <= 16'd1000;
        end
        else if (machine_state != WAIT)
            rand_reload <= 1'd1;
        else begin 
            rand_reload <= 1'd0;
            rand_num    <= 16'd1000 + rand_num_raw % 16'd9000;  // 获得 1000~9999 范围内随机数
        end
    end

    RanGen u_RanGen (
        .clk    (sys_clk     ),
        .rstn   (rstn        ),
        .reload (rand_reload ),
        .rand   (rand_num_raw)
    );

    // 计数器，既作延时，也作测量
    wire [15:0] timer_count;
    wire        timer_enable, timer_clear;

    wire [15:0] delay_count;

    assign react_time  = timer_count;
    assign delay_count = timer_count;

    assign signal_start    = (delay_count == rand_num);
    assign signal_overflow = (react_time  == 16'd999);
    assign signal_cleared  = (timer_count == 16'd0);

    assign timer_enable = ((machine_state == WAIT)  && (!signal_start)) ||
                          ((machine_state == START) && (!signal_overflow));
    assign timer_clear  = (machine_state == CLR_CNT1) || (machine_state == CLR_CNT2);

    Counter u_Timer(
    	.clk       (clk_1KHz    ),
        .rstn      (rstn        ),
        .enable    (timer_enable),
        .clear     (timer_clear ),
        .count     (timer_count )
    );

    // 数码管显示控制
    wire [15:0] bcdcode;
    reg  [9:0]  data_display;
    reg         enable_circle_shift;
    always @(posedge sys_clk or negedge rstn) begin
        if (!rstn) begin
            enable_circle_shift <= 1'b0;
            data_display        <= 10'b0;
        end
        else if (machine_state == START) begin
            data_display        <= react_time[9:0];
            enable_circle_shift <= 1'b0;
        end
        else if (machine_state == STORAGE) begin
            data_display        <= react_time[9:0];
            enable_circle_shift <= 1'b1;
        end
        else if (machine_state == AVERAGE) begin
            data_display        <= sum_react_time[cur_player][12:3];
            enable_circle_shift <= 1'b1;
        end
        else if (machine_state == COMPARE) begin
            data_display        <= (sum_react_time[PLAYER_A] <= sum_react_time[PLAYER_B]) ? 
                                   sum_react_time[PLAYER_A][12:3] : sum_react_time[PLAYER_B][12:3];
            enable_circle_shift <= 1'b1;
        end
        else begin
            data_display        <= 10'b0;
            enable_circle_shift <= 1'b0;
        end
    end

    Binary2BCD u_Binary2BCD(
        .bitcode (data_display),
        .bcdcode (bcdcode     )
    );

    wire [3:0] digit1, digit0;
    CircleShift u_CircleShift(
    	.clk         (clk_2Hz            ),
        .rstn        (rstn               ),
        .enable      (enable_circle_shift),
        .in_digit_2  (bcdcode [11:8]     ),
        .in_digit_1  (bcdcode [7:4]      ),
        .in_digit_0  (bcdcode [3:0]      ),
        .out_digit_1 (digit1             ),
        .out_digit_0 (digit0             )
    );
    
    SegmentEncoder u_SegmentEncoder(
    	.data_1 (digit1),
        .data_2 (digit0),
        .seg_1  (seg1  ),
        .seg_2  (seg2  )
    );

    // RGB 控制
    parameter RED   = 3'b001;
    parameter BLUE  = 3'b100;
    parameter GREEN = 3'b010;
    parameter WHITE = 3'b111;
    parameter BLACK = 3'b000;

    parameter FULL  = 1'b1;     // 亮度：大亮
    parameter SEMI  = 1'b0;     // 亮度：半亮

    reg [2:0] color  [1:0];
    reg [1:0] bright;
    always @(posedge sys_clk or negedge rstn) begin
        if (!rstn) begin
            color [PLAYER_A] <= BLACK;
            color [PLAYER_B] <= BLACK;
            bright           <= {FULL, FULL};
        end
        else if (machine_state == AVERAGE) begin
            color [cur_player]  <= (test_turn[cur_player] == 3'd7) ? RED : BLACK;
            color [~cur_player] <= BLACK;
            bright <= {FULL, FULL};
        end
        else if (machine_state == COMPARE) begin
            color  [PLAYER_A]  <= WHITE;
            color  [PLAYER_B]  <= WHITE;

            bright [PLAYER_A] <= (sum_react_time[PLAYER_A] <= sum_react_time[PLAYER_B]) ? FULL : SEMI;
            bright [PLAYER_B] <= (sum_react_time[PLAYER_A] >= sum_react_time[PLAYER_B]) ? FULL : SEMI;
        end
        else if (machine_state == IDLE) begin
            color [PLAYER_A] <= BLACK;
            color [PLAYER_B] <= BLACK;
            bright <= {FULL, FULL};
        end
        else if (machine_state == STORAGE) begin
            color [cur_player]  <= (test_turn[cur_player] == 3'd7) ? BLUE: GREEN;
            color [~cur_player] <= BLACK;
            bright <= {FULL, FULL};
        end
        else begin
            color  [cur_player]  <= GREEN;
            color  [~cur_player] <= BLACK;
            bright <= {FULL, FULL};
        end
    end

    RGB_LED u_RGB_LED(
    	.clk      (sys_clk          ),
        .rstn     (rstn             ),
        .color1   (color  [PLAYER_A]),
        .color2   (color  [PLAYER_B]),
        .bright1  (bright [PLAYER_A]),
        .bright2  (bright [PLAYER_B]),
        .rgb_led1 (rgb1             ),
        .rgb_led2 (rgb2             )
    );
    
    // LED 控制
    parameter ON  = 1'b0;
    parameter OFF = 1'b1;
    always @(posedge sys_clk or negedge rstn) begin
        if (!rstn)
            led <= {8{OFF}};
        else if (machine_state == START || machine_state == STORAGE)
            led[test_turn[cur_player]] <= ON;
        else if (machine_state == AVERAGE)
            led <= (test_turn[cur_player] == 3'd7) ? {8{ON}} : {8{OFF}};
        else
            led <= {8{OFF}};
    end

endmodule //Top