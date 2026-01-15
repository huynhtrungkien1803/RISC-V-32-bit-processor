// by: Huynh Trung Kien

module instruction_memory(
input logic [31:0] i_addr,
output logic [31:0] o_rdata
);

logic [31:0] imem [0:255];
initial $readmemh("./../02_test/isa_4b.hex", imem);

always_comb begin
o_rdata = imem[i_addr[12:2]];
end
endmodule

