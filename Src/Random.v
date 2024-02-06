module Random (
    input  wire        clk, rstn,
    input  wire [2:0]  machine_state,
    output reg  [13:0] rand_num  // 随机数 1000~9999
);
    // 状态机参数
    parameter WAIT     = 3'd1;

    reg [15:0] rand;               // 随机数生成器的原始输出 0~65535
    reg        rand_reload;        // 置高，随机数重载

    // 重整随机数范围
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin 
            rand_reload <= 1'd1;
            rand_num    <= 14'd1000;
        end
        else if (machine_state != WAIT)
            rand_reload <= 1'd1;
        else begin 
            rand_reload <= 1'd0;
            rand_num    <= 14'd1000 + rand % 14'd9000;  // 获得 1000~9999 范围内随机数
        end
    end

    // 伪随机序列发生器
    always @(posedge clk or negedge rstn) begin
		if (!rstn)
			rand <= 16'hffff;
		else if (rand_reload)
			rand <= {rand[14:0], rand[15]} ^ {4'b0, rand[15], 4'b0, rand[15], 6'b0};
	end

endmodule //Random