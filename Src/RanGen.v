module RanGen(
	input  wire        clk,
	input  wire        rstn,
	input  wire        reload,
	output reg  [15:0] rand
);

	always @(posedge clk or negedge rstn) begin
		if (!rstn)
			rand <= 16'hffff;
		else if (reload)
			rand <= {rand[14:0], rand[15]} ^ {4'b0, rand[15], 4'b0, rand[15], 6'b0};
	end

endmodule