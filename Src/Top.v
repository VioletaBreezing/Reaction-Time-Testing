module Top (
    input  wire       clk_12MHz,
    input  wire [3:0] key, swi,
    output wire [7:0] led,
    output wire [2:0] rgb1, rgb2,
    output wire [8:0] seg1, seg2
);
    // 系统输入
    wire   sys_clk, rstn;
    assign sys_clk = clk_12MHz;   // 系统时钟
    assign rstn    = swi[3];      // 系统复位

    // 状态机输入信号
    wire   signal_action, signal_react, signal_average, signal_compare;   // 4 个按键：启动、反应、平均、比较
    wire   signal_start,  signal_overflow, signal_cleared;                // start: 随机延时结束，开始测量计时
                                                                          // overflow: 测量超时溢出
                                                                          // cleared: 计时器清零完成
    assign signal_action  = ~key[0];
    assign signal_react   = ~key[1];
    assign signal_average = ~key[2];
    assign signal_compare = ~key[3];

    // 状态机输入
    wire [6:0] signals;
    assign signals = {signal_action, signal_react, signal_average, signal_compare, 
                      signal_start, signal_overflow, signal_cleared};
    
    wire   cur_player;
    assign cur_player = swi[0];         // 切换队友

    wire [9:0] react_time;             // 单次测量时间

    // 状态机输出
    wire [2:0]  machine_state;
    wire [9:0]  avr_react_time_A, avr_react_time_B;
    wire [2:0]  test_turn_A, test_turn_B;

    StateMachine u_StateMachine(
    	.clk               (sys_clk          ),
        .rstn              (rstn             ),
        .cur_player        (cur_player       ),
        .signals           (signals          ),
        .react_time        (react_time       ),
        .out_machine_state (machine_state    ),
        .avr_react_time_A  (avr_react_time_A ),
        .avr_react_time_B  (avr_react_time_B ),
        .test_turn_A       (test_turn_A      ),
        .test_turn_B       (test_turn_B      )
    );
    
    // 时钟分频
    wire clk_1KHz, clk_2Hz;
    ClockDivider u_ClockDivider (
    	.rstn      (rstn     ),
        .clk_12MHz (clk_12MHz),
        .clk_1KHz  (clk_1KHz ),
        .clk_2Hz   (clk_2Hz  )
    );

    // 随机数生成
    wire [13:0] rand_num;
    Random u_Random(
    	.clk           (sys_clk       ),
        .rstn          (rstn          ),
        .machine_state (machine_state ),
        .rand_num      (rand_num      )
    );
    
    // 计数器，既作延时，也作测量
    Timer u_Timer(
    	.clk             (clk_1KHz        ),
        .rstn            (rstn            ),
        .machine_state   (machine_state   ),
        .rand_num        (rand_num        ),
        .signal_start    (signal_start    ),
        .signal_overflow (signal_overflow ),
        .signal_cleared  (signal_cleared  ),
        .react_time      (react_time      )
    );

    // 数码管显示控制
    Display u_Display(
    	.clk              (sys_clk          ),
        .rstn             (rstn             ),
        .clk_2Hz          (clk_2Hz          ),
        .cur_player       (cur_player       ),
        .machine_state    (machine_state    ),
        .react_time       (react_time       ),
        .avr_react_time_A (avr_react_time_A ),
        .avr_react_time_B (avr_react_time_B ),
        .seg1             (seg1             ),
        .seg2             (seg2             )
    );

    // RGB 控制
    RGB u_RGB(
    	.clk              (sys_clk          ),
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
    
    // LED 控制
    LED u_LED(
    	.clk           (sys_clk       ),
        .rstn          (rstn          ),
        .cur_player    (cur_player    ),
        .machine_state (machine_state ),
        .test_turn_A   (test_turn_A   ),
        .test_turn_B   (test_turn_B   ),
        .led           (led           )
    );

endmodule //Top