module Timer (
    input  wire        clk, rstn,
    input  wire [2:0]  machine_state,
    input  wire [13:0] rand_num,
    output wire        signal_start, signal_overflow, signal_cleared,
    output wire [9:0]  react_time
);
    // 状态机参数
    parameter WAIT     = 3'd1;
    parameter CLR_CNT1 = 3'd2;
    parameter START    = 3'd3;
    parameter CLR_CNT2 = 3'd5;

    wire [13:0] timer_count;
    wire        timer_enable, timer_clear;

    wire [13:0] delay_count;

    assign react_time  = timer_count[9:0];
    assign delay_count = timer_count;

    assign signal_start    = (delay_count == rand_num);
    assign signal_overflow = (react_time  == 10'd999);
    assign signal_cleared  = (timer_count == 14'd0);

    assign enable = ((machine_state == WAIT)  && (!signal_start)) ||
                    ((machine_state == START) && (!signal_overflow));
    assign clear  = (machine_state == CLR_CNT1) || (machine_state == CLR_CNT2);

    // 计数器
    reg [13:0] count;
    assign timer_count = count;
    
    always @(posedge clk or negedge rstn) begin
        if (!rstn || clear) 
            count     <= 14'd0;
        else if (enable)
            count <= count + 14'd1;
        else
            count <= count;
    end

endmodule //Timer