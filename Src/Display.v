module Display (
    input  wire       clk, rstn,
    input  wire       clk_2Hz,
    input  wire       cur_player,
    input  wire [2:0] machine_state,
    input  wire [9:0] react_time,
    input  wire [9:0] avr_react_time_A, avr_react_time_B,
    output wire [8:0] seg1, seg2
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

    wire [9:0] avr_react_time [1:0];
    assign avr_react_time[PLAYER_A] = avr_react_time_A;
    assign avr_react_time[PLAYER_B] = avr_react_time_B;

    // 数码管显示控制
    reg  [9:0]  data_display;
    reg         enable_circle_shift;
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            enable_circle_shift <= 1'b0;
            data_display        <= 10'b0;
        end
        else if (machine_state == START) begin
            data_display        <= react_time;
            enable_circle_shift <= 1'b0;
        end
        else if (machine_state == STORAGE) begin
            data_display        <= react_time;
            enable_circle_shift <= 1'b1;
        end
        else if (machine_state == AVERAGE) begin
            data_display        <= avr_react_time[cur_player];
            enable_circle_shift <= 1'b1;
        end
        else if (machine_state == COMPARE) begin
            data_display        <= (avr_react_time[PLAYER_A] <= avr_react_time[PLAYER_B]) ? 
                                    avr_react_time[PLAYER_A] :  avr_react_time[PLAYER_B];
            enable_circle_shift <= 1'b1;
        end
        else begin
            data_display        <= 10'b0;
            enable_circle_shift <= 1'b0;
        end
    end

    wire [15:0] bcdcode;
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

endmodule //Display