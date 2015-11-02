/*
 * alu.sv
 */

import riscv::aluop_t;
import riscv::data_t;

/**
 * Module: alu
 *
 * An ALU.
 */
module alu (
    input  aluop_t opcode,
    input  data_t  op1,
    input  data_t  op2,
    output data_t  out
);
    logic [6:0] shamt = op2[5:0];

    always_comb
        unique case (opcode)
            aluop::ADD:  out = op1 + op2;
            aluop::SUB:  out = op1 - op2;
            aluop::SLL:  out = op1 << shamt;
            aluop::SLT:  out = signed'(op1) < signed'(op2);
            aluop::SLTU: out = op1 < op2;
            aluop::XOR:  out = op1 ^ op2;
            aluop::SRL:  out = op1 >> shamt;
            aluop::SRA:  out = signed'(op1) >>> shamt;
            aluop::OR:   out = op1 | op2;
            aluop::AND:  out = op1 & op2;
        endcase
endmodule
