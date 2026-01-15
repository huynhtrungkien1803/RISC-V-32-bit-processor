# ===============================================
# SW-ALU (RV32I)
#  SW[7:0]   = A
#  SW[15:8]  = B
#  SW[17:16] = op (00=ADD, 01=SUB, 10=AND, 11=OR)
# Hiển thị:
#  - HEX[3:0]  = res16 = (carry/borrow)<<8 | (res8)
#  - HEX[7:6]  = A (hai chữ số hex)
#  - HEX[5:4]  = B (hai chữ số hex)
#  - LEDG[7:0] = res8
#  - LEDR[0]   = carry (ADD) / borrow (SUB) / 0 (AND/OR)
#
# MMIO:
#   0x10000000 -> LEDR (SW)
#   0x10001000 -> LEDG (SW)
#   0x10002000 -> HEX0..3 (lsu_trans_7seg: nib0..3 -> HEX0..3)
#   0x10003000 -> HEX4..7 (lsu_trans_7seg: nib0..3 -> HEX4..7)
#   0x10010000 -> SW
# ===============================================

    .text
    .globl _start
_start:
    # base địa chỉ các ngoại vi
    lui     t0, 0x10000        # t0 = &LEDR  = 0x10000000
    lui     t1, 0x10001        # t1 = &LEDG  = 0x10001000
    lui     t2, 0x10002        # t2 = &HEX03 = 0x10002000
    lui     t3, 0x10003        # t3 = &HEX47 = 0x10003000
    lui     t4, 0x10010        # t4 = &SW    = 0x10010000

loop:
    # đọc switch, tách A,B,op
    lw      t5, 0(t4)          # t5 = SW
    andi    a0, t5, 0xFF       # a0 = A
    srli    t5, t5, 8
    andi    a1, t5, 0xFF       # a1 = B
    srli    t5, t5, 8
    andi    a2, t5, 0x3        # a2 = op

    # nhánh theo op
    beq     a2, x0, do_add     # 00 -> ADD
    addi    a3, x0, 1
    beq     a2, a3, do_sub     # 01 -> SUB
    addi    a3, x0, 2
    beq     a2, a3, do_and     # 10 -> AND
    # 11 -> OR
    or      t6, a0, a1
    andi    a3, t6, 0xFF       # a3 = res8
    addi    a4, x0, 0          # a4 = carry/borrow = 0
    jal     x0, write_out

do_and:
    and     t6, a0, a1
    andi    a3, t6, 0xFF
    addi    a4, x0, 0          # carry/borrow = 0
    jal     x0, write_out

do_add:
    add     t6, a0, a1         # t6 = A + B (tối đa 0x1FE)
    andi    a3, t6, 0xFF       # a3 = res8
    srli    a4, t6, 8
    andi    a4, a4, 1          # a4 = carry (bit0)
    jal     x0, write_out

do_sub:
    sub     t6, a0, a1         # t6 = A - B (wrap 32-bit)
    andi    a3, t6, 0xFF       # a3 = res8
    addi    a4, x0, 0          # mặc định borrow=0
    bltu    a0, a1, set_b      # nếu A < B -> borrow=1
    jal     x0, after_b
set_b:
    addi    a4, x0, 1
after_b:
    jal     x0, write_out

write_out:
    # HEX[3:0] = (carry/borrow)<<8 | res8
    slli    t6, a4, 8
    or      a5, t6, a3
    sw      a5, 0(t2)          # ghi vào 0x10002000 (HEX0..3)

    # HEX[7:4] = [A_hi, A_lo, B_hi, B_lo] (mỗi nibble là 1 ký tự)
    addi    a6, x0, 0          # acc = 0
    srli    a7, a0, 4          # A_hi
    andi    a7, a7, 0xF
    slli    a7, a7, 12
    or      a6, a6, a7

    andi    a7, a0, 0xF        # A_lo
    slli    a7, a7, 8
    or      a6, a6, a7

    srli    a7, a1, 4          # B_hi
    andi    a7, a7, 0xF
    slli    a7, a7, 4
    or      a6, a6, a7

    andi    a7, a1, 0xF        # B_lo
    or      a6, a6, a7

    sw      a6, 0(t3)          # ghi vào 0x10003000 (HEX4..7)

    # LEDG = res8, LEDR[0] = carry/borrow
    sw      a3, 0(t1)          # LEDG[7:0]
    sw      a4, 0(t0)          # LEDR[0]

    jal     x0, loop
