**Binary Adder Spec**

**Module Name:** 64-bit Unsigned Binary Adder

* **Architecture:** Combinational Logic (0-cycle latency)
* **Data Type:** Unsigned only
* **Input Ports:**
  * `a [63:0]`: 64-bit unsigned operand A
  * `b [63:0]`: 64-bit unsigned operand B
* **Output Ports:**
  * `sum [63:0]`: lower 64-bit addition result
  * `c_out`: carry-out bit from bit 63
* **Functional Definition:**
  * `{c_out, sum} = a + b`
* **Notes:**
  * No subtraction support
  * No signed overflow flag output
