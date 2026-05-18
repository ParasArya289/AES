"""
Phases 5, 6, 7 — one file each produces its own PPTX.
Phase 5: Pipeline OR-CE Flush Pattern (2 slides)
Phase 6: Fine-Grained CE Gating — CG-01/02/03 (3 slides)
Phase 7: Unified Enc/Dec FSM (2 slides)
"""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from slide_engine import *
import matplotlib; matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.patches import FancyBboxPatch
import numpy as np
from pathlib import Path

ROOT   = Path(__file__).parent.parent
CHARTS = ROOT / "docs" / "charts"
OUT    = ROOT / "phase_slides"
OUT.mkdir(exist_ok=True)


# ══════════════════════════════════════════════════════════════════════════════
# PHASE 5: Pipeline OR-CE
# ══════════════════════════════════════════════════════════════════════════════
def make_pipeline_ce_diagram():
    fig, axes = plt.subplots(1, 2, figsize=(14, 6.2))
    fig.patch.set_facecolor('#F4F6FA')

    for ax, title, is_after in zip(axes, ["BEFORE Phase 5 — No Stage CE", "AFTER Phase 5 — OR-CE Flush Pattern"], [False, True]):
        ax.set_facecolor('#F4F6FA'); ax.axis('off')
        ax.set_xlim(0, 9); ax.set_ylim(0, 9)
        ax.set_title(title, fontsize=12, fontweight='bold',
                     color='#B51919' if not is_after else '#176B38', pad=6)

        nr = 4  # simplified 4 stages
        stage_labels = ['Stage 0\n(seed)', 'Stage 1', 'Stage 2', 'Stage Nr-1\n(output)']
        stage_colors = ['#164E9C', '#164E9C', '#164E9C', '#164E9C']

        for i in range(nr):
            bx, by = 0.4 + i * 2.05, 6.5
            bw, bh = 1.75, 1.2

            # Stage register box
            ax.add_patch(FancyBboxPatch((bx, by), bw, bh,
                         boxstyle="round,pad=0.06", facecolor=stage_colors[i],
                         edgecolor='white', linewidth=1.8))
            ax.text(bx+bw/2, by+bh/2+0.1, stage_labels[i], ha='center', va='center',
                    fontsize=9, color='white', fontweight='bold')
            ax.text(bx+bw/2, by+0.15, 'State_Reg[i]\nReady_Reg[i]', ha='center',
                    fontsize=7.5, color='#B0C8E8')

            # Arrow to next stage
            if i < nr - 1:
                ax.annotate('', xy=(bx+bw+0.12, by+bh/2), xytext=(bx+bw, by+bh/2),
                            arrowprops=dict(arrowstyle='->', color='#5A6A7A', lw=2))

            # CE logic block
            if is_after:
                ce_y = by - 1.5
                fc_ce = '#176B38'
                if i == 0:
                    ce_text = 'CE = Enable\nOR Ready[0]'
                elif i == nr - 1:
                    ce_text = f'CE = Ready[{i-2}]\nOR Ready[{i-1}]'
                else:
                    ce_text = f'CE = Ready[{i-2}]\nOR Ready[{i-1}]'

                ax.add_patch(FancyBboxPatch((bx+0.1, ce_y), bw-0.2, 0.95,
                             boxstyle="round,pad=0.05", facecolor=fc_ce, edgecolor='white', linewidth=1.2))
                ax.text(bx+bw/2, ce_y+0.47, ce_text, ha='center', va='center',
                        fontsize=7.5, color='white', fontweight='bold')
                ax.annotate('', xy=(bx+bw/2, by), xytext=(bx+bw/2, ce_y+0.95),
                            arrowprops=dict(arrowstyle='->', color='#176B38', lw=1.8))
            else:
                # No CE — just "always enabled" mark
                ax.text(bx+bw/2, by-0.35, 'Always\nenabled', ha='center',
                        fontsize=8, color='#B51919', fontweight='bold')

        # Enable input
        ax.add_patch(FancyBboxPatch((0.1, 4.6), 1.5, 0.65,
                     boxstyle="round,pad=0.05", facecolor='#D45D00', edgecolor='white'))
        ax.text(0.85, 4.92, 'Enable', ha='center', va='center', fontsize=9, color='white', fontweight='bold')
        ax.annotate('', xy=(0.4+0.875, 6.5), xytext=(0.6, 4.6),
                    arrowprops=dict(arrowstyle='->', color='#D45D00', lw=1.8, linestyle='dashed'))

        # Problem / Solution annotation
        ax.add_patch(FancyBboxPatch((0.2, 0.15), 8.5, 2.4 if is_after else 1.8,
                     boxstyle="round,pad=0.1",
                     facecolor='#D4EDDA' if is_after else '#FDE8D0',
                     edgecolor='#176B38' if is_after else '#B51919', linewidth=1.5))
        if not is_after:
            ax.text(4.45, 2.2, 'Problem: No CE on pipeline stage registers', ha='center',
                    fontsize=10.5, color='#B51919', fontweight='bold')
            ax.text(4.45, 1.8, '• At idle, all stage registers latch stale data every clock cycle', ha='center',
                    fontsize=9.5, color='#1A1A2E')
            ax.text(4.45, 1.45, '• When Enable drops between two ops, in-flight data freezes mid-pipeline', ha='center',
                    fontsize=9.5, color='#1A1A2E')
            ax.text(4.45, 1.1, '• 101,035 idle register-candidate toggles per idle window (Verilator VCD)', ha='center',
                    fontsize=9.5, color='#B51919', fontweight='bold')
            ax.text(4.45, 0.7, '• Dynamic power dominated by these wasted toggle transitions', ha='center',
                    fontsize=9, color='#5A6A7A')
        else:
            ax.text(4.45, 2.3, 'OR-CE Flush Pattern — Self-Draining Pipeline', ha='center',
                    fontsize=10.5, color='#176B38', fontweight='bold')
            ax.text(4.45, 1.95, 'Stage 0:  CE = Enable  OR  Ready_Reg[0]    ← seeded by host + self-drain', ha='center',
                    fontsize=9.5, color='#1A1A2E', fontfamily='monospace')
            ax.text(4.45, 1.62, 'Stage i:  CE = Ready_Reg[i-2]  OR  Ready_Reg[i-1]   ← upstream + self', ha='center',
                    fontsize=9.5, color='#1A1A2E', fontfamily='monospace')
            ax.text(4.45, 1.28, 'Result: after Enable drops, pipeline drains stage-by-stage for exactly T cycles', ha='center',
                    fontsize=9.5, color='#176B38')
            ax.text(4.45, 0.9, 'Idle register-candidate toggles: 101,035 → 0  (−100%)', ha='center',
                    fontsize=10, color='#176B38', fontweight='bold')
            ax.text(4.45, 0.55, '3 bugs found during implementation: self-referential deadlock, '
                    'off-by-one bounds, indefinite hold', ha='center', fontsize=8.5, color='#5A6A7A')
            ax.text(4.45, 0.25, 'Symmetric pattern applied to aes_icipher.sv with descending stage indices', ha='center',
                    fontsize=8.5, color='#5A6A7A')

    plt.tight_layout(pad=1.0)
    path = CHARTS / "p5_pipeline_ce.png"
    plt.savefig(path, dpi=150, bbox_inches='tight', facecolor='#F4F6FA')
    plt.close()
    return path


def build_phase5():
    diag = make_pipeline_ce_diagram()
    prs = new_prs()

    sl = blank_slide(prs)
    slide_chrome(sl, "PHASE 5", "Pipeline Stage Clock Enable — OR-CE Flush Pattern",
                 subtitle="Files: aes_cipher.sv · aes_icipher.sv  |  Applies to all Nr−1 pipeline stage registers")
    add_img(sl, diag, MARGIN_L, Inches(0.82), Inches(12.43), Inches(5.75))
    footer(sl, "Phase 5 · OR-CE flush · 101,035 idle toggles → 0",
           right_text="No LUT change — effect is in switching activity and dynamic power")

    sl = blank_slide(prs)
    slide_chrome(sl, "PHASE 5", "Phase 5 — Design Decisions & Self-Drain Correctness",
                 subtitle="Why OR semantics are necessary — three bugs discovered during implementation")

    y = Inches(0.88)
    callout_box(sl, "Why upstream-only CE is WRONG",
                "First attempt:  CE[i] = Ready_Reg[i-1]   (upstream only)\n\n"
                "Failure mode:\n"
                "  After Enable drops, Ready_Reg holds at 1 (no one clears it).\n"
                "  Stage i: CE = Ready_Reg[i-1] = 1  → always enabled → never quiesces.\n"
                "  Output: Ready_Reg[Nr-1] stays 1 permanently → testbench reads stale data\n"
                "  as a valid result for the next encryption request.\n\n"
                "Fix: OR with self (Ready_Reg[i-1] = 1 when this stage is valid).\n"
                "Self term allows each stage to propagate a 0 forward and go dark,\n"
                "draining the pipeline cleanly one stage per cycle.",
                MARGIN_L, y, Inches(6.15), Inches(3.6),
                accent=RED, bg=LIGHT_ORG)

    callout_box(sl, "Three Implementation Bugs",
                "Bug 1 — Self-referential deadlock:\n"
                "  CE[i] = Ready[i-1] || Ready[i-1]  (same signal twice)\n"
                "  → stage could never re-open once closed\n\n"
                "Bug 2 — Off-by-one array bounds:\n"
                "  Generate loop upper bound wrong → final stage ungated\n"
                "  → indefinite hold on last output\n\n"
                "Bug 3 — Final stage CE missing self-drain:\n"
                "  CE[Nr-1] = Ready[Nr-2] only → freezes after first completion\n"
                "  Fix: CE[Nr-1] = Ready[Nr-2] || Ready[Nr-1]",
                Inches(6.6), y, Inches(6.28), Inches(3.6),
                accent=ORANGE, bg=LIGHT_ORG)

    headers = ["Stage", "CE Condition (aes_cipher.sv ascending)", "CE Condition (aes_icipher.sv descending)"]
    rows = [
        ["Stage 0 (seed)",   "Enable || Ready_Reg[0]",               "Enable || Ready_Reg[Nr-1]"],
        ["Stage i (mid)",    "Ready_Reg[i-2] || Ready_Reg[i-1]",     "Ready_Reg[i+1] || Ready_Reg[i]"],
        ["Stage Nr-1 (out)", "Ready_Reg[Nr-2] || Ready_Reg[Nr-1]",   "Ready_Reg[1] || Ready_Reg[0]"],
    ]
    add_table(sl, headers, rows,
              MARGIN_L, Inches(4.65), Inches(12.43), Inches(1.65),
              header_size=10.5, row_size=10)

    footer(sl, "Phase 5 · OR-CE semantics · correctness analysis",
           right_text="Symmetric index mirroring: cipher counts up, icipher counts down")

    prs.save(str(OUT / "Phase5_Pipeline_CE.pptx"))
    print(f"  Phase5_Pipeline_CE.pptx  ({len(prs.slides)} slides)")


# ══════════════════════════════════════════════════════════════════════════════
# PHASE 6: Fine-Grained CE (CG-01, CG-02, CG-03)
# ══════════════════════════════════════════════════════════════════════════════
def make_cg03_mux_diagram():
    fig, axes = plt.subplots(1, 2, figsize=(14, 6.2))
    fig.patch.set_facecolor('#F4F6FA')

    for ax, title, is_after in zip(axes, ["Before CG-03 — Registers gated, S-Box fanin still toggles",
                                           "After CG-03 — Mux forces 0x00 → S-Box freezes"], [False, True]):
        ax.set_facecolor('#F4F6FA'); ax.axis('off')
        ax.set_xlim(0, 9); ax.set_ylim(0, 9.5)
        ax.set_title(title, fontsize=11.5, fontweight='bold',
                     color='#B51919' if not is_after else '#176B38', pad=6)

        # Pipeline stage register (already gated by Phase 5)
        ax.add_patch(FancyBboxPatch((0.4, 6.5), 2.5, 1.6,
                     boxstyle="round,pad=0.06", facecolor='#007A87', edgecolor='white', linewidth=1.8))
        ax.text(1.65, 7.6, 'Stage i\nState_Reg[i]', ha='center', fontsize=10, color='white', fontweight='bold')
        ax.text(1.65, 7.05, 'Ready_Reg[i]', ha='center', fontsize=9, color='#B0E8E0')
        ax.text(1.65, 6.62, '(CE gated — Phase 5)', ha='center', fontsize=8, color='#B0E8E0')

        # Signal wire from register
        ax.annotate('', xy=(3.4, 7.2), xytext=(2.9, 7.2),
                    arrowprops=dict(arrowstyle='->', color='#5A6A7A', lw=2))

        if not is_after:
            # Direct connection — no mux
            ax.text(3.6, 7.4, 'State_Reg[i]', fontsize=9, color='#B51919', fontfamily='monospace')
            ax.text(3.6, 7.1, '(toggles at idle\neven though CE=0\nfor downstream reg)', fontsize=8.5, color='#B51919')
            ax.annotate('', xy=(5.2, 7.2), xytext=(5.0, 7.2),
                        arrowprops=dict(arrowstyle='->', color='#B51919', lw=2))

            # Wavy line to indicate toggle
            import numpy as np
            t = np.linspace(3.9, 5.0, 100)
            wave = 7.2 + 0.08 * np.sin(t * 20)
            ax.plot(t, wave, color='#B51919', lw=2)
        else:
            # MUX block
            mux_pts = [(3.3, 6.7), (3.3, 7.9), (4.1, 7.6), (4.1, 7.0)]
            ax.add_patch(plt.Polygon(mux_pts, closed=True, color='#007A87'))
            ax.text(3.65, 7.3, 'MUX', ha='center', va='center', fontsize=9.5, color='white', fontweight='bold')

            # Ready_Reg[i] → sel
            ax.annotate('', xy=(3.65, 7.0), xytext=(3.65, 6.3),
                        arrowprops=dict(arrowstyle='->', color='#FFD700', lw=1.8))
            ax.text(3.65, 6.15, "Ready_Reg[i]\n(select)", ha='center', fontsize=8.5,
                    color='#FFD700', fontweight='bold')

            # 0x00 input
            ax.add_patch(FancyBboxPatch((2.2, 7.6), 1.0, 0.5,
                         boxstyle="round,pad=0.04", facecolor='#176B38', edgecolor='white'))
            ax.text(2.7, 7.85, "0x00", ha='center', fontsize=9, color='white', fontweight='bold', fontfamily='monospace')
            ax.annotate('', xy=(3.3, 7.7), xytext=(3.2, 7.8),
                        arrowprops=dict(arrowstyle='->', color='#176B38', lw=1.5))

            ax.text(3.65, 7.45, 'sbyte_in_muxed[i]', fontsize=8.5, color='#176B38',
                    ha='center', fontfamily='monospace')
            ax.annotate('', xy=(5.2, 7.3), xytext=(4.1, 7.3),
                        arrowprops=dict(arrowstyle='->', color='#176B38', lw=2))

        # CFA S-Box block (~100 gates)
        ax.add_patch(FancyBboxPatch((5.2, 6.3), 3.0, 2.0,
                     boxstyle="round,pad=0.08",
                     facecolor='#B51919' if not is_after else '#176B38',
                     edgecolor='white', linewidth=2))
        ax.text(6.7, 7.75, 'CFA S-Box', ha='center', fontsize=11, color='white', fontweight='bold')
        ax.text(6.7, 7.35, '(aes_cfa_sbox)', ha='center', fontsize=9, color='#FFD0D0' if not is_after else '#B0E8B0')
        ax.text(6.7, 7.0, '~100 XOR/AND gates', ha='center', fontsize=9, color='white')
        ax.text(6.7, 6.65, 'GF((2⁴)²) tower field', ha='center', fontsize=8.5, color='#FFD0D0' if not is_after else '#B0E8B0')

        # Toggle annotation inside S-Box
        if not is_after:
            ax.text(6.7, 6.4, '⚡ ALL 100 GATES TOGGLE', ha='center', fontsize=9,
                    color='#FFD700', fontweight='bold')
        else:
            ax.text(6.7, 6.4, '🔒 STATIC (input=0x00=const)', ha='center', fontsize=9,
                    color='#FFD700', fontweight='bold')

        # Output arrow
        ax.annotate('', xy=(8.5, 7.3), xytext=(8.2, 7.3),
                    arrowprops=dict(arrowstyle='->', color='#5A6A7A', lw=1.5))
        ax.text(8.55, 7.3, 'SubBytes\nOutput', ha='left', fontsize=8.5, color='#5A6A7A')

        # Explanation box at bottom
        ax.add_patch(FancyBboxPatch((0.2, 0.2), 8.5, 2.5,
                     boxstyle="round,pad=0.1",
                     facecolor='#FDE8D0' if not is_after else '#D4EDDA',
                     edgecolor='#B51919' if not is_after else '#176B38', linewidth=1.5))
        if not is_after:
            ax.text(4.45, 2.5, 'Problem: Phase 5 gated the REGISTERS — but not the combinational fanin', ha='center',
                    fontsize=10.5, color='#B51919', fontweight='bold')
            ax.text(4.45, 2.1, 'State_Reg[i] is frozen by Phase 5 CE — but its Q output is still wired\n'
                    'directly to the CFA S-Box State_in port.', ha='center', fontsize=9.5, color='#1A1A2E')
            ax.text(4.45, 1.65, 'The ~100-gate CFA tree evaluates on every clock edge\n'
                    'with the STALE value of State_Reg[i] — all internal nodes toggle unnecessarily.', ha='center',
                    fontsize=9.5, color='#B51919')
            ax.text(4.45, 1.2, 'This is the dominant power waste in the pipeline — combinational GF logic\n'
                    'dissipates more power than the registers it feeds.', ha='center', fontsize=9, color='#5A6A7A')
        else:
            ax.text(4.45, 2.55, 'CG-03 Mux-gating: force 0x00 to CFA S-Box when stage is idle', ha='center',
                    fontsize=10.5, color='#176B38', fontweight='bold')
            ax.text(4.45, 2.15, 'assign sbyte_in_muxed[i] = Ready_Reg[i] ? State_Reg[i] : \'{default:\'0};',
                    ha='center', fontsize=9.5, color='#164E9C', fontfamily='monospace')
            ax.text(4.45, 1.75, 'When Ready_Reg[i]=0: input = 0x00 (constant)\n'
                    '→ CFA S-Box computes S(0x00)=0x63 every cycle → ALL internal nodes STATIC\n'
                    '→ Zero toggle activity across all ~100 gates', ha='center', fontsize=9.5, color='#176B38')
            ax.text(4.45, 1.2, 'This achieves the same effect as clock-gating the CFA logic,\n'
                    'without any ICG cells. Purely RTL, tool-agnostic, works on any FPGA.', ha='center',
                    fontsize=9, color='#5A6A7A')
            ax.text(4.45, 0.75, 'VCD evidence: toggle count on pipeline data signals = 0 during idle windows.',
                    ha='center', fontsize=9, color='#176B38', fontweight='bold')

    plt.tight_layout(pad=1.0)
    path = CHARTS / "p6_cg03_mux.png"
    plt.savefig(path, dpi=150, bbox_inches='tight', facecolor='#F4F6FA')
    plt.close()
    return path


def build_phase6():
    cg03 = make_cg03_mux_diagram()
    prs = new_prs()

    # ── SLIDE 6.1: CG-01 + CG-02 overview ────────────────────────────────────
    sl = blank_slide(prs)
    slide_chrome(sl, "PHASE 6", "Fine-Grained CE Gating — Three Sub-Techniques",
                 subtitle="CG-01: FSM State_N register  |  CG-02: kexp pipeline stages  |  CG-03: Mux-gating CFA S-Box inputs")

    callout_box(sl, "CG-01 — FSM State_N Register (aes_cipher_state.sv / aes_icipher_state.sv)",
                "Phase 2 gated the control struct r = {state, ready}.\n"
                "CG-01 gates State_N — the 128-bit DATA register holding the AES intermediate state.\n\n"
                "Why it was missed in Phase 2:\n"
                "  State_N is a separate always_ff block from r. Phase 2 targeted only the\n"
                "  control struct. State_N was left as a bare always_ff — toggling every cycle.\n\n"
                "CE condition (same as r guard):\n"
                "  CE = (r.state != IDLE) || (r.ready == 1) || (Enable == 1)\n\n"
                "Why ready term is critical:\n"
                "  State_N drives Data_out directly. It must hold the final result stable\n"
                "  through the cycle where ready is being cleared, or the consumer reads garbage.\n\n"
                "Impact: 128-bit register + downstream combo frozen at idle.",
                MARGIN_L, Inches(0.88), Inches(6.15), Inches(3.7),
                accent=NAVY, bg=LIGHT_BLU)

    callout_box(sl, "CG-02 — Key Expansion Pipeline (aes_kexp.sv)",
                "Key expansion runs as its own pipeline producing round keys.\n"
                "Before Phase 6: all stage registers completely ungated.\n\n"
                "CE pattern applied:\n"
                "  Stage 0:  CE = Enable || Ready_N[0]     ← seed + self-drain\n"
                "  Stage i:  CE = Ready_N[i-1]             ← upstream only\n\n"
                "Why no OR-flush for interior stages?\n"
                "  aes_kexp is a one-shot pipeline — once Enable fires, key data\n"
                "  propagates through all stages exactly once and stops.\n"
                "  No second wave arrives → self-drain term unnecessary.\n\n"
                "Why Stage 0 still needs OR:\n"
                "  Enable is a 1-cycle pulse. Ready_N[0] rises the cycle after.\n"
                "  Without OR, Stage 0 misses the leading edge of its own data.\n\n"
                "Key schedule is the longest-latency path — high-value gate.",
                Inches(6.6), Inches(0.88), Inches(6.28), Inches(3.7),
                accent=TEAL, bg=RGBColor(0xD8, 0xF0, 0xF4))

    headers = ["Sub-technique", "File", "Register(s) gated", "CE condition"]
    rows = [
        ["CG-01", "aes_cipher_state.sv",  "State_N (128-bit data)",     "state!=IDLE || ready || Enable"],
        ["CG-01", "aes_icipher_state.sv", "State_N (128-bit data)",     "state!=Nr || ready || Enable"],
        ["CG-02", "aes_kexp.sv",          "KExp_N[i] + Ready_N[i]",     "Stage 0: Enable||Ready_N[0]; Stage i: Ready_N[i-1]"],
        ["CG-03", "aes_cipher.sv",        "sbyte_in_muxed[i] (mux)",    "Ready_Reg[i] ? State_Reg[i] : 0"],
        ["CG-03", "aes_icipher.sv",       "isbyte_in_muxed[i] (mux)",   "Ready_Reg[i] ? State_Reg[i] : 0"],
    ]
    add_table(sl, headers, rows,
              MARGIN_L, Inches(4.78), Inches(12.43), Inches(2.0),
              header_size=10.5, row_size=10)
    footer(sl, "Phase 6 · 3 sub-techniques · 5 locations in 4 files",
           right_text="CG-03 is the dominant power saver: silences ~100-gate CFA tree at idle")

    # ── SLIDE 6.2: CG-03 block diagram ────────────────────────────────────────
    sl = blank_slide(prs)
    slide_chrome(sl, "PHASE 6 / CG-03", "Mux-Gating CFA S-Box Inputs — The Dominant Power Reduction",
                 subtitle="aes_cipher.sv · aes_icipher.sv  |  sbyte_in_muxed[i] / isbyte_in_muxed[i]  |  applied at all Nr round sites")
    add_img(sl, cg03, MARGIN_L, Inches(0.82), Inches(12.43), Inches(5.75))
    footer(sl, "Phase 6 / CG-03 · data-path mux before CFA S-Box",
           right_text="Constant 0x00 input → S(0x00)=0x63 every cycle → zero toggle across ~100 gates")

    # ── SLIDE 6.3: Results ─────────────────────────────────────────────────────
    sl = blank_slide(prs)
    slide_chrome(sl, "PHASE 6", "Phase 6 Results — Power and Toggle Count",
                 subtitle="Vivado report_power (SAIF) + Verilator VCD toggle analysis  |  AES-128  |  Artix-7 xc7a35t")

    callout_box(sl, "Dynamic Power (Vivado SAIF, AES-128 Pipeline)",
                "Stage               Baseline    Post FSM-CE    Post Full CE+Mux\n"
                "─────────────────────────────────────────────────────────────\n"
                "Clocks              0.042 W      0.036 W         0.030 W\n"
                "Signals             0.068 W      0.052 W         0.040 W\n"
                "Logic               0.095 W      0.074 W         0.060 W\n"
                "I/O                 0.012 W      0.012 W         0.012 W\n"
                "─────────────────────────────────────────────────────────────\n"
                "Total Dynamic       0.217 W      0.174 W         0.142 W\n"
                "Reduction                        −19.8%          −34.6%",
                MARGIN_L, Inches(0.88), Inches(7.55), Inches(3.55),
                accent=NAVY, bg=LIGHT_BLU, title_size=11, body_size=10.5)

    callout_box(sl, "Idle Toggle Analysis (Verilator VCD)",
                "Architecture    Idle Reg Toggles (Baseline)    Post Phase 5+6\n"
                "────────────────────────────────────────────────────────\n"
                "FSM                    0                             0\n"
                "Pipeline         101,035                             0   (−100%)\n\n"
                "Total DUT bit toggles:\n"
                "  939,018  →  50,449   (−94.6%)\n\n"
                "VCD confirms: during idle windows, pipeline data\n"
                "signals show ZERO transitions — exactly what\n"
                "the mux forcing 0x00 predicts.",
                Inches(8.0), Inches(0.88), Inches(4.88), Inches(3.55),
                accent=GREEN, bg=LIGHT_GRN)

    headers2 = ["Phase", "LUT Change", "FF Change", "Power Impact", "Mechanism"]
    rows2 = [
        ["Ph6/CG-01", "0", "0", "Part of −34.6% total", "State_N (128-bit) frozen at idle"],
        ["Ph6/CG-02", "0", "0", "Part of −34.6% total", "kexp pipeline stages gated"],
        ["Ph6/CG-03", "+small (mux logic)", "0", "Dominant contributor", "CFA ~100 gates go static: α→0"],
    ]
    add_table(sl, headers2, rows2,
              MARGIN_L, Inches(4.6), Inches(12.43), Inches(1.7),
              header_size=10.5, row_size=10)

    footer(sl, "Phase 6 results — full CE+mux: 0.217 W → 0.142 W  (−34.6%)",
           right_text="I/O power unchanged — driven by test stimulus, not internal enables")

    prs.save(str(OUT / "Phase6_Fine_Grained_CG.pptx"))
    print(f"  Phase6_Fine_Grained_CG.pptx  ({len(prs.slides)} slides)")


# ══════════════════════════════════════════════════════════════════════════════
# PHASE 7: Unified FSM
# ══════════════════════════════════════════════════════════════════════════════
def make_unified_fsm_diagram():
    fig, axes = plt.subplots(1, 2, figsize=(14, 6.2))
    fig.patch.set_facecolor('#F4F6FA')

    # ── LEFT: Before — two separate FSMs ─────────────────────────────────────
    ax = axes[0]
    ax.set_facecolor('#F4F6FA'); ax.axis('off')
    ax.set_xlim(0, 9); ax.set_ylim(0, 9)
    ax.set_title("BEFORE Phase 7 — Two Separate FSMs", fontsize=12, fontweight='bold', color='#B51919', pad=6)

    # Enc FSM
    ax.add_patch(FancyBboxPatch((0.3, 5.2), 3.8, 2.8,
                 boxstyle="round,pad=0.1", facecolor='#FDE8D0', edgecolor='#B51919', linewidth=2))
    ax.text(2.2, 7.75, 'aes_cipher_state.sv', ha='center', fontsize=10.5, color='#B51919', fontweight='bold')
    ax.text(2.2, 7.35, 'IDLE (state=0) → Rounds 1..Nr-1 → FINAL (Nr)', ha='center', fontsize=8.5, color='#1A1A2E')
    for si, (s, sx) in enumerate([('IDLE\n0', 0.7), ('Rnd\n1..Nr-1', 1.9), ('FINAL\nNr', 3.2)]):
        ax.add_patch(plt.Circle((sx, 6.3), 0.42, color='#B51919', zorder=3))
        ax.text(sx, 6.3, s, ha='center', va='center', fontsize=8, color='white', fontweight='bold', zorder=4)
        if si < 2:
            ax.annotate('', xy=(sx+0.6, 6.3), xytext=(sx+0.42, 6.3),
                        arrowprops=dict(arrowstyle='->', color='#5A6A7A', lw=1.3))
    ax.annotate('', xy=(0.85, 6.62), xytext=(3.05, 6.62),
                arrowprops=dict(arrowstyle='->', connectionstyle='arc3,rad=-0.4', color='#176B38', lw=1.3))
    ax.text(2.2, 5.55, 'aes_arkey — key index = round_r (forward)', ha='center', fontsize=8.5, color='#5A6A7A')
    ax.text(2.2, 5.3, '~200 lines  |  406 FFs', ha='center', fontsize=8.5, color='#B51919', fontweight='bold')

    # Dec FSM
    ax.add_patch(FancyBboxPatch((0.3, 2.0), 3.8, 2.8,
                 boxstyle="round,pad=0.1", facecolor='#FDE8D0', edgecolor='#B51919', linewidth=2))
    ax.text(2.2, 4.55, 'aes_icipher_state.sv', ha='center', fontsize=10.5, color='#B51919', fontweight='bold')
    ax.text(2.2, 4.15, 'IDLE (state=Nr) → Rounds Nr-1..1 → FINAL (0)', ha='center', fontsize=8.5, color='#1A1A2E')
    for si, (s, sx) in enumerate([('IDLE\nNr', 0.7), ('Rnd\nNr-1..1', 1.9), ('FINAL\n0', 3.2)]):
        ax.add_patch(plt.Circle((sx, 3.2), 0.42, color='#B51919', zorder=3))
        ax.text(sx, 3.2, s, ha='center', va='center', fontsize=8, color='white', fontweight='bold', zorder=4)
        if si < 2:
            ax.annotate('', xy=(sx+0.6, 3.2), xytext=(sx+0.42, 3.2),
                        arrowprops=dict(arrowstyle='->', color='#5A6A7A', lw=1.3))
    ax.annotate('', xy=(0.85, 3.52), xytext=(3.05, 3.52),
                arrowprops=dict(arrowstyle='->', connectionstyle='arc3,rad=0.4', color='#176B38', lw=1.3))
    ax.text(2.2, 2.45, 'aes_arkey — key index = Nr-round_r (reverse)', ha='center', fontsize=8.5, color='#5A6A7A')
    ax.text(2.2, 2.2, '~200 lines  |  406 FFs  (DUPLICATED!)', ha='center', fontsize=8.5, color='#B51919', fontweight='bold')

    # Two arkey instances
    for by3 in [6.0, 2.85]:
        ax.add_patch(FancyBboxPatch((4.5, by3), 2.0, 0.65,
                     boxstyle="round,pad=0.05", facecolor='#D45D00', edgecolor='white'))
        ax.text(5.5, by3+0.32, 'aes_arkey', ha='center', va='center', fontsize=9, color='white', fontweight='bold')
    ax.text(5.5, 5.45, '2 × aes_arkey\n(duplicated)', ha='center', fontsize=9, color='#D45D00', fontweight='bold')

    ax.add_patch(FancyBboxPatch((0.2, 0.3), 8.5, 1.5,
                 boxstyle="round,pad=0.08", facecolor='#FDE8D0', edgecolor='#B51919', linewidth=1.5))
    ax.text(4.45, 1.6, 'Total: ~400+ lines  |  ~812 FFs  |  2× aes_arkey', ha='center', fontsize=10, color='#B51919', fontweight='bold')
    ax.text(4.45, 1.2, 'IDLE ambiguity: enc IDLE=0 vs dec IDLE=Nr — checked separately in each FSM', ha='center', fontsize=9, color='#1A1A2E')
    ax.text(4.45, 0.8, 'Structurally identical control flow — only direction and key index differ', ha='center', fontsize=9, color='#5A6A7A')
    ax.text(4.45, 0.5, 'Hardware duplication: state registers, round counter, ready logic — all doubled', ha='center', fontsize=9, color='#B51919')

    # ── RIGHT: After — unified FSM ────────────────────────────────────────────
    ax2 = axes[1]
    ax2.set_facecolor('#F4F6FA'); ax2.axis('off')
    ax2.set_xlim(0, 9); ax2.set_ylim(0, 9)
    ax2.set_title("AFTER Phase 7 — Single Unified FSM", fontsize=12, fontweight='bold', color='#176B38', pad=6)

    # Unified FSM box
    ax2.add_patch(FancyBboxPatch((0.3, 2.5), 5.5, 5.8,
                 boxstyle="round,pad=0.12", facecolor='#D4EDDA', edgecolor='#176B38', linewidth=2.5))
    ax2.text(3.05, 8.1, 'aes_unified_state.sv', ha='center', fontsize=11.5, color='#176B38', fontweight='bold')
    ax2.text(3.05, 7.7, '(~186 lines)', ha='center', fontsize=9, color='#5A6A7A')

    # IDLE sentinel
    ax2.add_patch(plt.Circle((1.0, 6.8), 0.52, color='#164E9C', zorder=3))
    ax2.text(1.0, 6.8, "IDLE\n4'hF", ha='center', va='center', fontsize=8.5, color='white', fontweight='bold', zorder=4)

    # Enc path
    ax2.add_patch(plt.Circle((2.8, 7.5), 0.45, color='#007A87', zorder=3))
    ax2.text(2.8, 7.5, 'Enc\n1..Nr-1', ha='center', va='center', fontsize=8, color='white', fontweight='bold', zorder=4)
    ax2.add_patch(plt.Circle((4.6, 7.5), 0.45, color='#176B38', zorder=3))
    ax2.text(4.6, 7.5, 'Enc\nNr', ha='center', va='center', fontsize=8, color='white', fontweight='bold', zorder=4)

    # Dec path
    ax2.add_patch(plt.Circle((2.8, 6.0), 0.45, color='#007A87', zorder=3))
    ax2.text(2.8, 6.0, 'Dec\nNr-1..1', ha='center', va='center', fontsize=8, color='white', fontweight='bold', zorder=4)
    ax2.add_patch(plt.Circle((4.6, 6.0), 0.45, color='#176B38', zorder=3))
    ax2.text(4.6, 6.0, 'Dec\n0', ha='center', va='center', fontsize=8, color='white', fontweight='bold', zorder=4)

    # Transition arrows
    ax2.annotate('', xy=(2.4, 7.4), xytext=(1.4, 6.95),
                arrowprops=dict(arrowstyle='->', color='#007A87', lw=1.5))
    ax2.text(1.7, 7.35, 'Dir=0\n(enc)', fontsize=8, color='#007A87')
    ax2.annotate('', xy=(2.4, 6.1), xytext=(1.4, 6.55),
                arrowprops=dict(arrowstyle='->', color='#D45D00', lw=1.5))
    ax2.text(1.5, 6.15, 'Dir=1\n(dec)', fontsize=8, color='#D45D00')
    ax2.annotate('', xy=(4.15, 7.5), xytext=(3.25, 7.5),
                arrowprops=dict(arrowstyle='->', color='#5A6A7A', lw=1.3))
    ax2.annotate('', xy=(4.15, 6.0), xytext=(3.25, 6.0),
                arrowprops=dict(arrowstyle='->', color='#5A6A7A', lw=1.3))
    ax2.annotate('', xy=(1.15, 7.05), xytext=(4.55, 7.1),
                arrowprops=dict(arrowstyle='->', connectionstyle='arc3,rad=-0.5', color='#176B38', lw=1.3))
    ax2.annotate('', xy=(1.15, 6.52), xytext=(4.55, 5.9),
                arrowprops=dict(arrowstyle='->', connectionstyle='arc3,rad=0.5', color='#176B38', lw=1.3))

    # Direction register
    ax2.add_patch(FancyBboxPatch((0.5, 4.9), 4.8, 0.85,
                 boxstyle="round,pad=0.06", facecolor='#164E9C', edgecolor='white', linewidth=1.5))
    ax2.text(2.9, 5.32, 'direction_r  (1-bit)  — latched at Enable assertion', ha='center', fontsize=9.5,
             color='white', fontweight='bold', fontfamily='monospace')

    # Key index mux
    ax2.add_patch(FancyBboxPatch((0.5, 3.85), 4.8, 0.85,
                 boxstyle="round,pad=0.06", facecolor='#007A87', edgecolor='white', linewidth=1.5))
    ax2.text(2.9, 4.27, 'Index = direction_r ? (Nr - round_r) : round_r', ha='center',
             fontsize=10, color='white', fontweight='bold', fontfamily='monospace')

    # IDLE sentinel explanation
    ax2.add_patch(FancyBboxPatch((0.5, 2.68), 4.8, 1.0,
                 boxstyle="round,pad=0.06", facecolor='#EAF0F8', edgecolor='#164E9C', linewidth=1.2))
    ax2.text(2.9, 3.42, "IDLE = 4'hF (all-ones sentinel)", ha='center', fontsize=9.5, color='#164E9C', fontweight='bold')
    ax2.text(2.9, 3.12, "Outside [0..Nr] range → simple compare, no complex decode", ha='center', fontsize=9, color='#1A1A2E')
    ax2.text(2.9, 2.82, "Eliminates enc-IDLE=0 vs dec-IDLE=Nr ambiguity from baseline", ha='center', fontsize=9, color='#5A6A7A')

    # Single arkey
    ax2.add_patch(FancyBboxPatch((6.0, 5.5), 2.3, 0.7,
                 boxstyle="round,pad=0.06", facecolor='#176B38', edgecolor='white'))
    ax2.text(7.15, 5.85, '1× aes_arkey\n(shared)', ha='center', va='center', fontsize=9, color='white', fontweight='bold')

    ax2.add_patch(FancyBboxPatch((0.2, 0.2), 8.5, 2.1,
                 boxstyle="round,pad=0.08", facecolor='#D4EDDA', edgecolor='#176B38', linewidth=1.5))
    ax2.text(4.45, 2.1, 'Results (AES-128, Yosys):', ha='center', fontsize=10.5, color='#176B38', fontweight='bold')
    ax2.text(4.45, 1.72, 'LUT:  17,467 → 15,621   (−10.6%)    |    FF: 406 → 274   (−32.5%)', ha='center',
             fontsize=10, color='#176B38', fontweight='bold', fontfamily='monospace')
    ax2.text(4.45, 1.32, 'Cumulative from baseline: 184,918 → 15,621   (−91.6%)', ha='center',
             fontsize=10.5, color='#0A234F', fontweight='bold')
    ax2.text(4.45, 0.9, 'Vivado AES-128 shows LUT rise (3,185→4,094) — direction-select mux artefact', ha='center',
             fontsize=9, color='#D45D00')
    ax2.text(4.45, 0.55, 'Yosys confirms structural reduction is real', ha='center',
             fontsize=9, color='#5A6A7A')

    plt.tight_layout(pad=1.0)
    path = CHARTS / "p7_unified_fsm.png"
    plt.savefig(path, dpi=150, bbox_inches='tight', facecolor='#F4F6FA')
    plt.close()
    return path


def build_phase7():
    diag = make_unified_fsm_diagram()
    prs = new_prs()

    sl = blank_slide(prs)
    slide_chrome(sl, "PHASE 7", "Unified Enc/Dec FSM — Two FSMs Merged into One",
                 subtitle="aes_cipher_state.sv + aes_icipher_state.sv → aes_unified_state.sv  |  direction_r register + Index mux")
    add_img(sl, diag, MARGIN_L, Inches(0.82), Inches(12.43), Inches(5.75))
    footer(sl, "Phase 7 · aes_unified_state.sv · ~186 lines · 1× aes_arkey",
           right_text="Yosys AES-128: 17,467→15,621 LUTs (−10.6%) · 406→274 FFs (−32.5%)")

    sl = blank_slide(prs)
    slide_chrome(sl, "PHASE 7", "Phase 7 — Design Rationale & Correctness",
                 subtitle="IDLE sentinel choice · direction_r sampling · Vivado mapper artefact explained")

    y = Inches(0.88)
    callout_box(sl, "Why IDLE = 4'hF (all-ones)?",
                "Baseline encode:\n"
                "  Encrypt FSM:  IDLE = state 0   (start of round counter)\n"
                "  Decrypt FSM:  IDLE = state Nr  (end of reverse counter)\n"
                "  Problem: enc-IDLE and dec-IDLE overlap with valid round indices!\n\n"
                "Unified sentinel 4'hF = 0b1111:\n"
                "  Outside normal round range [0..14] for all key sizes (max Nr=14)\n"
                "  → Single comparison: r.state == 4'hF   for IDLE check\n"
                "  → No ambiguity between enc idle, dec idle, and active rounds\n\n"
                "CE guard updated:\n"
                "  CE = (r.state != 4'hF) || (r.ready == 1) || (Enable == 1)",
                MARGIN_L, y, Inches(6.15), Inches(3.7),
                accent=NAVY, bg=LIGHT_BLU)

    callout_box(sl, "direction_r Sampling + Vivado Artefact",
                "direction_r register:\n"
                "  Separate always_ff block — NOT covered by the r struct CE guard.\n"
                "  Only updates on Enable assertion (1-cycle pulse).\n"
                "  This prevents it from being frozen incorrectly by the CE guard\n"
                "  while an operation is in progress.\n\n"
                "Key index mux (shared aes_arkey):\n"
                "  assign Index = direction_r ? (Nr[3:0] - round_r) : round_r;\n"
                "  Correct reverse key-schedule traversal for decrypt — no ROM.\n\n"
                "Vivado LUT increase (AES-128: 3,185→4,094):\n"
                "  Direction-select mux at datapath top adds routing → extra LUTs\n"
                "  in Vivado's technology mapper. This is a mapper artefact.\n"
                "  Yosys confirms −10.6% structural reduction. FF count falls in\n"
                "  both tools: real register consolidation from merging two modules.",
                Inches(6.6), y, Inches(6.28), Inches(3.7),
                accent=TEAL, bg=RGBColor(0xD8, 0xF0, 0xF4))

    headers = ["Metric", "Before (2 FSMs)", "After (unified)", "Delta"]
    rows = [
        ["LUT (Yosys AES-128)",    "17,467",  "15,621", "−10.6%"],
        ["FF (Yosys AES-128)",     "406",     "274",    "−32.5%"],
        ["LUT (Vivado AES-128)",   "3,185",   "4,094",  "+28.5% (mapper artefact — direction mux)"],
        ["aes_arkey instances",    "2 (one per FSM)", "1 (shared)", "50% reduction in key logic"],
        ["Lines of code",          "~400+ (two files)", "~186 (one file)", "Significant structural simplification"],
        ["Cumulative LUT (Yosys)", "—",       "15,621 from 184,918", "−91.6% total from baseline"],
    ]
    add_table(sl, headers, rows,
              MARGIN_L, Inches(4.75), Inches(12.43), Inches(2.0),
              header_size=10.5, row_size=10)

    footer(sl, "Phase 7 results · cumulative −91.6% LUT (AES-128 FSM, Yosys)",
           right_text="Vivado FF count also falls — register consolidation is real in both tools")

    prs.save(str(OUT / "Phase7_Unified_FSM.pptx"))
    print(f"  Phase7_Unified_FSM.pptx  ({len(prs.slides)} slides)")


if __name__ == "__main__":
    build_phase5()
    build_phase6()
    build_phase7()
