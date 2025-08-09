# Bitcoin Hash Pipeline — FSM Design in SystemVerilog

## Overview
This project implements a **Bitcoin-style hashing pipeline** in SystemVerilog built around the, slightly modified, `simplified_sha256.sv` module. 
[SHA-256 hardware module](https://github.com/bigbyrus/SHA-256) was modified so that it left all memory accesses to be done by the top module, `bitcoin_hash.sv`. 
This way the `simplified_sha256.sv` module only concerns itself with processing 512-bit blocks, and storing the output hashes in an unpacked array of 8, 32-bit, elements.
The design is structured to mimic Bitcoin's mining process where multiple nonce values are tried per iteration.

The top-level module (`bitcoin_hash.sv`) instantiates `simplified_sha256` multiple times to create a three-phase hashing process:

---

## Pipeline Structure

### **Phase 1 — Initial Block Hash**
1. A single instance of `simplified_sha256` computes the **initial 256-bit hash** from the **first 512-bit message block**.
2. The result of this hash becomes the **initial hash constants** for the next phase.

---

### **Phase 2 — 16 Parallel Nonce Trials**
1. The **second 512-bit message block** is duplicated **16 times**.
2. The **3rd word** in each duplicate is replaced with a **nonce** value.
3. Each modified block is hashed in parallel using **16 generated instances** of `simplified_sha256`.
4. Each instance outputs its own **256-bit hash**.

---

### **Phase 3 — Second Round of SHA-256**
1. The 16 hash outputs from Phase 2 are **padded** to form new **512-bit message blocks**.
2. These padded blocks are each processed again using another set of `simplified_sha256` instances, this time incorporating the original hash constants.
3. This produces the **final SHA-256 hashes** for each nonce.

---

### **WRITE to memory**
1. The first word of each **final 256-bit hash** is written to memory.
2. The testbench verifies that the outputs match expected results.

