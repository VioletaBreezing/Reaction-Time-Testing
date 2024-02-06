module LED (
    input  wire       clk, rstn,
    input  wire       cur_player,
    input  wire [2:0] machine_state,
    input  wire [2:0] test_turn_A, test_turn_B,
    output reg  [7:0] led 
);
    // 状态机参数
    parameter START    = 3'd3;
    parameter STORAGE  = 3'd4;
    parameter AVERAGE  = 3'd6;
    parameter PLAYER_A = 1'b1;
    parameter PLAYER_B = 1'b0;

    wire [2:0] test_turn [1:0];
    assign test_turn[PLAYER_A] = test_turn_A;
    assign test_turn[PLAYER_B] = test_turn_B;

    parameter ON  = 1'b0;
    parameter OFF = 1'b1;
    always @(posedge clk or negedge rstn) begin
        if (!rstn)
            led <= {8{OFF}};
        else if (machine_state == START || machine_state == STORAGE)
            led[test_turn[cur_player]] <= ON;
        else if (machine_state == AVERAGE)
            led <= (test_turn[cur_player] == 3'd7) ? {8{ON}} : {8{OFF}};
        else
            led <= {8{OFF}};
    end

endmodule //LED