`timescale 1ns/1ns

module TB_RGB_LED;

initial begin
    $dumpfile ("./Build/TB_RGB_LED.vcd");
    $dumpvars;
end

// 输入
reg       clk, rstn;
reg       bright1, bright2;
reg [2:0] color1,  color2;

// 输出
wire [2:0] rgb_led1, rgb_led2;

parameter BLACK = 3'b000;
parameter WHITE = 3'b111;
parameter RED   = 3'b001;
parameter BLUE  = 3'b100;
parameter GREEN = 3'b010;

parameter FULL = 1'b1;
parameter SEMI = 1'b0;

initial begin
    clk = 1'b0;
    rstn = 1'b0;
    color1 = BLACK;
    color2 = BLACK;
    bright1 = FULL;
    bright2 = FULL;

    #10 rstn = 1'b1;

    #2560;
    color1 = RED;  bright1 = SEMI;
    color2 = BLUE; bright2 = FULL;

    #2560;
    color1 = GREEN; bright1 = FULL;
    color2 = WHITE; bright2 = SEMI;

    #2560 $finish;
end

always #5 clk = ~clk;  // 周期10ns, 100MHz

RGB_LED u_RGB_LED(
    .clk      (clk      ),
    .rstn     (rstn     ),
    .color1   (color1   ),
    .color2   (color2   ),
    .bright1  (bright1  ),
    .bright2  (bright2  ),
    .rgb_led1 (rgb_led1 ),
    .rgb_led2 (rgb_led2 )
);

endmodule