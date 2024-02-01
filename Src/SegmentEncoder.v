module SegmentEncoder (
    input  wire [3:0] data_1,
    input  wire [3:0] data_2,
    output wire [8:0] seg_1,
    output wire [8:0] seg_2
);
    reg [8:0] seg_table [10:0];                          //段码表
    
    initial begin
        seg_table[0]  = 9'h3f;                           //7段显示数字  0
        seg_table[1]  = 9'h06;                           //7段显示数字  1
	    seg_table[2]  = 9'h5b;                           //7段显示数字  2
	    seg_table[3]  = 9'h4f;                           //7段显示数字  3
	    seg_table[4]  = 9'h66;                           //7段显示数字  4
	    seg_table[5]  = 9'h6d;                           //7段显示数字  5
	    seg_table[6]  = 9'h7d;                           //7段显示数字  6
	    seg_table[7]  = 9'h07;                           //7段显示数字  7
	    seg_table[8]  = 9'h7f;                           //7段显示数字  8
	    seg_table[9]  = 9'h6f;                           //7段显示数字  9
        seg_table[10] = 9'h100;                          //不显示
    end
    
    assign seg_1 = seg_table[data_1];
    assign seg_2 = seg_table[data_2];
    
endmodule