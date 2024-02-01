module RGB_LED (
    input  wire clk,
    input  wire rstn,
    input  wire [2:0] color1, color2,
    input  wire bright1, bright2,     // bright = 0, 1 , 0 半亮 1大亮
    output wire [2:0] rgb_led1, rgb_led2
);
    wire pwm1, pwm2;

    PWM u1_PWM(
    	.clk        (clk    ),
        .rstn       (rstn   ),
        .bright     (bright1),
        .pwm_div256 (pwm1   )
    );

    PWM u2_PWM(
    	.clk        (clk    ),
        .rstn       (rstn   ),
        .bright     (bright2),
        .pwm_div256 (pwm2   )
    );

    assign rgb_led1 = ~(color1 & {3{pwm1}});
    assign rgb_led2 = ~(color2 & {3{pwm2}});
    
endmodule //RGB_LED