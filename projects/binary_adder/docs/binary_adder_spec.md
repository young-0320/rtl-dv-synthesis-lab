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

**Golden Vector File Format**

* **Path:** `sim/vector/golden_vectors.hex`
* **Type:** Plain text (one test case per line)
* **Line Format:** ``a(16hex) b(16hex) sum(16hex) c_out(1hex)``
* **Delimiter:** One or more spaces
* **Header:** None (data lines only)
* **Radix:** Hexadecimal (lowercase output from generator)
* **Semantics:** `sum` and `c_out` are golden expected outputs for the given `a`, `b`
* **Vector Count Rule:** `10 + random_count` (`random_count` default is `256`, so default file has `266` lines)
* **Example:**
  * `ffffffffffffffff 0000000000000001 0000000000000000 1`
