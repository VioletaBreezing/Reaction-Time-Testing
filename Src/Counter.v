module Counter (
    input  wire clk,
    input  wire rstn,
    input  wire enable,
    input  wire clear,
    output reg [15:0] count,
    output reg carry_out
);

    always @(posedge clk or negedge rstn) begin
        if (!rstn || clear) begin
            count     <= 16'd0;
            carry_out <= 1'b0;
        end
        else if (enable) begin
            count <= count + 16'd1;
            if (count == 16'b1111_1111_1111_1111)
                carry_out <= 1'b1;
            else
                carry_out <= 1'b0;
        end
        else begin
            count <= count;
            carry_out <= carry_out;
        end
    end

endmodule //Counter