## Overview
This project implements a synthesizable Bitcoin Hashing RTL model in SystemVerilog built around the, slightly modified, `simplified_sha256.sv` module. 
[My SHA-256 RTL model](https://github.com/bigbyrus/SHA-256) was modified so that it only concerns itself with processing 512-bit blocks, and writing the output hash to the top module, `bitcoin_hash.sv`.
The design is structured to mimic **Bitcoin's mining process where a 640-bit block header is hashed repeatedly, trying different nonce values**. The specific project flow is as follows: 

<p align="center">
  <img src="assets/bitcoinhash.png" width="700">
</p>

---

## Results
The purpose of this project was to optimize the design for area, so that I could hash the same 640-bit block header 16 times in parallel using different nonce values.
    - I also explored mutliple approaches in an attempt to increase throughput by pipelining the SHA-256 hash rounds

### Pipelined Version, Fifth Iteration

    +--------------------------------------------------+
    ; Slow 900mV 100C Model Fmax Summary               ;
    +------------+-----------------+------------+------+
    ; Fmax       ; Restricted Fmax ; Clock Name ; Note ;
    +------------+-----------------+------------+------+
    ; 187.2 MHz  ; 187.2 MHz       ; clk        ;      ;
    +------------+-----------------+------------+------+

    Cycles: 486
    Delay: 2.59 (microseconds)

    Logic utilization : 98 %
        Combinational ALUTs : 12,488 / 36,100 ( 34 % )
        Memory ALUTs : 0 / 18,050 ( 0 % )
        Dedicated logic registers : 33,762 / 36,100 ( 94 % )
    Total registers : 33762
    
    Delay * Area: 119.79 (ms*Area)

Since I am optimizing for Area and Speed, this pipelined version falls short in terms of efficiency. Splitting the SHA-256 hash round into two pipeline stages increased Fmax substantially, but the increase in cycles and registers shows that a larger Fmax does not directly contribute to a more efficient design.

---

### Final Iteration

    +--------------------------------------------------+
    ; Slow 900mV 100C Model Fmax Summary               ;
    +------------+-----------------+------------+------+
    ; Fmax       ; Restricted Fmax ; Clock Name ; Note ;
    +------------+-----------------+------------+------+
    ; 136.86 MHz ; 136.86 MHz      ; clk        ;      ;
    +------------+-----------------+------------+------+

    Cycles: 294
    Delay: 2.14 microseconds

    Logic utilization : 93 %
        Combinational ALUTs : 12,481 / 36,100 ( 35 % )
        Memory ALUTs : 0 / 18,050 ( 0 % )
        Dedicated logic registers : 27,232 / 36,100 ( 75 % )
    Total registers : 27232

    Delay * Area: 84.98 (ms*Area)

The final iteration of this design uses less registers, ALUTs, and cycles to execute the Bitcoin mining process. Each SHA-256 hash round is done in a single cycle (no pipelining).
