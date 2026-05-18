# AES Optimization Brief

For the next phase of this project we will implement two improvements:

1.  Replace logarithm-table based `gmul` with direct `xtime` arithmetic
2.  Introduce clock gating (via clock enable) in FSM and pipeline
    registers

These optimizations target two different aspects:

  Optimization       Target
  ------------------ ----------------------
  xtime MixColumns   Reduce LUT usage
  Clock gating       Reduce dynamic power

------------------------------------------------------------------------

# 1. Replace `gmul` with `xtime` Arithmetic

## Current Implementation

The current design performs Galois Field multiplication using
**logarithm and exponentiation lookup tables**.

gmul(a, b) = EXP3\[(LN3\[a\] + LN3\[b\]) mod 255\]

Tables used:

-   LN3\[256\]
-   EXP3\[256\]

These tables are defined in:

rtl/aes_array.sv

MixColumns then performs multiple table accesses per byte.

### Problem

This approach introduces:

-   Large constant LUT tables
-   High fan-out routing
-   Multiple table reads per multiplication

Each **MixColumns column** requires many `gmul` operations.

For the **pipelined architecture**, these tables are replicated across
every pipeline stage, which significantly increases LUT usage.

------------------------------------------------------------------------

## Proposed Improvement: `xtime`

Instead of lookup tables, AES multiplication can be implemented using
**bitwise shift and conditional XOR** operations.

### Core Function

``` systemverilog
function automatic [7:0] xtime(input [7:0] b);
    xtime = b[7] ? ({b[6:0],1'b0} ^ 8'h1b) : {b[6:0],1'b0};
endfunction
```

AES multiplications become:

2 · a = xtime(a)\
3 · a = xtime(a) \^ a

9 · a = xtime(xtime(xtime(a))) \^ a\
11 · a = xtime(xtime(xtime(a))) \^ xtime(a) \^ a\
13 · a = xtime(xtime(xtime(a))) \^ xtime(xtime(a)) \^ a\
14 · a = xtime(xtime(xtime(a))) \^ xtime(xtime(a)) \^ xtime(a)

### Files to Modify

-   rtl/aes_mcol.sv
-   rtl/aes_imcol.sv
-   rtl/aes_array.sv (remove EXP3/LN3 tables)

------------------------------------------------------------------------

## Significance for the Project

Replacing the logarithm tables provides several benefits.

### Major LUT Reduction

Removing:

-   LN3\[256\]
-   EXP3\[256\]

eliminates large LUT-based constant tables.

Estimated impact:

  Architecture       Current LUTs   Estimated After
  ------------------ -------------- -----------------
  Pipeline AES-128   38,766         \~25k--30k
  FSM AES-128        6,794          \~4k--5k

The improvement is especially significant for the **pipeline design**,
where the table fan-out occurs across multiple round stages.

### Better Hardware Scalability

Arithmetic implementation:

-   scales naturally with synthesis
-   avoids large ROM structures
-   improves placement and routing

### More Conventional AES Hardware

Most modern AES hardware implementations follow the **FIPS-197
polynomial arithmetic approach** using `xtime`.

Adopting this aligns the design with **standard AES hardware
architectures used in industry and academia**.

------------------------------------------------------------------------

# 2. Clock Gating (Clock Enable)

## Motivation

Currently many registers toggle **every clock cycle**, even when:

-   the FSM is idle
-   pipeline stages are not active
-   key expansion is not progressing

This unnecessary switching increases **dynamic power consumption**.

------------------------------------------------------------------------

## FPGA-Friendly Clock Gating

Instead of physically gating the clock (not recommended in FPGA), we use
the **flip-flop clock enable (CE)** feature.

Example:

### Current Register

``` systemverilog
always_ff @(posedge clk) begin
    r <= rin;
end
```

### Clock-Enabled Register

``` systemverilog
always_ff @(posedge clk) begin
    if (enable)
        r <= rin;
end
```

The synthesis tool maps `enable` to the **CE pin of the flip-flop**,
requiring no extra LUTs.

------------------------------------------------------------------------

## Locations to Apply Clock Enable

### FSM State Registers

Files:

-   rtl/aes_state.sv
-   rtl/aes_cipher_state.sv
-   rtl/aes_icipher_state.sv

Registers update only when the FSM is active.

fsm_active = (state != IDLE)

------------------------------------------------------------------------

### Pipeline Stage Registers

File:

rtl/aes_cipher.sv

Registers should only propagate data when valid pipeline data exists.

if (Ready_P\[i\]) State_Reg\[i\] \<= State_Next;

------------------------------------------------------------------------

### Key Expansion Registers

File:

rtl/aes_kexp.sv

Key schedule registers should update only when key expansion is active.

if (kexp_enable) KExp_N \<= KExp_P;

------------------------------------------------------------------------

## Significance for the Project

Clock gating improves the design by:

### Reduced Dynamic Power

Research on AES hardware shows approximately **17--24% reduction in
dynamic power** when clock gating is applied to inactive registers.

### No Area Cost

Clock enable uses existing **flip-flop CE pins**, meaning:

-   no additional LUTs
-   no additional routing

### Improved Hardware Efficiency

This is particularly beneficial for the **pipeline architecture**, where
thousands of registers exist across round stages.

------------------------------------------------------------------------

# Summary

This optimization phase introduces two practical improvements to the AES
project.

  -----------------------------------------------------------------------
  Optimization            Goal                    Impact
  ----------------------- ----------------------- -----------------------
  Replace gmul with xtime Remove table-based GF   Major LUT reduction
                          multiplication          

  Clock gating via CE     Reduce unnecessary      Lower dynamic power
                          register switching      
  -----------------------------------------------------------------------

Together these changes:

-   reduce LUT utilization
-   improve routing efficiency
-   lower power consumption
-   move the design closer to optimized AES hardware implementations

while maintaining the project's architectural comparison between
**pipeline and FSM AES designs**.
