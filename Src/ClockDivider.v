module ClockDivider (
    input  wire rstn,
    input  wire clk_12MHz,
    output reg  clk_1KHz,
    output reg  clk_2Hz
);

    reg [12:0] counter_1KHz;
    reg [21:0] counter_2Hz;

    always @(posedge clk_12MHz or negedge rstn) begin
        if (!rstn) begin
            counter_1KHz <= 13'd0;
            counter_2Hz  <= 22'd0;
            clk_1KHz <= 1'b0;
            clk_2Hz  <= 1'b0;
        end
        else begin
            if (counter_1KHz == 13'd5_999) begin
                counter_1KHz <= 13'd0;
                clk_1KHz <= ~clk_1KHz;
            end
            else counter_1KHz <= counter_1KHz + 13'd1;

            if (counter_2Hz == 22'd2_999_999) begin
                counter_2Hz <= 22'd0;
                clk_2Hz <= ~clk_2Hz;
            end
            else counter_2Hz <= counter_2Hz + 22'd1;
        end
    end

endmodule