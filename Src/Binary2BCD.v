module Binary2BCD (
    input  wire [9:0]  bitcode,
    output reg  [15:0] bcdcode
);
    integer i;
    always @(bitcode) begin
        bcdcode = 16'd0;
        for (i = 9; i >= 0; i = i - 1) begin
            if (bcdcode[15:12] > 4'd4)
                bcdcode[15:12] = bcdcode[15:12] + 4'd3;
            if (bcdcode[11:8]  > 4'd4)
                bcdcode[11:8]  = bcdcode[11:8]  + 4'd3;
            if (bcdcode[7:4]   > 4'd4)
                bcdcode[7:4]   = bcdcode[7:4]   + 4'd3;
            if (bcdcode[3:0]   > 4'd4)
                bcdcode[3:0]   = bcdcode[3:0]   + 4'd3;
            bcdcode = bcdcode << 1;
            bcdcode[0] = bitcode[i];
        end
    end

endmodule //Binary2BCD