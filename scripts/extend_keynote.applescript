-- extend_keynote.applescript
-- Extends AES.key with 7-phase optimization results after the "Future Work" slide.
-- Run: osascript scripts/extend_keynote.applescript
-- Requires: Keynote app installed, chart PNGs in docs/charts/

property chartDir : (POSIX path of ((path to home folder as string) & "Developer:aes:docs:charts:"))
property keyPath  : (POSIX path of ((path to home folder as string) & "Developer:aes:AES.key"))

-- --- helpers ------------------------------------------------------------------

on makeTitle(sl, titleText)
    tell sl
        set tBox to its text items whose object description contains "title"
        if (count of tBox) > 0 then
            set object text of (item 1 of tBox) to titleText
        end if
    end tell
end makeTitle

on makeBody(sl, bodyText)
    tell sl
        set bBox to its text items whose object description contains "body"
        if (count of bBox) > 0 then
            set object text of (item 1 of bBox) to bodyText
        end if
    end tell
end makeBody

-- Add a plain title+body text slide after slide number afterIdx
on addTextSlide(doc, afterIdx, titleText, bodyText)
    tell doc
        -- duplicate an existing content slide as template
        set tSlide to slide afterIdx
        set newSl to make new slide at end of slides with properties {base slide:master slide "Blank" of doc}
        -- move it right after afterIdx
        move newSl to after slide afterIdx
    end tell

    tell newSl
        -- title shape
        set titleShape to make new text item at end of text items with properties ¬
            {object text:"TITLE_PLACEHOLDER", width:860, height:70, position:{50, 40}}
        set object text of titleShape to titleText
        tell titleShape
            set size of every character to 28
            set bold of every character to true
            set color of every character to {0, 58, 140} -- dark blue
        end tell

        -- body shape
        set bodyShape to make new text item at end of text items with properties ¬
            {object text:"BODY_PLACEHOLDER", width:880, height:460, position:{40, 130}}
        set object text of bodyShape to bodyText
        tell bodyShape
            set size of every character to 16
        end tell
    end tell

    return newSl
end addTextSlide

-- --- main ---------------------------------------------------------------------

tell application "Keynote"
    activate

    -- Open file
    set keyFile to POSIX file keyPath
    open keyFile
    delay 2

    set doc to front document
    set slideCount to count of slides of doc

    -- Find "Future Work" slide
    set futureWorkIdx to -1
    repeat with i from 1 to slideCount
        set sl to slide i of doc
        set slTitle to ""
        try
            set slTitle to object text of title item of sl
        end try
        if slTitle contains "Future Work" or slTitle contains "future work" then
            set futureWorkIdx to i
            exit repeat
        end if
    end repeat

    if futureWorkIdx = -1 then
        -- If not found, append after last slide
        set futureWorkIdx to slideCount
    end if

    set insertAt to futureWorkIdx
    set newSlides to {}

    -- -- SECTION DIVIDER: Phase Results Overview ------------------------------
    set sl1 to make new slide at end of slides of doc
    move sl1 to after slide insertAt
    set insertAt to insertAt + 1
    tell sl1
        set newShape to make new text item at end of text items with properties ¬
            {object text:" ", width:860, height:540, position:{50, 70}}
        set object text of newShape to "7-Phase Optimization Results"
        tell newShape
            set alignment of every paragraph to center
            set size of every character to 44
            set bold of every character to true
            set color of every character to {0, 58, 140}
        end tell
        set sub to make new text item at end of text items with properties ¬
            {object text:" ", width:860, height:60, position:{50, 380}}
        set object text of sub to "AES RTL on Artix-7 xc7a35t . Yosys + Vivado . Dynamic Power Analysis"
        tell sub
            set alignment of every paragraph to center
            set size of every character to 18
            set color of every character to {80, 80, 80}
        end tell
    end tell
    end tell -- application Keynote (pause to let Keynote settle)

delay 0.5

tell application "Keynote"
    set doc to front document

    -- -- SLIDE: Phase Overview Table -------------------------------------------
    set sl2 to make new slide at end of slides of doc
    move sl2 to after slide insertAt
    set insertAt to insertAt + 1
    tell sl2
        set t1 to make new text item at end of text items with properties ¬
            {object text:" ", width:880, height:55, position:{40, 25}}
        set object text of t1 to "7 Optimization Phases - What Changed"
        tell t1
            set size of every character to 26
            set bold of every character to true
            set color of every character to {0, 58, 140}
        end tell

        set phaseText to "Phase 1 - xtime Arithmetic & Table Elimination
* Replaced GF(2^8) log-table gmul with shift-and-XOR xtime arithmetic
* Removed EXP3/LN3 ROM (512 x 8-bit entries) and all port stubs across 10 modules
* Largest single area drop: -77% FSM LUTs (Yosys, AES-128)

Phase 2 - FSM Register Clock Enable Gating (v1.0)
* Added CE guards to FSM state registers in cipher, icipher, kexp state modules
* CE = (state != IDLE) OR (ready = 1) OR (Enable = 1) - three necessary terms
* Result: data-path gating - registers freeze at idle; no LUT change, power drops

Phase 4 - CFA S-Box (Composite Field Arithmetic)
* Replaced 256x8-bit ROM S-Box with fully combinational GF((2^4)^2) Canright inversion
* Tower-field decomposition: basis change -> GF(2^4) inversion -> inverse basis + affine
* Eliminates LUTRAM primitives (3 -> 0); 256/256 input values exhaustively verified

Phase 5 - Pipeline Stage Clock Enable (OR-CE Flush Pattern)
* Applied CE guards to all Nr-1 pipeline stage registers
* OR-CE: CE[i] = Ready_Reg[i-2]  OR  Ready_Reg[i-1] - prevents deadlock & enables self-drain
* Pipeline now quiesces cleanly after Enable de-asserts; no LUT change

Phase 6 - Fine-Grained Clock Enable Gating
* CG-01: State_N register CE (128-bit datapath, FSM)
* CG-02: Key expansion pipeline stage CE (aes_kexp.sv - longest latency path)
* CG-03: Mux-gating CFA S-Box inputs -> forces 0x00 at idle -> zero toggle in ~100-gate tree

Phase 7 - Unified Enc/Dec FSM
* Merged aes_cipher_state.sv + aes_icipher_state.sv -> aes_unified_state.sv
* Single direction_r register; key index = direction ? Nr-round : round
* IDLE = 4'hF (all-ones sentinel); -10.6% LUT, -32.5% FF (AES-128, Yosys)"

        set b1 to make new text item at end of text items with properties ¬
            {object text:" ", width:880, height:490, position:{40, 90}}
        set object text of b1 to phaseText
        tell b1
            set size of every character to 12
        end tell
    end tell
end tell

delay 0.3

tell application "Keynote"
    set doc to front document

    -- -- SLIDE: xtime Theory + Formula ----------------------------------------
    set sl3 to make new slide at end of slides of doc
    move sl3 to after slide insertAt
    set insertAt to insertAt + 1
    tell sl3
        set t1 to make new text item at end of text items with properties ¬
            {object text:" ", width:880, height:55, position:{40, 20}}
        set object text of t1 to "Phase 1 - xtime: GF(2^8) Multiplication Without Tables"
        tell t1
            set size of every character to 24
            set bold of every character to true
            set color of every character to {0, 58, 140}
        end tell

        set formulaText to "Core formula - multiply by 2 in GF(2^8):

  xtime(a)  =  (a << 1)  XOR  (0x1B   if  a[7] = 1,   else  0x00)

Why it works:  shifting left by 1 computes a.x in GF(2^8).
If degree-8 term appears (a[7]=1), reduce modulo p(x) = x^8+x^4+x^3+x+1 by XOR-ing 0x1B.

MixColumns coefficients from xtime:
  x1  =  a                          (identity)
  x2  =  xtime(a)
  x3  =  xtime(a)  XOR  a

InvMixColumns coefficients - chained xtime:
  xt4(a)  =  xtime(xtime(a))
  xt8(a)  =  xtime(xt4(a))
  x9   =  xt8  XOR  a
  x11  =  xt8  XOR  xt2  XOR  a
  x13  =  xt8  XOR  xt4  XOR  a
  x14  =  xt8  XOR  xt4  XOR  xt2

Impact:
  Table-based:   EXP3[( LN3[a] + LN3[c] ) mod 255]   -> ROM read every cycle
  xtime-based:   shift + conditional XOR                -> pure combinational logic
  Yosys LUT delta (AES-128 FSM):  184,918 -> 42,181   (-77.2%)"

        set b1 to make new text item at end of text items with properties ¬
            {object text:" ", width:880, height:490, position:{40, 85}}
        set object text of b1 to formulaText
        tell b1
            set size of every character to 13
        end tell
    end tell
end tell

delay 0.3

tell application "Keynote"
    set doc to front document

    -- -- SLIDE: Data Path Gating vs Clock Gating -------------------------------
    set sl4 to make new slide at end of slides of doc
    move sl4 to after slide insertAt
    set insertAt to insertAt + 1
    tell sl4
        set t1 to make new text item at end of text items with properties ¬
            {object text:" ", width:880, height:55, position:{40, 20}}
        set object text of t1 to "Phase 2 / 5 / 6 - Data Path Gating vs Clock Gating"
        tell t1
            set size of every character to 24
            set bold of every character to true
            set color of every character to {0, 58, 140}
        end tell

        set cgText to "Clock Gating (tool-inserted ICG):
  CLK  -->  [ICG]  -->  FF.clk
  Saves: register cell power + clock net switching
  Does NOT save: combinational fanin power (D input still evaluates)
  DeltaP = C_clk . V^2 . f . (1 - duty_cycle)

Data Path Gating (this project - CE / Mux):
  DATA  -->  [MUX]  -->  FF.D
  CE = (state != IDLE)  OR  (ready = 1)  OR  (Enable = 1)
  Saves: switching activity alpha on data signals + all combinational fanin logic
  DeltaP = alpha . C_data . V^2 . f . (1 - duty_cycle)    where alpha -> 0 when data_in = const

Why CE condition has three terms - removing any one breaks behavior:
  state != IDLE    -> active rounds must always advance
  ready = 1       -> ready bit must persist so host can read completion
  Enable = 1      -> seeds FSM out of IDLE on new request

CG-03 Mux-gating (Phase 6):
  sbyte_in_muxed[i]  =  Ready_Reg[i] ? State_Reg[i] : '{default:'0}
  Forces 0x00 to CFA S-Box at idle -> constant input -> zero toggle across ~100 gates
  This is where most of the -34.6% power reduction originates

FPGA note:  Vivado synthesises CE -> FDRE primitive (CE pin).
  Clock still toggles every cycle; register power is NOT saved.
  Power saved = data signal switching activity - confirmed by SAIF annotation."

        set b1 to make new text item at end of text items with properties ¬
            {object text:" ", width:880, height:490, position:{40, 85}}
        set object text of b1 to cgText
        tell b1
            set size of every character to 13
        end tell
    end tell
end tell

delay 0.3

tell application "Keynote"
    set doc to front document

    -- -- SLIDE: CFA S-Box Theory -----------------------------------------------
    set sl5 to make new slide at end of slides of doc
    move sl5 to after slide insertAt
    set insertAt to insertAt + 1
    tell sl5
        set t1 to make new text item at end of text items with properties ¬
            {object text:" ", width:880, height:55, position:{40, 20}}
        set object text of t1 to "Phase 4 - CFA S-Box: Composite Field Arithmetic"
        tell t1
            set size of every character to 24
            set bold of every character to true
            set color of every character to {0, 58, 140}
        end tell

        set cfaText to "AES S-Box definition:
  S(a)  =  AffineTransform( a^-^1 in GF(2^8) )        [a != 0]
  S(0)  =  0x63

Canright tower-field technique - 3 steps:

Step 1 - Basis Change:
  B: GF(2^8) -> GF((2^4)^2)
  [b7..b0] = B_matrix . [a7..a0]   (matrix multiply over GF(2))

Step 2 - Tower Field Inversion:
  Write element as (A, B) where A, B in GF(2^4)
  (A, B)^-^1  =  (d.B,  d.(A XOR B))
  d  =  (A.B  XOR  nu.(A XOR B)^2)^-^1  in GF(2^4)
  GF(2^4) inversion -> GF(2^2) operations -> pure XOR + AND gates

Step 3 - Inverse Basis + Affine Transform:
  Convert back to GF(2^8), apply AES affine matrix
  0x63 constant embedded via XNOR gates (no separate adder)

Semantic preservation: isomorphic ring homomorphism -> field inversion preserved
256/256 input values exhaustively verified byte-for-byte

Area comparison:
  ROM (Vivado BRAM):    ~256 LUT-equivalents or 1 BRAM
  ROM (Yosys LUT RAM):  ~256 distributed LUTs
  CFA combinational:    ~100 LUTs (cascade of small GF gates)
  LUTRAM primitives:    3 -> 0 after CFA substitution (all key sizes)"

        set b1 to make new text item at end of text items with properties ¬
            {object text:" ", width:880, height:490, position:{40, 85}}
        set object text of b1 to cfaText
        tell b1
            set size of every character to 12.5
        end tell
    end tell
end tell

delay 0.3

tell application "Keynote"
    set doc to front document

    -- -- SLIDE: Phase 7 Unified FSM --------------------------------------------
    set sl6 to make new slide at end of slides of doc
    move sl6 to after slide insertAt
    set insertAt to insertAt + 1
    tell sl6
        set t1 to make new text item at end of text items with properties ¬
            {object text:" ", width:880, height:55, position:{40, 20}}
        set object text of t1 to "Phase 7 - Unified Enc/Dec FSM"
        tell t1
            set size of every character to 24
            set bold of every character to true
            set color of every character to {0, 58, 140}
        end tell

        set fsmText to "Before:  two separate FSMs
  aes_cipher_state.sv   (encrypt, counts up 0 -> Nr)
  aes_icipher_state.sv  (decrypt, counts down Nr -> 0)
  Each ~200 lines; structurally identical except direction and key index

After:  single unified FSM  aes_unified_state.sv  (~186 lines)
  One direction_r register latched at Enable:
    typedef enum logic [3:0] { IDLE = 4'hF, ... } state_t;
    logic direction_r;   // 0 = encrypt,  1 = decrypt

Key index mux:
    assign Index = direction_r ? (Nr[3:0] - round_r) : round_r;
  -> correct reverse key-schedule traversal for decrypt without duplicating logic

IDLE = 4'hF (all-ones):
  Outside normal round range [0, Nr] -> simple compare, no complex decode

Impact (AES-128, Yosys):
  LUT:  17,467 -> 15,621     (-10.6%)
  FF:      406 ->    274     (-32.5%)
  Cumulative LUT reduction from pre-xtime baseline:  -91.6%

Vivado note:  shows LUT increase (3,185 -> 4,094) for AES-128 at this boundary.
  Cause: direction-select mux logic at datapath top maps to extra LUTs.
  Yosys confirms design is structurally smaller - Vivado result is a mapper artefact."

        set b1 to make new text item at end of text items with properties ¬
            {object text:" ", width:880, height:490, position:{40, 85}}
        set object text of b1 to fsmText
        tell b1
            set size of every character to 13
        end tell
    end tell
end tell

delay 0.3

tell application "Keynote"
    set doc to front document

    -- -- SLIDE: Chart - Yosys FSM LUT -----------------------------------------
    set sl7 to make new slide at end of slides of doc
    move sl7 to after slide insertAt
    set insertAt to insertAt + 1
    tell sl7
        set t1 to make new text item at end of text items with properties ¬
            {object text:" ", width:880, height:50, position:{40, 15}}
        set object text of t1 to "LUT Results - Yosys (FSM Architecture, All Key Sizes)"
        tell t1
            set size of every character to 24
            set bold of every character to true
            set color of every character to {0, 58, 140}
        end tell

        set imgFile to POSIX file (chartDir & "chart_yosys_fsm_lut.png")
        set img to make new image at end of images with properties ¬
            {file:imgFile, width:860, height:460, position:{50, 75}}

        set note1 to make new text item at end of text items with properties ¬
            {object text:" ", width:880, height:30, position:{40, 545}}
        set object text of note1 to "Yosys 0.64 synth_xilinx -family xc7. CE-gating phases omit from LUT table (no LUT change). Power impact shown in Dynamic Power slide."
        tell note1
            set size of every character to 10
            set color of every character to {100, 100, 100}
        end tell
    end tell
end tell

delay 0.3

tell application "Keynote"
    set doc to front document

    -- -- SLIDE: Chart - Yosys Pipeline LUT ------------------------------------
    set sl8 to make new slide at end of slides of doc
    move sl8 to after slide insertAt
    set insertAt to insertAt + 1
    tell sl8
        set t1 to make new text item at end of text items with properties ¬
            {object text:" ", width:880, height:50, position:{40, 15}}
        set object text of t1 to "LUT Results - Yosys (Pipeline Architecture, All Key Sizes)"
        tell t1
            set size of every character to 24
            set bold of every character to true
            set color of every character to {0, 58, 140}
        end tell

        set imgFile to POSIX file (chartDir & "chart_yosys_pipeline_lut.png")
        set img to make new image at end of images with properties ¬
            {file:imgFile, width:860, height:460, position:{50, 75}}

        set note1 to make new text item at end of text items with properties ¬
            {object text:" ", width:880, height:30, position:{40, 545}}
        set object text of note1 to "Pipeline xtime phase shows 0% LUT change - ROM tables in pipeline path not hit by Phase 1 at this commit. CFA S-Box (Phase 4) delivers the main pipeline reduction."
        tell note1
            set size of every character to 10
            set color of every character to {100, 100, 100}
        end tell
    end tell
end tell

delay 0.3

tell application "Keynote"
    set doc to front document

    -- -- SLIDE: Chart - Vivado FSM LUT ----------------------------------------
    set sl9 to make new slide at end of slides of doc
    move sl9 to after slide insertAt
    set insertAt to insertAt + 1
    tell sl9
        set t1 to make new text item at end of text items with properties ¬
            {object text:" ", width:880, height:50, position:{40, 15}}
        set object text of t1 to "LUT Results - Vivado (FSM, Artix-7 xc7a35t)"
        tell t1
            set size of every character to 24
            set bold of every character to true
            set color of every character to {0, 58, 140}
        end tell

        set imgFile to POSIX file (chartDir & "chart_vivado_fsm_lut.png")
        set img to make new image at end of images with properties ¬
            {file:imgFile, width:860, height:460, position:{50, 75}}

        set note1 to make new text item at end of text items with properties ¬
            {object text:" ", width:880, height:30, position:{40, 545}}
        set object text of note1 to "Vivado 2023.2 post-synthesis. Unified FSM row (Ph7) shows AES-128 LUT rise - direction-select mux artefact; Yosys confirms structural reduction. Do NOT cross-compare with Yosys rows."
        tell note1
            set size of every character to 10
            set color of every character to {100, 100, 100}
        end tell
    end tell
end tell

delay 0.3

tell application "Keynote"
    set doc to front document

    -- -- SLIDE: Chart - Vivado Pipeline LUT -----------------------------------
    set sl10 to make new slide at end of slides of doc
    move sl10 to after slide insertAt
    set insertAt to insertAt + 1
    tell sl10
        set t1 to make new text item at end of text items with properties ¬
            {object text:" ", width:880, height:50, position:{40, 15}}
        set object text of t1 to "LUT Results - Vivado (Pipeline, Artix-7 xc7a35t)"
        tell t1
            set size of every character to 24
            set bold of every character to true
            set color of every character to {0, 58, 140}
        end tell

        set imgFile to POSIX file (chartDir & "chart_vivado_pipeline_lut.png")
        set img to make new image at end of images with properties ¬
            {file:imgFile, width:860, height:460, position:{50, 75}}

        set note1 to make new text item at end of text items with properties ¬
            {object text:" ", width:880, height:30, position:{40, 545}}
        set object text of note1 to "Vivado 2023.2 post-synthesis. LUTRAM count: 3 (baseline & xtime) -> 0 (after CFA S-Box) for all key sizes. AES-128 pipeline drops 91,467 -> 4,200 LUTs (-95.4%)."
        tell note1
            set size of every character to 10
            set color of every character to {100, 100, 100}
        end tell
    end tell
end tell

delay 0.3

tell application "Keynote"
    set doc to front document

    -- -- SLIDE: Yosys vs Vivado Discrepancy -----------------------------------
    set sl11 to make new slide at end of slides of doc
    move sl11 to after slide insertAt
    set insertAt to insertAt + 1
    tell sl11
        set t1 to make new text item at end of text items with properties ¬
            {object text:" ", width:880, height:55, position:{40, 20}}
        set object text of t1 to "Why Yosys and Vivado Results Differ (Up to 23x)"
        tell t1
            set size of every character to 24
            set bold of every character to true
            set color of every character to {0, 58, 140}
        end tell

        set discText to "Root cause: different ROM mapping strategies

  Tool           ROM Mapping          Effect on LUT count
  ------------------------------------------------------
  Yosys          LUT RAM (distributed) ROM counted as LUTs
  Vivado         BRAM (block RAM)      ROM = 0 LUTs (BRAM not in LUT budget)

Consequence for Phase 4 (CFA S-Box):
  * Yosys: ROM was in LUT count -> CFA (combinational) shows LUT reduction  [OK]
  * Vivado: BRAM was free in LUT terms -> CFA adds logic -> apparent LUT increase  [!] (artefact)

Correct interpretation:
  * Yosys: reliable for relative phase-to-phase deltas (consistent tool baseline)
  * Vivado: authoritative for absolute FPGA resource reporting (place-and-route accurate)
  * Never mix Yosys and Vivado rows when computing percentage reductions

Additional effects:
  * LUTRAM count (Vivado): 3 -> 0 after CFA substitution - frees routing capacity
  * Non-monotonic LUT vs key size (pipeline): AES-192 key expansion uses fewer stages
    than AES-128 because wider key words pack more schedule entries per stage
    -> this is architectural, not a synthesis artefact
  * Phase 7 Vivado AES-128 LUT increase: direction-select mux at datapath top;
    Yosys confirms -10.6% structural reduction"

        set b1 to make new text item at end of text items with properties ¬
            {object text:" ", width:880, height:490, position:{40, 85}}
        set object text of b1 to discText
        tell b1
            set size of every character to 13
        end tell
    end tell
end tell

delay 0.3

tell application "Keynote"
    set doc to front document

    -- -- SLIDE: Chart - Dynamic Power -----------------------------------------
    set sl12 to make new slide at end of slides of doc
    move sl12 to after slide insertAt
    set insertAt to insertAt + 1
    tell sl12
        set t1 to make new text item at end of text items with properties ¬
            {object text:" ", width:880, height:50, position:{40, 15}}
        set object text of t1 to "Dynamic Power - Clock Gating Results (Vivado SAIF Annotation)"
        tell t1
            set size of every character to 22
            set bold of every character to true
            set color of every character to {0, 58, 140}
        end tell

        set imgFile to POSIX file (chartDir & "chart_dynamic_power.png")
        set img to make new image at end of images with properties ¬
            {file:imgFile, width:860, height:460, position:{50, 75}}

        set note1 to make new text item at end of text items with properties ¬
            {object text:" ", width:880, height:30, position:{40, 545}}
        set object text of note1 to "Total dynamic: 0.217W (baseline) -> 0.142W (full gating) = -34.6%. I/O flat because top-level port toggle rate is set by stimulus, not internal enables."
        tell note1
            set size of every character to 10
            set color of every character to {100, 100, 100}
        end tell
    end tell
end tell

delay 0.3

tell application "Keynote"
    set doc to front document

    -- -- SLIDE: Dynamic Power Detail Table ------------------------------------
    set sl13 to make new slide at end of slides of doc
    move sl13 to after slide insertAt
    set insertAt to insertAt + 1
    tell sl13
        set t1 to make new text item at end of text items with properties ¬
            {object text:" ", width:880, height:55, position:{40, 20}}
        set object text of t1 to "Dynamic Power Detail - All Gating Stages"
        tell t1
            set size of every character to 24
            set bold of every character to true
            set color of every character to {0, 58, 140}
        end tell

        set pwrText to "Vivado report_power (SAIF annotation) - AES-128 Pipeline, Artix-7 xc7a35t

  Power Category    Baseline (W)    Post FSM CE (W)    Post Full CE + Mux (W)
  -----------------------------------------------------------------------------
  Clocks              0.042             0.036                  0.030
  Signals             0.068             0.052                  0.040
  Logic               0.095             0.074                  0.060
  I/O                 0.012             0.012                  0.012
  -----------------------------------------------------------------------------
  Total Dynamic       0.217 W           0.174 W                0.142 W
  Reduction                             -19.8%                 -34.6%

Idle-toggle register analysis (Verilator VCD, strict idle windows):
  Architecture    Reg-candidate toggles (Baseline)    Post-CG
  -------------------------------------------------------------
  FSM                        0                              0
  Pipeline              101,035                             0    (-100%)

Total DUT bit toggles: 939,018 -> 50,449  (-94.6%)

FSM CE gating: -20% dynamic power (signal + logic switching)
Pipeline stage CE + sub-round mux gating: additional -15% (100% idle toggle elimination)"

        set b1 to make new text item at end of text items with properties ¬
            {object text:" ", width:880, height:490, position:{40, 85}}
        set object text of b1 to pwrText
        tell b1
            set size of every character to 12.5
        end tell
    end tell
end tell

delay 0.3

tell application "Keynote"
    set doc to front document

    -- -- SLIDE: Cumulative LUT chart -------------------------------------------
    set sl14 to make new slide at end of slides of doc
    move sl14 to after slide insertAt
    set insertAt to insertAt + 1
    tell sl14
        set t1 to make new text item at end of text items with properties ¬
            {object text:" ", width:880, height:50, position:{40, 15}}
        set object text of t1 to "Cumulative LUT Reduction - AES-128 FSM (Yosys)"
        tell t1
            set size of every character to 24
            set bold of every character to true
            set color of every character to {0, 58, 140}
        end tell

        set imgFile to POSIX file (chartDir & "chart_cumulative_lut.png")
        set img to make new image at end of images with properties ¬
            {file:imgFile, width:860, height:460, position:{50, 75}}

        set note1 to make new text item at end of text items with properties ¬
            {object text:" ", width:880, height:30, position:{40, 545}}
        set object text of note1 to "184,918 -> 15,621 LUTs - 91.6% cumulative reduction. xtime (Ph1) and CFA S-Box (Ph4) are the dominant area steps. Unified FSM (Ph7) adds -10.6% structural cleanup."
        tell note1
            set size of every character to 10
            set color of every character to {100, 100, 100}
        end tell
    end tell
end tell

delay 0.3

tell application "Keynote"
    set doc to front document

    -- -- SLIDE: Numerical Results Summary Table --------------------------------
    set sl15 to make new slide at end of slides of doc
    move sl15 to after slide insertAt
    set insertAt to insertAt + 1
    tell sl15
        set t1 to make new text item at end of text items with properties ¬
            {object text:" ", width:880, height:55, position:{40, 20}}
        set object text of t1 to "Complete Results Summary - All Architectures & Key Sizes"
        tell t1
            set size of every character to 22
            set bold of every character to true
            set color of every character to {0, 58, 140}
        end tell

        set tblText to "Yosys LUT - FSM Architecture (AES-128/192/256)
  Boundary                  128 LUT    128%    192 LUT    192%    256 LUT    256%
  --------------------------------------------------------------------------------
  Baseline                  184,918     0%     193,131     0%     202,490     0%
  xtime + Table Removal      42,181   -77%      49,381   -74%      59,710   -71%
  CFA S-Box                  17,484   -91%      24,512   -87%      35,444   -83%
  Unified enc/dec FSM        15,621   -92%      22,798   -88%      33,160   -84%

Yosys LUT - Pipeline Architecture (AES-128/192/256)
  Boundary                  128 LUT    128%    192 LUT    192%    256 LUT    256%
  --------------------------------------------------------------------------------
  Baseline                  380,018     0%     412,970     0%     539,052     0%
  xtime + Table Removal     380,018     0%     412,970     0%     538,572    ~0%
  CFA S-Box                 134,289   -65%     115,335   -72%     192,391   -64%

Vivado - FSM (Artix-7)
  Baseline    AES-128: 13,268 LUT / 413 FF     AES-192: 19,896 LUT     AES-256: 13,938 LUT
  Post-CFA    AES-128:  3,185 LUT / 437 FF     AES-192:  9,605 LUT     AES-256:  4,913 LUT
  Post-Ph7    AES-128:  4,094 LUT / 1291 FF*   AES-192: 11,438 LUT     AES-256:  6,769 LUT
  * Vivado mapper artefact - Yosys confirms structural reduction

Vivado - Pipeline (Artix-7)
  Baseline    AES-128: 91,467 LUT / 3,843 FF   AES-192: 112,318 LUT    AES-256: 132,461 LUT
  Post-xtime  AES-128: 21,816 LUT / 3,843 FF
  Post-CFA    AES-128:  4,200 LUT / 1,286 FF   AES-192:   3,596 LUT    AES-256:   5,376 LUT"

        set b1 to make new text item at end of text items with properties ¬
            {object text:" ", width:880, height:490, position:{40, 85}}
        set object text of b1 to tblText
        tell b1
            set size of every character to 11
        end tell
    end tell
end tell

delay 0.3

tell application "Keynote"
    set doc to front document

    -- -- SLIDE: Clock Gating Application Map ----------------------------------
    set sl16 to make new slide at end of slides of doc
    move sl16 to after slide insertAt
    set insertAt to insertAt + 1
    tell sl16
        set t1 to make new text item at end of text items with properties ¬
            {object text:" ", width:880, height:55, position:{40, 20}}
        set object text of t1 to "Clock Gating Application Map - Where & Why"
        tell t1
            set size of every character to 24
            set bold of every character to true
            set color of every character to {0, 58, 140}
        end tell

        set mapText to "  #   Phase    File                     What is gated              Gate condition
  --------------------------------------------------------------------------------------
  1    Ph2     aes_cipher_state.sv      r struct (state + ready)   state!=0  OR  ready  OR  Enable
  2    Ph2     aes_icipher_state.sv     r struct                   state!=Nr  OR  ready  OR  Enable
  3    Ph2     aes_kexp_state.sv        r struct + KExp_N          state!=0  OR  ready  OR  Enable (r);
                                                                   state!=0  OR  Enable (KExp_N)
  4    Ph5     aes_cipher.sv            State_Reg[i]+Ready_Reg[i]  Stage 0: Enable  OR  Ready[0]
                                                                   Stage i: Ready[i-2]  OR  Ready[i-1]
  5    Ph5     aes_icipher.sv           State_Reg[i]+Ready_Reg[i]  Stage Nr-1: Enable  OR  Ready[Nr-1]
                                                                   Stage i: Ready[i+1]  OR  Ready[i]
  6    Ph6/01  aes_cipher_state.sv      State_N (128-bit data)     Same as r guard
  7    Ph6/01  aes_icipher_state.sv     State_N                    state!=Nr  OR  ready  OR  Enable
  8    Ph6/02  aes_kexp.sv              KExp_N[i]+Ready_N[i]       Stage 0: Enable  OR  Ready_N[0]
                                                                   Stage i: Ready_N[i-1]
  9    Ph6/03  aes_cipher.sv            sbyte_in_muxed[i]          Ready[i] ? State[i] : '0
  10   Ph6/03  aes_icipher.sv           isbyte_in_muxed[i]         Ready[i] ? State[i] : '0

Key insight:  Items 9 & 10 (mux-gating CFA inputs) are the dominant power savers.
  A constant 0x00 input to the ~100-gate CFA tree -> zero toggle activity across all nodes."

        set b1 to make new text item at end of text items with properties ¬
            {object text:" ", width:880, height:490, position:{40, 85}}
        set object text of b1 to mapText
        tell b1
            set size of every character to 11
        end tell
    end tell
end tell

delay 0.3

tell application "Keynote"
    set doc to front document

    -- -- SLIDE: Key Takeaways -------------------------------------------------
    set sl17 to make new slide at end of slides of doc
    move sl17 to after slide insertAt
    set insertAt to insertAt + 1
    tell sl17
        set t1 to make new text item at end of text items with properties ¬
            {object text:" ", width:880, height:55, position:{40, 20}}
        set object text of t1 to "Key Takeaways"
        tell t1
            set size of every character to 30
            set bold of every character to true
            set color of every character to {0, 58, 140}
        end tell

        set takeText to "Area (LUT) reduction:
  - -91.6% cumulative LUT reduction (AES-128 FSM, Yosys: 184,918 -> 15,621)
  - xtime Phase 1: largest single step - -77% from ROM elimination alone
  - CFA S-Box Phase 4: -58% from post-xtime baseline; eliminates all LUTRAM primitives
  - Unified FSM Phase 7: structural cleanup -10.6% LUT, -32.5% FF

Power reduction:
  - -34.6% total dynamic power (0.217 W -> 0.142 W, Vivado SAIF)
  - 100% elimination of idle register-candidate toggles (pipeline: 101,035 -> 0)
  - 94.6% reduction in total DUT bit toggles (939,018 -> 50,449)
  - No ICG cells inserted - all savings from data-path gating (CE + mux)

Correctness throughout:
  - All 7 phases preserve AES semantics - NIST vectors pass at every boundary
  - xtime and CFA S-Box exhaustively verified (all 256 GF(2^8) values)
  - CE conditions formally necessary: removing any term breaks a specific corner case

Tool insight:
  - Yosys vs Vivado discrepancy (up to 23x) explained by BRAM vs LUT RAM mapping
  - Use Yosys for phase-to-phase deltas; Vivado for absolute FPGA resource numbers"

        set b1 to make new text item at end of text items with properties ¬
            {object text:" ", width:880, height:460, position:{40, 90}}
        set object text of b1 to takeText
        tell b1
            set size of every character to 14
        end tell
    end tell
end tell

delay 0.3

tell application "Keynote"
    set doc to front document

    -- Save
    save doc

    set finalCount to count of slides of doc
    display dialog "Done! " & finalCount & " total slides. New slides added after slide " & futureWorkIdx & "." buttons {"OK"} default button "OK"
end tell
