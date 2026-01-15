// by: Nguyen Doan Gia Huy - Nguyen Dinh Trong Khoi 

module imm_gen(
input logic [31:0] i_instr,
output logic [31:0] o_imm
);

always_comb begin
case(i_instr[6:0])
7'b0010011: begin //I-type (Arithmetic)
if(i_instr[31]) o_imm = {20'hFFFFF, i_instr[31:20]};
else 			  o_imm = {20'd0,i_instr[31:20]};
end
7'b0000011: begin //I-type (Load)
if(i_instr[31]) o_imm = {20'hFFFFF, i_instr[31:20]};
else 			  o_imm = {20'd0,i_instr[31:20]};
end
7'b1100111: begin //I-type (JALR)
if(i_instr[31]) o_imm = {20'hFFFFF, i_instr[31:20]};
else 			  o_imm = {20'd0,i_instr[31:20]};
end
7'b0100011: begin //S-type
if(i_instr[31]) o_imm = {20'hFFFFF, i_instr[31:25], i_instr[11:7]};
else 			  o_imm = {20'd0, i_instr[31:25], i_instr[11:7]};
end
7'b1100011: begin //B-type
if(i_instr[31]) o_imm = {19'h7FFFF, i_instr[31], i_instr[7], i_instr[30:25], i_instr[11:8], 1'd0};
else 			  o_imm = {19'h0, i_instr[31], i_instr[7], i_instr[30:25], i_instr[11:8], 1'd0};
end
7'b1101111: begin //J-type
if(i_instr[31]) o_imm = {11'h7FF, i_instr[31], i_instr[19:12], i_instr[20], i_instr[30:25], i_instr[24:21], 1'b0};
else 			  o_imm = {11'h0, i_instr[31], i_instr[19:12], i_instr[20], i_instr[30:25], i_instr[24:21], 1'b0};
end
7'b0110111: o_imm = {i_instr[31:12], 12'h0}; //U-Type (LUI)
7'b0010111: o_imm = {i_instr[31:12], 12'h0}; //U-Type (AUIPC)
default: o_imm = 32'h0; //If none
endcase
end
endmodule