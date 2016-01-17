/**
 * Copyright (c) 2015, C. Brett Witherspoon
 */
package core;

    /*
     * Data
     */

    // Opcodes
    typedef enum logic [6:0] {
        LOAD      = 'b0000011,
        LOAD_FP   = 'b0000111,
        CUSTOM_0  = 'b0001011,
        MISC_MEM  = 'b0001111,
        OP_IMM    = 'b0010011,
        AUIPC     = 'b0010111,
        OP_IMM_32 = 'b0011011,
        STORE     = 'b0100011,
        STORE_FP  = 'b0100111,
        CUSTOM_1  = 'b0101011,
        AMO       = 'b0101111,
        OP        = 'b0110011,
        LUI       = 'b0110111,
        OP_32     = 'b0111011,
        MADD      = 'b1000011,
        MSUB      = 'b1000111,
        NMSUB     = 'b1001011,
        NMADD     = 'b1001111,
        OP_FP     = 'b1010011,
        CUSTOM_2  = 'b1011011,
        BRANCH    = 'b1100011,
        JALR      = 'b1100111,
        JAL       = 'b1101111,
        SYSTEM    = 'b1110011,
        CUSTOM_3  = 'b1111011
    } opcode_t;

    // Word type
    typedef logic [31:0] word_t;

    // Register address type
    typedef logic [4:0] addr_t;

    // Byte strobe type
    typedef logic [$bits(word_t)/8-1:0] strb_t;

    // Immediate type
    typedef logic signed [31:0] imm_t;

    // Instruction funct7 type
    typedef logic [6:0] funct7_t;

    // Instruction funct3 type
    typedef enum logic [2:0] {
        BEQ_LB_SB_ADD_SUB = 'b000,
        BNE_LH_SH_SLL     = 'b001,
        LW_SW_SLT         = 'b010,
        SLTU_SLTIU        = 'b011,
        BLT_LBU_XOR       = 'b100,
        BGE_LHU_SRL_SRA   = 'b101,
        BLTU_OR           = 'b110,
        BGEU_AND          = 'b111
    } funct3_t;

    // Instruction address space base
    localparam word_t CODE_BASE = 32'h00000000;

    // Instruction address space size
    localparam word_t CODE_SIZE = 32'h00000200;

    // Kernal address space
    localparam word_t KERN_BASE = 32'h00000200;

    // Kernal address space
    localparam word_t KERN_SIZE = 32'h00000200;

    // Data address space base
    localparam word_t DATA_BASE = 32'h00000000;

    // Data address space size
    localparam word_t DATA_SIZE = 32'h00000200;

    // BSS address space base
    localparam word_t BSS_BASE = 32'h00000200;

    // BAA address space size
    localparam word_t BSS_SIZE = 32'h00000100;

    // Stack base address
    localparam word_t STACK_BASE = 32'h00000FFF;

    // Stack size
    localparam word_t STACK_SIZE = 32'h00000100;

    // Memory mapped peripheral address space
    localparam word_t MMIO_BASE = 32'h40000000;


    // Instruction type
    typedef union packed {
        struct packed {
            funct7_t funct7;
            addr_t   rs2;
            addr_t   rs1;
            funct3_t funct3;
            addr_t   rd;
            opcode_t opcode;
        } r;
       struct packed {
            logic [11:0] imm_11_0;
            addr_t       rs1;
            funct3_t     funct3;
            addr_t       rd;
            opcode_t     opcode;
        } i;
        struct packed {
            logic [6:0] imm_11_5;
            addr_t      rs2;
            addr_t      rs1;
            funct3_t    funct3;
            logic [4:0] imm_4_0;
            opcode_t    opcode;
        } s;
        struct packed {
            logic       imm_12;
            logic [5:0] imm_10_5;
            addr_t      rs2;
            addr_t      rs1;
            funct3_t    funct3;
            logic [3:0] imm_4_1;
            logic       imm_11;
            opcode_t    opcode;
        } sb;
        struct packed {
            logic [19:0] imm_31_12;
            addr_t       rd;
            opcode_t     opcode;
        } u;
        struct packed {
            logic       imm_20;
            logic [9:0] imm_10_1;
            logic       imm_11;
            logic [7:0] imm_19_12;
            addr_t      rd;
            opcode_t    opcode;
        } uj;
    } inst_t;

    localparam word_t NOP = 32'h00000013;

    /*
     * Control
     */

    // CPU function type
    typedef enum logic [3:0] {
        NULL,
        REGISTER,
        JUMP_OR_BRANCH,
        LOAD_WORD,
        LOAD_HALF,
        LOAD_BYTE,
        LOAD_HALF_UNSIGNED,
        LOAD_BYTE_UNSIGNED,
        STORE_WORD,
        STORE_HALF,
        STORE_BYTE
    } fun_t;

    // ALU operation type
    typedef enum logic [3:0] {
        ADD,
        SLL,
        SLT,
        SLTU,
        XOR,
        SRL,
        OR,
        AND,
        SUB,
        SRA,
        OP2,
        ANY = 4'bxxxx
    } op_t;

    // Jump / Branch operation type
    typedef enum logic [2:0] {
        NONE,
        JAL_OR_JALR,
        BEQ,
        BNE,
        BLT,
        BLTU,
        BGE,
        BGEU
    } jmp_t;

    // Program counter select
    typedef enum logic [1:0] {
        NEXT,
        ADDR,
        TRAP
    } pc_t;

    // First operand select
    typedef enum logic {
        RS1,
        PC,
        XX = 1'bx
    } op1_t;

    // Second operand select
    typedef enum logic [2:0] {
        RS2,
        I_IMM,
        S_IMM,
        B_IMM,
        U_IMM,
        J_IMM,
        XXX = 3'bxxx
    } op2_t;

    // Source register select (forwarding)
    typedef enum logic [1:0] {
        REG,
        ALU,
        MEM,
        RAM
    } rs_t;

    // Data path control signals
    typedef struct packed {
        fun_t fun;
        op_t  op;
        jmp_t jmp;
        op1_t op1;
        op2_t op2;
    } ctrl_t;

    /*
     * Helper functions (synthesizable)
     */

    function logic is_load (input fun_t fun);
        return fun == LOAD_WORD || fun == LOAD_HALF || fun == LOAD_BYTE ||
               fun == LOAD_HALF_UNSIGNED || fun == LOAD_BYTE_UNSIGNED;
    endfunction

    function logic is_store (input fun_t fun);
        return fun == STORE_WORD || fun == STORE_HALF || fun == STORE_BYTE;
    endfunction


endpackage
