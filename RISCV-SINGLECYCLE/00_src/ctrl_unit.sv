/* -------------------------------------------- //
					ControlUnit.sv

	This module generates control signals for 
	other modules to ensure that all instruc-
	tions are executed correctly. 					

				by: Huynh Trung Kien

// -------------------------------------------- */

module ctrl_unit (
	output logic        o_pc_sel,     // PC select (0 if PC += 4, 1 if PC = alu_data)
	input  logic [31:0] i_instr,      // Instruction
	output logic        o_rd_wren,    // Write enable for the destination register
	output logic        o_insn_vld,   // Instruction valid (1 if vailid, 0 if unvailid)
	output logic        o_br_un,      // BRC's comparison mode (0 if signed, 1 if unsigned)
	input  logic        i_br_less,    // BRC's result (rs1 < rs2)
	input  logic        i_br_equal,   // BRC's result (rs1 = rs2)
	output logic        o_opa_sel,    // operand_a select (0 if rs1_data, 1 if pc)
	output logic        o_opb_sel,    // operand_b select (0 if rs2_data, 1 if imm)
	output logic [3:0]  o_alu_op,     // The operation to be performed (for ALU)
	output logic        o_mem_wren,   // Memory write enable (1 if writing, 0 if reading)
	output logic [1:0]  o_wb_sel,     // write back data select (00: pc_four, 01: alu_data, 10: ld_data, 11: 32'b0)
	
	output logic [2:0]  o_lsu_funct3	 // function3 to lsu
);
	assign o_lsu_funct3 = i_instr[14:12];
	
	always_comb begin
		case (i_instr[6:0])	// read the opcode
		
			7'b0110011: begin   // R_TYPE
				o_insn_vld = 1'b1;
				o_pc_sel   = 1'b0;
				o_rd_wren  = 1'b1;
				o_br_un    = 1'b0;
				o_opa_sel  = 1'b0;
				o_opb_sel  = 1'b0;
				o_alu_op   = 4'b1111;
				o_mem_wren = 1'b0;
				o_wb_sel   = 2'b01;
				
				case (i_instr[14:12]) // funct3
					3'b000: o_alu_op = (i_instr[30]) ? 4'b0001 : 4'b0000; // SUB / ADD
					3'b001: o_alu_op = 4'b0111;	// SLL
					3'b010: o_alu_op = 4'b0010;	// SLT
					3'b011: o_alu_op = 4'b0011;	// SLTU
					3'b100: o_alu_op = 4'b0100;	// XOR
					3'b101: o_alu_op = (i_instr[30]) ? 4'b1001 : 4'b1000; // SRA / SRL
					3'b110: o_alu_op = 4'b0101;	// OR
					3'b111: o_alu_op = 4'b0110;	// AND
					
					default: begin
						o_alu_op   = 4'b1111;
						o_insn_vld = 1'b0;
					end
				endcase
			end
			
			7'b1100011: begin   // B_TYPE
				o_insn_vld = 1'b1;
				o_pc_sel   = 1'b0;
				o_rd_wren  = 1'b0;
				o_br_un    = 1'b0;
				o_opa_sel  = 1'b1;
				o_opb_sel  = 1'b1;
				o_alu_op   = 4'b0000;
				o_mem_wren = 1'b0;
				o_wb_sel   = 2'b11;
				
				case (i_instr[14:12])	// funct3
					3'b000: o_pc_sel = (i_br_equal) ? 1'b1 : 1'b0; // BEQ
					3'b001: o_pc_sel = (i_br_equal) ? 1'b0 : 1'b1; // BNE
					3'b100: o_pc_sel = (i_br_less)  ? 1'b1 : 1'b0; // BLT
					3'b101: o_pc_sel = (i_br_less)  ? 1'b0 : 1'b1; // BGE
					
					3'b110: begin // BLTU
						o_br_un  = 1'b1;
						o_pc_sel = (i_br_less) ? 1'b1 : 1'b0;
					end
					
					3'b111: begin // BGEU
						o_br_un  = 1'b1;
						o_pc_sel = (i_br_less) ? 1'b0 : 1'b1;
					end
					
					default: begin
						o_pc_sel   = 1'b0;
						o_insn_vld = 1'b0;
					end
				endcase
			end
			
			7'b0100011: begin   // S_TYPE
				o_insn_vld = 1'b1;
				o_pc_sel   = 1'b0;
				o_rd_wren  = 1'b0;
				o_br_un    = 1'b0;
				o_opa_sel  = 1'b0;
				o_opb_sel  = 1'b1;
				o_alu_op   = 4'b0000;
				o_mem_wren = 1'b1;
				o_wb_sel   = 2'b11;
			end
			
			7'b1100111: begin   // I_TYPE (JALR)
				o_insn_vld = 1'b1;
				o_pc_sel   = 1'b1;
				o_rd_wren  = 1'b1;
				o_br_un    = 1'b0;
				o_opa_sel  = 1'b0;
				o_opb_sel  = 1'b1;
				o_alu_op   = 4'b0000;
				o_mem_wren = 1'b0;
				o_wb_sel   = 2'b00;
			end
			
			7'b1101111: begin   // J_TYPE (JAL)
				o_insn_vld = 1'b1;
				o_pc_sel   = 1'b1;
				o_rd_wren  = 1'b1;
				o_br_un    = 1'b0;
				o_opa_sel  = 1'b1;
				o_opb_sel  = 1'b1;
				o_alu_op   = 4'b0000;
				o_mem_wren = 1'b0;
				o_wb_sel   = 2'b00;
			end
			
			7'b0000011: begin   // I_TYPE (LOAD)
				o_insn_vld = 1'b1;
				o_pc_sel   = 1'b0;
				o_rd_wren  = 1'b1;
				o_br_un    = 1'b0;
				o_opa_sel  = 1'b0;
				o_opb_sel  = 1'b1;
				o_alu_op   = 4'b0000;
				o_mem_wren = 1'b0;
				o_wb_sel   = 2'b10;
			end
			
			7'b0010011: begin   // I_TYPE (ARITHMETIC)
				o_insn_vld = 1'b1;
				o_pc_sel   = 1'b0;
				o_rd_wren  = 1'b1;
				o_br_un    = 1'b0;
				o_opa_sel  = 1'b0;
				o_opb_sel  = 1'b1;
				o_alu_op   = 4'b0000;
				o_mem_wren = 1'b0;
				o_wb_sel   = 2'b01;
				
				case (i_instr[14:12]) // funct3
					3'b000: o_alu_op = 4'b0000;	// ADDI
					3'b001: o_alu_op = 4'b0111;	// SLLI
					3'b010: o_alu_op = 4'b0010;	// SLTI
					3'b011: o_alu_op = 4'b0011;	// SLTIU
					3'b100: o_alu_op = 4'b0100;	// XORI
					3'b101: o_alu_op = (i_instr[30]) ? 4'b1001 : 4'b1000; // SRAI / SRLI
					3'b110: o_alu_op = 4'b0101;	// ORI
					3'b111: o_alu_op = 4'b0110;	// ANDI
				endcase
			end
			
			7'b0110111: begin   // U_TYPE (LUI)
				o_insn_vld = 1'b1;
				o_pc_sel   = 1'b0;
				o_rd_wren  = 1'b1;
				o_br_un    = 1'b0;
				o_opa_sel  = 1'b0;
				o_opb_sel  = 1'b1;
				o_mem_wren = 1'b0;
				o_wb_sel   = 2'b11;
				o_alu_op   = 4'b0000;
			end
			
			7'b0010111: begin   // U_TYPE (AUIPC)
				o_insn_vld = 1'b1;
				o_pc_sel   = 1'b0;
				o_rd_wren  = 1'b1;
				o_br_un    = 1'b0;
				o_opa_sel  = 1'b1;
				o_opb_sel  = 1'b1;
				o_mem_wren = 1'b0;
				o_wb_sel   = 2'b01;
				o_alu_op   = 4'b0000;
			end
			
			default: begin // error
				o_insn_vld = 1'b0;
				o_pc_sel   = 1'b0;
				o_rd_wren  = 1'b0;
				o_br_un    = 1'b0;
				o_opa_sel  = 1'b0;
				o_opb_sel  = 1'b0;
				o_alu_op   = 4'b1111;
				o_mem_wren = 1'b0;
				o_wb_sel   = 2'b11;
			end
		
		endcase
	end

endmodule
