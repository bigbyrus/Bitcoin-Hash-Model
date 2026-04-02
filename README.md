## Overview
This project implements a Bitcoin Hash model in SystemVerilog built around the, slightly modified, `simplified_sha256.sv` module. 
[My SHA-256 hardware module](https://github.com/bigbyrus/SHA-256) was modified so that it left all memory accesses to be done by the top module, `bitcoin_hash.sv`. 
This way the `simplified_sha256.sv` module only concerns itself with processing 512-bit blocks, and storing the output hashes in an unpacked array of 8, 32-bit, elements.
The design is structured to mimic Bitcoin's mining process where multiple nonce values are tried per iteration.

---

### First Iteration

    +--------------------------------------------------+
    ; Slow 900mV 100C Model Fmax Summary               ;
    +------------+-----------------+------------+------+
    ; Fmax       ; Restricted Fmax ; Clock Name ; Note ;
    +------------+-----------------+------------+------+
    ; 116.59 MHz ; 116.59 MHz      ; clk        ;      ;
    +------------+-----------------+------------+------+


    Logic utilization : 95 %
        Combinational ALUTs : 18,956 / 36,100 ( 53 % )
        Memory ALUTs : 0 / 18,050 ( 0 % )
        Dedicated logic registers : 27,762 / 36,100 ( 77 % )
    Total registers : 27762

    Cycles: 348
    Delay: 2.98 (microseconds)
    Delay * Area: 139.44 (ms*Area)
    
---

### Reduced SHA-256 Logic, Second Iteration


    +--------------------------------------------------+
    ; Slow 900mV 100C Model Fmax Summary               ;
    +------------+-----------------+------------+------+
    ; Fmax       ; Restricted Fmax ; Clock Name ; Note ;
    +------------+-----------------+------------+------+
    ; 122.26 MHz ; 122.26 MHz      ; clk        ;      ;
    +------------+-----------------+------------+------+

    Logic utilization : 95 %
        Combinational ALUTs : 18,923 / 36,100 ( 52 % )
        Memory ALUTs : 0 / 18,050 ( 0 % )
        Dedicated logic registers : 27,744 / 36,100 ( 77 % )<
    Total registers : 27744

    Cycles: 342
    Delay: 2.79 (microseconds)
    Delay * Area: 130.54 (ms*Area)

---

### Separated Word Expansion, Third Iteration
In this iteration, I separated the word expansion step from the always_ff block so that cycles are not wasted
computing this word expansion that can be executed all at once.


    Logic utilization : 368 %
        Combinational ALUTs : 114,627 / 36,100
        Memory ALUTs : 0 / 18,050
        Dedicated logic registers : 19,038 / 36,100 
    Total registers : 28290


This attempt proved to be useless because the design does not fit onto the FPGA, although I did see the number of cycles
decrease substantially. Since the area constraint is critical in this design, I will step away from this approach and 
try to optimize the design in a more efficient way.

---

### Fourth Iteration

    +--------------------------------------------------+
    ; Slow 900mV 100C Model Fmax Summary               ;
    +------------+-----------------+------------+------+
    ; Fmax       ; Restricted Fmax ; Clock Name ; Note ;
    +------------+-----------------+------------+------+
    ; 135.03 MHz ; 135.03 MHz      ; clk        ;      ;
    +------------+-----------------+------------+------+


    Cycles: 294
    Delay: 2.18 (microseconds)
    Delay * Area: 88.09 (ms*Area)


    Logic utilization : 95 %
        Combinational ALUTs : 12,716 / 36,100 ( 34 % )
        Memory ALUTs : 0 / 18,050 ( 0 % )
        Dedicated logic registers : 27,744 / 36,100 ( 77 % )
    Total registers : 27744

This iteration showed the most improvement (so far) to FPGA resources and cycles. To do this I took advantage of
the asynchronous read to save cycles, and I went back to limiting the w[] array to only 16 elements.
In the previous iterations I attempted to complete the word expansion all at once, but this method would
not fit on the FPGA I am using.

---

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
    Delay * Area: 119.48 (ms*Area)


    Logic utilization : 98 %
        Combinational ALUTs : 12,369 / 36,100 ( 34 % )
        Memory ALUTs : 0 / 18,050 ( 0 % )
        Dedicated logic registers : 33,763 / 36,100 ( 94 % )
    Total registers : 33763

Since I am optimizing for Area and Speed, this pipelined version falls short of the efficiency shown in the last iteration.
Splitting up the critical path increased Fmax substantially, but the increase in cycles and registers shows that a larger Fmax
does not result in a more efficient design.
