// by: Huynh Trung Kien
module regfile (
    input  logic        i_clk,
    input  logic        i_reset,     // active-high bên trong
    input  logic [4:0]  i_rs1_addr,
    input  logic [4:0]  i_rs2_addr,
    output logic [31:0] o_rs1_data,
    output logic [31:0] o_rs2_data,
    input  logic [4:0]  i_rd_addr,
    input  logic [31:0] i_rd_data,
    input  logic        i_rd_wren
);
    logic [31:0] regs [0:31];
    // Khởi tạo
/*    initial begin
      for (integer i = 0; i < 32; i = i + 1) regs[i] = 32'b0;
    end */
	 
    // Đọc: x0 luôn 0
    always_comb begin
      o_rs1_data = (i_rs1_addr == 5'd0) ? 32'b0 : regs[i_rs1_addr];
      o_rs2_data = (i_rs2_addr == 5'd0) ? 32'b0 : regs[i_rs2_addr];
    end
    // Ghi: cấm ghi x0
    always_ff @(posedge i_clk or negedge i_reset) begin
		if (~i_reset) for (integer i = 0; i < 32; i = i + 1) regs[i] <= 32'b0;
		else 
      if (i_rd_wren && (i_rd_addr != 5'd0)) begin
        regs[i_rd_addr] <= i_rd_data;
      end
    end
endmodule
