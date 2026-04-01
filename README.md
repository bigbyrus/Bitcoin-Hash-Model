## Overview
This project implements a Bitcoin Hash model in SystemVerilog built around the, slightly modified, `simplified_sha256.sv` module. 
[My SHA-256 hardware module](https://github.com/bigbyrus/SHA-256) was modified so that it left all memory accesses to be done by the top module, `bitcoin_hash.sv`. 
This way the `simplified_sha256.sv` module only concerns itself with processing 512-bit blocks, and storing the output hashes in an unpacked array of 8, 32-bit, elements.
The design is structured to mimic Bitcoin's mining process where multiple nonce values are tried per iteration.

---

### First Iteration
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
    Logic utilization : 95 %<br>
        Combinational ALUTs : 18,956 / 36,100 ( 53 % )<br>
        Memory ALUTs : 0 / 18,050 ( 0 % )<br>
        Dedicated logic registers : 27,762 / 36,100 ( 77 % )<br>
    Total registers : 27762<br>
</p>

    Cycles: 348
    Delay: 2.98 (microseconds)
    Delay*Area: 139.44 (ms*Area)
    
---

### Reduced SHA-256 Logic, Second Iteration

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
    Logic utilization : 95 %<br>
        Combinational ALUTs : 18,923 / 36,100 ( 52 % )<br>
        Memory ALUTs : 0 / 18,050 ( 0 % )<br>
        Dedicated logic registers : 27,744 / 36,100 ( 77 % )<br>
    Total registers : 27744<br>
</p>

    Cycles: 342
    Delay: 2.79 (microseconds)
    Delay*Area: 130.54 (ms*Area)

---

### Separated Word Expansion, Third Iteration
In this iteration, I separated the word expansion step from the always_ff block so that cycles are not wasted
computing this word expansion that can be executed all at once.

<p>
    Logic utilization : 368 %<br>
        Combinational ALUTs : 114,627 / 36,100 ( 52 % )<br>
        Memory ALUTs : 0 / 18,050 ( 0 % )<br>
        Dedicated logic registers : 19,038 / 36,100 ( 77 % )<br>
    Total registers : 28290<br>
</p>

This attempt proved to be useless because the design does not fit onto the FPGA, although I did see the number of cycles
decrease substantially. Since the area constraint is critical in this design, I will step away from this approach and 
try to optimize the design in a more efficient way.

---

### Fourth Iteration
<p>
    +--------------------------------------------------+<br>
    ; Slow 900mV 100C Model Fmax Summary               ;<br>
    +------------+-----------------+------------+------+<br>
    ; Fmax       ; Restricted Fmax ; Clock Name ; Note ;<br>
    +------------+-----------------+------------+------+<br>
    ; 135.03 MHz ; 135.03 MHz      ; clk        ;      ;<br>
    +------------+-----------------+------------+------+<br>
</p>
<p>
    Cycles: 534

    Delay: 2.17 (microseconds)
    Delay*Area: 88.09 (ms*Area)
</p>
<p>
    Logic utilization : 95 %<br>
        Combinational ALUTs : 12,716 / 36,100 ( 52 % )<br>
        Memory ALUTs : 0 / 18,050 ( 0 % )<br>
        Dedicated logic registers : 27,744 / 36,100 ( 77 % )<br>
    Total registers : 27744<br>
</p>

This iteration showed the mos improvement to FPGA resources and cycles. To do this I took advantage of
the asynchronous read to save cycles, and I went back to limiting the w[] array to only 16 elements.
In the previous iterations I attempted to complete the word expansion all at once, but this method would
not fit on the FPGA I am using.