# Bitcoin Hash Pipeline — FSM Design in SystemVerilog

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
    Cycles: 348
</p>
<p>
    Logic utilization : 95 %<br>
        Combinational ALUTs : 18,956 / 36,100 ( 53 % )<br>
        Memory ALUTs : 0 / 18,050 ( 0 % )<br>
        Dedicated logic registers : 27,762 / 36,100 ( 77 % )<br>
    Total registers : 27762<br>
</p>

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
    Cycles: 342
</p>
<p>
    Logic utilization : 95 %<br>
        Combinational ALUTs : 18,923 / 36,100 ( 52 % )<br>
        Memory ALUTs : 0 / 18,050 ( 0 % )<br>
        Dedicated logic registers : 27,744 / 36,100 ( 77 % )<br>
    Total registers : 27744<br>
</p>

---

### Attempted to Pipeline Design, Third Iteration
    In this iteration, I separated the word expansion step from the SHA-256 operation step, hoping to reduce the 
critical path of this system so that the design could run at a higher clock frequency.
<p>
    +--------------------------------------------------+<br>
    ; Slow 900mV 100C Model Fmax Summary               ;<br>
    +------------+-----------------+------------+------+<br>
    ; Fmax       ; Restricted Fmax ; Clock Name ; Note ;<br>
    +------------+-----------------+------------+------+<br>
    ; 129.79 MHz ; 129.79 MHz      ; clk        ;      ;<br>
    +------------+-----------------+------------+------+<br>
</p>
<p>
    Cycles: 534
</p>
<p>
    Logic utilization : 95 %<br>
        Combinational ALUTs : 18,931 / 36,100 ( 52 % )<br>
        Memory ALUTs : 0 / 18,050 ( 0 % )<br>
        Dedicated logic registers : 28,290 / 36,100 ( 77 % )<br>
    Total registers : 28290<br>
</p>

    Attempting to pipeline the design in this way caused the cycles to increase significantly while not offering much
improvement to the clock frequency. This lets me know that **pipelining the SHA-256 operation itself** will give me a more
efficient design.