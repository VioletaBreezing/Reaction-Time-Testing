module RGB (
    input  wire       clk, rstn,
    input  wire       cur_player,
    input  wire [2:0] machine_state,
    input  wire [2:0] test_turn_A, test_turn_B,
    input  wire [9:0] avr_react_time_A, avr_react_time_B,
    output wire [2:0] rgb1, rgb2
);
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

    wire [9:0] avr_react_time [1:0];
    assign avr_react_time[PLAYER_A] = avr_react_time_A;
    assign avr_react_time[PLAYER_B] = avr_react_time_B;

    // 颜色
    parameter RED   = 3'b001;
    parameter BLUE  = 3'b100;
    parameter GREEN = 3'b010;
    parameter WHITE = 3'b111;
    parameter BLACK = 3'b000;

    // 亮度
    parameter FULL  = 1'b1;
    parameter SEMI  = 1'b0;

    reg [2:0] color  [1:0];
    reg [1:0] bright;
    always @(posedge clk or negedge rstn) begin
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

            bright [PLAYER_A] <= (avr_react_time[PLAYER_A] <= avr_react_time[PLAYER_B]) ? FULL : SEMI;
            bright [PLAYER_B] <= (avr_react_time[PLAYER_A] >= avr_react_time[PLAYER_B]) ? FULL : SEMI;
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

    wire pwm1;
    PWM u1_PWM(
    	.clk        (clk    ),
        .rstn       (rstn   ),
        .bright     (bright[PLAYER_A]),
        .pwm_div256 (pwm1   )
    );

    wire pwm2;
    PWM u2_PWM(
    	.clk        (clk    ),
        .rstn       (rstn   ),
        .bright     (bright[PLAYER_B]),
        .pwm_div256 (pwm2   )
    );

    assign rgb1 = ~(color[PLAYER_A] & {3{pwm1}});
    assign rgb2 = ~(color[PLAYER_B] & {3{pwm2}});

endmodule //RGB