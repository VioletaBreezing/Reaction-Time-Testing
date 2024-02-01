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
    parameter IDLE    = 3'd0;
    parameter WAIT    = 3'd1;
    parameter START   = 3'd2;
    parameter STORAGE = 3'd3;
    parameter AVERAGE = 3'd4;
    parameter COMPARE = 3'd5;
    parameter PLAYER_A = 1'b1;
    parameter PLAYER_B = 1'b0;

    // 状态机输入信号
    wire   signal_action, signal_react, signal_average, signal_compare, signal_start, signal_overflow;
    assign signal_action  = ~key[0];
    assign signal_react   = ~key[1];
    assign signal_average = ~key[2];
    assign signal_compare = ~key[3];

    wire   cur_player;
    assign cur_player = swi[0];

    // 状态机变量
    reg  [2:0]  machine_state;           // 状态寄存器
    reg  [12:0] sum_react_time [1:0];    // 累加时间寄存器
    reg  [2:0]  test_turn      [1:0];    // 测试轮次寄存器
    wire [15:0] react_time;              // 单次测量时间

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
                machine_state <= signal_start ? START : machine_state;
            end
            START  : begin
                if (signal_react || signal_overflow) begin  // signal_react 由按键发出，signal_overflow 由毫秒计时器发出
                    machine_state <= STORAGE;
                    sum_react_time[cur_player] <= sum_react_time[cur_player] + react_time[12:0];
                end
                else machine_state <= machine_state;
            end
            STORAGE: begin
                if (test_turn[cur_player] == 3'd7 && signal_average)
                    machine_state <= AVERAGE;
                else if (test_turn[cur_player] != 3'd7 && signal_action) begin
                    machine_state <= WAIT;
                    test_turn[cur_player] <= test_turn[cur_player] + 3'd1;
                end
                else machine_state <= machine_state;
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

    // 根据随机数进行延时模块
    wire [15:0] delay_count;
    wire        delay_enable, delay_clear;
    assign signal_start = (delay_count == rand_num);
    assign delay_enable = (machine_state == WAIT) && (!signal_start);
    assign delay_clear  = (machine_state != WAIT);
    Counter u0_Counter(
    	.clk    (clk_1KHz    ),
        .rstn   (rstn        ),
        .enable (delay_enable),
        .clear  (delay_clear ),
        .count  (delay_count )
    );
    
    // 反应时间计时器
    wire count_enable, count_clear;
    assign signal_overflow = (react_time == 16'd999);       // 测量反应时间上限定为 1s
    assign count_enable    = (machine_state == START) && (!signal_overflow);
    assign count_clear     = (machine_state != START) && (machine_state != STORAGE);
    Counter u1_Counter(
    	.clk    (clk_1KHz    ),
        .rstn   (rstn        ),
        .enable (count_enable),
        .clear  (count_clear ),
        .count  (react_time  )
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
            data_display        <= react_time[9:0];
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

    parameter FULL  = 1'b1;
    parameter SEMI  = 1'b0;

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
            led[test_turn[cur_player]] <= 1'b0;
        else if (machine_state == AVERAGE)
            led <= (test_turn[cur_player] == 3'd7) ? {8{ON}} : {8{OFF}};
        else
            led <= {8{OFF}};
    end

endmodule //Top