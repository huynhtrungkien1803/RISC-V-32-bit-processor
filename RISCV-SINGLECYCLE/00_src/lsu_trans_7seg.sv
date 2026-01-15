// by: Huynh Trung Kien

//  trans_7seg.sv
//  Nhận 32-bit và xuất 4 mã HEX (HEX3..HEX0)
//  Mỗi nibble (4 bit) hiển thị 1 ký tự hex

module lsu_trans_7seg (
    input  logic [31:0] i_bin,
    output logic [6:0]  o_7seg0,
    output logic [6:0]  o_7seg1,
    output logic [6:0]  o_7seg2,
    output logic [6:0]  o_7seg3
);
    // Tách 4 nibble thấp (hiển thị 4 chữ số HEX)
    logic [3:0] nib0, nib1, nib2, nib3;
    assign nib0 = i_bin[3:0];
    assign nib1 = i_bin[7:4];
    assign nib2 = i_bin[11:8];
    assign nib3 = i_bin[15:12];

    // Gọi 4 module con để chuyển từng nibble
    hex_to_7seg HEX0 (.i_hex(nib0), .o_seg(o_7seg0));
    hex_to_7seg HEX1 (.i_hex(nib1), .o_seg(o_7seg1));
    hex_to_7seg HEX2 (.i_hex(nib2), .o_seg(o_7seg2));
    hex_to_7seg HEX3 (.i_hex(nib3), .o_seg(o_7seg3));

endmodule

//  hex_to_7seg.sv
//  Chuyển nibble (4-bit) thành mã 7 đoạn (active-low)

module hex_to_7seg (
    input  logic [3:0] i_hex,
    output logic [6:0] o_seg
);
    always_comb begin
        case (i_hex)
            4'h0: o_seg = 7'b1000000;
            4'h1: o_seg = 7'b1111001;
            4'h2: o_seg = 7'b0100100;
            4'h3: o_seg = 7'b0110000;
            4'h4: o_seg = 7'b0011001;
            4'h5: o_seg = 7'b0010010;
            4'h6: o_seg = 7'b0000010;
            4'h7: o_seg = 7'b1111000;
            4'h8: o_seg = 7'b0000000;
            4'h9: o_seg = 7'b0010000;
            4'hA: o_seg = 7'b0001000;
            4'hB: o_seg = 7'b0000011;
            4'hC: o_seg = 7'b1000110;
            4'hD: o_seg = 7'b0100001;
            4'hE: o_seg = 7'b0000110;
            4'hF: o_seg = 7'b0001110;
            default: o_seg = 7'b1111111;  // tắt hết
        endcase
    end
endmodule
