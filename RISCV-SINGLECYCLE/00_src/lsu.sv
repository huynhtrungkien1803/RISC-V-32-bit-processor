// ----------------------------------------------------------- //
//	lsu.sv
//	The Load and Store Unit (LSU) for RV32I based processor
// ----------------------------------------------------------- //
//	By: Huynh Trung Kien
// ----------------------------------------------------------- //

module lsu(
	input  logic         i_clk,
	input  logic         i_reset,
	input  logic [31:0]  i_lsu_addr,
	input  logic [31:0]  i_st_data,
	input  logic         i_lsu_wren,
	output logic [31:0]  o_ld_data,
	output logic [31:0]  o_io_ledr,
	output logic [31:0]  o_io_ledg,
	
	output logic [ 6:0]  o_io_hex0 ,
   output logic [ 6:0]  o_io_hex1 ,
   output logic [ 6:0]  o_io_hex2 ,
   output logic [ 6:0]  o_io_hex3 ,
   output logic [ 6:0]  o_io_hex4 ,
   output logic [ 6:0]  o_io_hex5 ,
   output logic [ 6:0]  o_io_hex6 ,
   output logic [ 6:0]  o_io_hex7 ,
	
	output logic [31:0]  o_io_lcd,
	input  logic [31:0]  i_io_sw,
	
	input	logic  [2:0]	i_funct3
);
	logic [31:0] ld_data;	// internal load data
	logic [31:0] dmem_rdata;	// data read from datamem
	//logic [31:0] dmem_wdata;	// data to be stored in to dmem
	logic [3:0] bmask;	// byte mask for storing
	logic	dmem_wren;	// enable writing to dmem
	logic [31:0] io_hex03;	// giá trị bin của 7seg 0-3
	logic [31:0] io_hex47;	// giá trị bin của 7seg 4-7

memory datamem	(
	.i_clk		(i_clk),
	.i_reset		(i_reset),
	.i_addr		(i_lsu_addr[10:0]),  
	.i_wdata		(i_st_data),
	.i_bmask		(bmask),
	.i_wren		(dmem_wren),
	.o_rdata		(dmem_rdata)
);

lsu_trans_7seg trans_7seg_03 (	// hiện led 7 đoạn 0-3
	.i_bin (io_hex03),
	.o_7seg0(o_io_hex0),
	.o_7seg1(o_io_hex1),
	.o_7seg2(o_io_hex2),
	.o_7seg3(o_io_hex3),
);

lsu_trans_7seg trans_7seg_47 (	// hiện led 7 đoạn 4-7
	.i_bin (io_hex47),
	.o_7seg0(o_io_hex4),
	.o_7seg1(o_io_hex5),
	.o_7seg2(o_io_hex6),
	.o_7seg3(o_io_hex7),
);


	always_ff @(posedge i_clk or negedge i_reset) begin
	
		if (~i_reset) begin
			// Gán tất cả thanh ghi = 0
			o_io_ledr  <= 32'b0;
			o_io_ledg  <= 32'b0;
			o_io_lcd   <= 32'b0;
			
			io_hex03 <= 32'b0;
			io_hex47 <= 32'b0;
			
		/*	o_io_hex0  <= 7'b0;
			o_io_hex1  <= 7'b0;
			o_io_hex2  <= 7'b0;
			o_io_hex3  <= 7'b0;
			o_io_hex4  <= 7'b0;
			o_io_hex5  <= 7'b0;
			o_io_hex6  <= 7'b0;
			o_io_hex7  <= 7'b0; */
		end 
		else
		if (i_lsu_wren) begin
		
				//dmem_wren <= 1'b0;	// set default value
				
				case (i_lsu_addr[31:12])
					20'h1000_4: begin //o_io_lcd <= i_st_data;	        //thêm byte mask cho all
						if (bmask[3]) o_io_lcd[31:24] <= i_st_data[31:24];
						if (bmask[2]) o_io_lcd[23:16] <= i_st_data[23:16];
						if (bmask[1]) o_io_lcd[15:8] <= i_st_data[15:8];
						if (bmask[0]) o_io_lcd[7:0] <= i_st_data[7:0];
					end
					
					20'h1000_3: begin
						if (bmask[3]) io_hex47[31:24] <= i_st_data[31:24];
						if (bmask[2]) io_hex47[23:16] <= i_st_data[23:16];
						if (bmask[1]) io_hex47[15:8] <= i_st_data[15:8];
						if (bmask[0]) io_hex47[7:0] <= i_st_data[7:0];
					end
					20'h1000_2: begin
						if (bmask[3]) io_hex03[31:24] <= i_st_data[31:24];
						if (bmask[2]) io_hex03[23:16] <= i_st_data[23:16];
						if (bmask[1]) io_hex03[15:8] <= i_st_data[15:8];
						if (bmask[0]) io_hex03[7:0] <= i_st_data[7:0];
					end
					20'h1000_1: begin //o_io_ledg <= i_st_data;
						if (bmask[3]) o_io_ledg[31:24] <= i_st_data[31:24];
						if (bmask[2]) o_io_ledg[23:16] <= i_st_data[23:16];
						if (bmask[1]) o_io_ledg[15:8] <= i_st_data[15:8];
						if (bmask[0]) o_io_ledg[7:0] <= i_st_data[7:0];
					end
					20'h1000_0: begin //o_io_ledr <= i_st_data;
						if (bmask[3]) o_io_ledr[31:24] <= i_st_data[31:24]; 
						if (bmask[2]) o_io_ledr[23:16] <= i_st_data[23:16];
						if (bmask[1]) o_io_ledr[15:8] <= i_st_data[15:8];
						if (bmask[0]) o_io_ledr[7:0] <= i_st_data[7:0];
					end
					//20'h0000_0: bật cờ dmem_wren ở khối comb để dmem nhận được cùng dmem_wrdata

					default: ; // reserved
				endcase
			end
	
	end
	
	// read (combinational)
	
	always_comb begin		// read full 4 byte from the memory
		
		// default value
		bmask = 4'b0000;
		dmem_wren = 1'b0;
		ld_data = 32'b0;
		o_ld_data = 32'b0;
	
		if (i_lsu_wren) // bật cờ dmem_wren bất đồng bộ 
			if (i_lsu_addr[31:12] == 20'h0000_0) dmem_wren = 1'b1;
				else dmem_wren = 1'b0;
			else dmem_wren = 1'b0;
		
		case (i_lsu_addr[31:12])
			20'h1000_4: ld_data = o_io_lcd;
			20'h1000_3: ld_data = io_hex47;
			20'h1000_2: ld_data = io_hex03;
			20'h1000_1: ld_data = o_io_ledg;
			20'h1000_0: ld_data = o_io_ledr;
			20'h0000_0: ld_data = dmem_rdata;
			default:    ld_data = i_io_sw;
		endcase
		
		case (i_funct3)	// load data generate
			3'b000: o_ld_data = {{24{ld_data[7]}}, ld_data[7:0]};		// LB
			3'b001: o_ld_data = {{16{ld_data[15]}}, ld_data[15:0]}; 	// LH
			3'b010: o_ld_data = ld_data; 										// LW
			3'b100: o_ld_data = {24'b0, ld_data[7:0]}; 					// LBU
			3'b101: o_ld_data = {16'b0, ld_data[15:0]}; 					// LHU
			default: o_ld_data = 32'b0;	// error
		endcase
		
		case (i_funct3)	// bmask generate
			3'b000: bmask = 4'b0001;	// SB
			3'b001: bmask = 4'b0011;	// SH
			3'b010: bmask = 4'b1111;	// SW
			default: bmask = 4'b0000;	//avoid writing unintentionally
		endcase
	end

endmodule
