module CircleShift (
    input  wire       clk,
    input  wire       rstn,
    input  wire       enable,
    input  wire [3:0] in_digit_2, in_digit_1, in_digit_0,
    output wire [3:0] out_digit_1, out_digit_0
);
    reg [1:0] cnt;

    always @(posedge clk or negedge rstn) begin
        if (!rstn) cnt <= 2'd0;
        else if (enable) cnt <= cnt + 2'd1;
        else cnt <= 2'd0;
    end

    assign out_digit_1 = (in_digit_1 & {4{cnt == 2'd0}}) |
                         (in_digit_0 & {4{cnt == 2'd1}}) |
                         (4'd10      & {4{cnt == 2'd2}}) |
                         (in_digit_2 & {4{cnt == 2'd3}});

    assign out_digit_0 = (in_digit_0 & {4{cnt == 2'd0}}) |
                         (4'd10      & {4{cnt == 2'd1}}) |
                         (in_digit_2 & {4{cnt == 2'd2}}) |
                         (in_digit_1 & {4{cnt == 2'd3}});

endmodule //CircleShift