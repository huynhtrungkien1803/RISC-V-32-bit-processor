// by: Huynh Trung Kien - Nguyen Dinh Trong Khoi

module single_cycle (
  input  logic        i_clk,
  input  logic        i_reset,          // active-low
  output logic [31:0] o_pc_debug,
  output logic        o_insn_vld,

  // I/O memory-mapped
  output logic [31:0] o_io_ledr,
  output logic [31:0] o_io_ledg,
  output logic [6:0]  o_io_hex0,
  output logic [6:0]  o_io_hex1,
  output logic [6:0]  o_io_hex2,
  output logic [6:0]  o_io_hex3,
  output logic [6:0]  o_io_hex4,
  output logic [6:0]  o_io_hex5,
  output logic [6:0]  o_io_hex6,
  output logic [6:0]  o_io_hex7,
  output logic [31:0] o_io_lcd,
  input  logic [31:0] i_io_sw
);

  // PC + 4
  logic [31:0] pc, pc_next, pc_four;
  //assign pc_four = pc + 32'd4;
  addsub32 addsub_pc4 (	// pc_four = pc + 32'd4
		.i_a(pc),
		.i_b(32'd4),
		.Cin(1'b0),		//add
		.Cout(),
		.o_s(pc_four)
	);

  always_ff @(posedge i_clk or negedge i_reset) begin
    if (!i_reset) pc <= 32'b00;
    else	pc <= pc_next;
  end
  assign o_pc_debug = pc;

  // Instruction memory (I$)
  logic [31:0] instr;

  instruction_memory I$ (
    .i_addr  (pc[15:0]),          // BYTE address -> lấy 16 bit thấp của PC
    .o_rdata (instr)
  );

  // Control Unit
  logic        pc_sel, rd_wren, br_un, opa_sel, opb_sel, mem_wren; //insn_vld;
  logic [3:0]  alu_op;
  logic [1:0]  wb_sel;
  logic [2:0]  ld_en;     
  logic [2:0]  imm_sel;
  logic br_less, br_equal;
  
  logic [2:0] mem_funct3;

  ctrl_unit u_cu (
        .i_instr(instr),
        .i_br_less(br_less), 
		  .i_br_equal(br_equal),
        .o_pc_sel(pc_sel), 
		  .o_rd_wren(rd_wren), 
		  .o_insn_vld(o_insn_vld),
        .o_br_un(br_un), 
		  .o_opa_sel(opa_sel), 
		  .o_opb_sel(opb_sel),
        .o_alu_op(alu_op), 
		  .o_mem_wren(mem_wren),
        .o_wb_sel(wb_sel), 
		  
		  .o_lsu_funct3(mem_funct3)
    );
  //assign o_insn_vld = insn_vld;

  // Regfile
  logic [4:0]  rs1_addr, rs2_addr, rd_addr;
  logic [31:0] rs1_data, rs2_data, rd_data;

  assign rs1_addr = instr[19:15];
  assign rs2_addr = instr[24:20];
  assign rd_addr  = instr[11:7];

  regfile RF (
    .i_clk      (i_clk),
    .i_reset    (i_reset),
    .i_rs1_addr (rs1_addr),
    .i_rs2_addr (rs2_addr),
    .o_rs1_data (rs1_data),
    .o_rs2_data (rs2_data),
    .i_rd_addr  (rd_addr),
    .i_rd_data  (rd_data),
    .i_rd_wren  (rd_wren)
  );

  // Immediate Generator
	logic [31:0] imm;

	imm_gen IG (
		.i_instr (instr),
		.o_imm   (imm)
	);

  // Operand muxes to ALU
	logic [31:0] op_a, op_b, alu_data;
	assign op_a = (opa_sel) ? pc  : rs1_data;
	assign op_b = (opb_sel) ? imm : rs2_data;

	alu ALU (
		.i_op_a     (op_a),
		.i_op_b     (op_b),
		.i_alu_op   (alu_op),
		.o_alu_data (alu_data)
	);

  // BRC
  brc BRC (
    .i_rs1_data (rs1_data),
    .i_rs2_data (rs2_data),
    .i_br_un    (br_un),
    .o_br_less  (br_less),
    .o_br_equal (br_equal)
  );


  // LSU
  logic [31:0] ld_data;
  lsu u_lsu (
		  .i_clk(i_clk), 
		  .i_reset(i_reset),
		  .i_lsu_addr(alu_data), 
		  .i_st_data(rs2_data),
        .i_lsu_wren(mem_wren), 
		  .i_funct3(mem_funct3),
        .o_ld_data(ld_data),
        .o_io_ledr(o_io_ledr), 
		  .o_io_ledg(o_io_ledg),
		  
        .o_io_hex0(o_io_hex0),
		  .o_io_hex1(o_io_hex1),
        .o_io_hex2(o_io_hex2), 
		  .o_io_hex3(o_io_hex3),
        .o_io_hex4(o_io_hex4), 
		  .o_io_hex5(o_io_hex5),
        .o_io_hex6(o_io_hex6), 
		  .o_io_hex7(o_io_hex7),
		  
        .o_io_lcd(o_io_lcd),
        .i_io_sw(i_io_sw)
  );


  // WB mux
  logic [31:0] wb_data;
  always_comb begin
    unique case (wb_sel)
      2'b00: wb_data = pc_four;   // PC+4
      2'b01: wb_data = alu_data;   // ALU
      2'b10: wb_data = ld_data;    // LOAD
		2'b11: wb_data = imm;		//	LUI
      //default: wb_data = 32'h0;
    endcase
  end
  assign rd_data = wb_data;

  assign pc_next = (pc_sel) ? alu_data : pc_four;

endmodule
