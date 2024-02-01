module PWM (
    input  wire clk,
    input  wire rstn,
    input  wire bright,
    output reg  pwm_div256
);
    reg [7:0] cnt;
    reg [7:0] duty [1:0];

    initial begin
        duty[0] = 8'd4;
        duty[1] = 8'd254;
    end

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            cnt <= 8'd0;
            pwm_div256 <= 1'b0;
        end
        else begin
            cnt <= cnt + 8'd1;
            pwm_div256 <= (cnt <= duty[bright]) ? 1'b1 : 1'b0;
        end
    end

endmodule //PWM