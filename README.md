# Bitcoin Hash Pipeline — FSM Design in SystemVerilog

## Overview
This project implements a **Bitcoin-style hashing pipeline** in SystemVerilog built around the, slightly modified, `simplified_sha256.sv` module. 
[SHA-256 hardware module](https://github.com/bigbyrus/SHA-256) was modified so that it left all memory accesses to be done by the top module, `bitcoin_hash.sv`. 
This way the `simplified_sha256.sv` module only concerns itself with processing 512-bit blocks, and storing the output hashes in an unpacked array of 8, 32-bit, elements.
The design is structured to mimic Bitcoin's mining process where multiple nonce values are tried per iteration.

The top-level module (`bitcoin_hash.sv`) instantiates `simplified_sha256` multiple times to create a three-phase hashing process:

---

### First Iteration
<p>
    Logic utilization : 95 %<br>
        Combinational ALUTs : 18,956 / 36,100 ( 53 % )<br>
        Memory ALUTs : 0 / 18,050 ( 0 % )<br>
        Dedicated logic registers : 27,762 / 36,100 ( 77 % )<br>
    Total registers : 27762<br>
</p>

<p>
    +--------------------------------------------------+<br>
    ; Slow 900mV 100C Model Fmax Summary               ;<br>
    +------------+-----------------+------------+------+<br>
    ; Fmax       ; Restricted Fmax ; Clock Name ; Note ;<br>
    +------------+-----------------+------------+------+<br>
    ; 116.59 MHz ; 116.59 MHz      ; clk        ;      ;<br>
    +------------+-----------------+------------+------+<br>
</p>

<p>
    Cycles: 348
</p>

---

### Reduced SHA-256 Logic, Second Iteration

<p>
    Logic utilization : 95 %
        Combinational ALUTs : 18,923 / 36,100 ( 52 % )
        Memory ALUTs : 0 / 18,050 ( 0 % )
        Dedicated logic registers : 27,744 / 36,100 ( 77 % )
    Total registers : 27744
</p>
<p>
    +--------------------------------------------------+<br>
    ; Slow 900mV 100C Model Fmax Summary               ;<br>
    +------------+-----------------+------------+------+<br>
    ; Fmax       ; Restricted Fmax ; Clock Name ; Note ;<br>
    +------------+-----------------+------------+------+<br>
    ; 122.26 MHz ; 122.26 MHz      ; clk        ;      ;<br>
    +------------+-----------------+------------+------+<br>
</p>
<p>
    Cycles: 342
</p>
