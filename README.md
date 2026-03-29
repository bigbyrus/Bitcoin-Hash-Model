# Bitcoin Hash Pipeline — FSM Design in SystemVerilog

## Overview
This project implements a **Bitcoin-style hashing pipeline** in SystemVerilog built around the, slightly modified, `simplified_sha256.sv` module. 
[SHA-256 hardware module](https://github.com/bigbyrus/SHA-256) was modified so that it left all memory accesses to be done by the top module, `bitcoin_hash.sv`. 
This way the `simplified_sha256.sv` module only concerns itself with processing 512-bit blocks, and storing the output hashes in an unpacked array of 8, 32-bit, elements.
The design is structured to mimic Bitcoin's mining process where multiple nonce values are tried per iteration.

The top-level module (`bitcoin_hash.sv`) instantiates `simplified_sha256` multiple times to create a three-phase hashing process:

---

### Statistics on First Iteration

Logic utilization : 95 %
    Combinational ALUTs : 18,956 / 36,100 ( 53 % )
    Memory ALUTs : 0 / 18,050 ( 0 % )
    Dedicated logic registers : 27,762 / 36,100 ( 77 % )
Total registers : 27762

+--------------------------------------------------+
; Slow 900mV 100C Model Fmax Summary               ;
+------------+-----------------+------------+------+
; Fmax       ; Restricted Fmax ; Clock Name ; Note ;
+------------+-----------------+------------+------+
; 116.59 MHz ; 116.59 MHz      ; clk        ;      ;
+------------+-----------------+------------+------+
