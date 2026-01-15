// by: Nguyen Dinh Trong Khoi - Huynh Trung Kien
module memory (
  input  logic              i_clk,
  input  logic              i_reset,     // active-low
  input  logic [10:0] i_addr,      // byte address
  input  logic [31:0]       i_wdata,
  input  logic [3:0]        i_bmask,     // per-byte
  input  logic              i_wren,
  output logic [31:0]       o_rdata
);
  // 2 KiB, byte-addressable
  logic [7:0] mem_cell [0:254];	// cắt để đổ DE2
  // init (SIM/synth-friendly)
  //initial mem_cell = '{default: 8'h0};
  // ---------------------------
  // Tính địa chỉ byte a0..a3
  // ---------------------------
  logic [7:0] a0; 
  logic [7:0] a1;
  logic [7:0] a2;
  logic [7:0] a3;
  
  assign a0 = i_addr;
  // zero-extend i_addr lên 32-bit để đưa vào addsub32
  logic [31:0] addr_zext;
  assign addr_zext = { {(21){1'b0}}, i_addr };
  // kết quả 32-bit trung gian từ addsub32 (là lvalue của o_s)
  logic [31:0] a1_w;
  logic [31:0] a2_w;
  logic [31:0] a3_w;
  addsub32 addsub_a1 (
    .i_a  (addr_zext),
    .i_b  (32'd1),
    .Cin  (1'b0),
    .Cout (),
    .o_s  (a1_w)
  );
  addsub32 addsub_a2 (
    .i_a  (addr_zext),
    .i_b  (32'd2),
    .Cin  (1'b0),
    .Cout (),
    .o_s  (a2_w)
  );
  addsub32 addsub_a3 (
    .i_a  (addr_zext),
    .i_b  (32'd3),
    .Cin  (1'b0),
    .Cout (),
    .o_s  (a3_w)
  );
  // cắt xuống 7-bit để index bộ nhớ
  assign a1 = a1_w[7:0];
  assign a2 = a2_w[7:0];
  assign a3 = a3_w[7:0];

  // ---------------------------
  // Ghi đồng bộ (byte-enable)
  // ---------------------------
  always_ff @(posedge i_clk or negedge i_reset) begin
    if (~i_reset) begin
      integer i;
      for (i = 0; i < 255; i++) begin
        mem_cell[i] <= 8'd0;
      end
    end else if (i_wren) begin
      if (i_bmask[0]) mem_cell[a0] <= i_wdata[7:0];
      if (i_bmask[1]) mem_cell[a1] <= i_wdata[15:8];
      if (i_bmask[2]) mem_cell[a2] <= i_wdata[23:16];
      if (i_bmask[3]) mem_cell[a3] <= i_wdata[31:24];
    end
  end
  // ---------------------------
  // Đọc bất đồng bộ (little-endian)
  // ---------------------------
  always_comb begin
    o_rdata = { mem_cell[a3], mem_cell[a2], mem_cell[a1], mem_cell[a0] };
  end
endmodule
