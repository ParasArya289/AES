"""
phase1_slides.py  —  Phase 1: xtime Arithmetic & Table Elimination
3 slides:
  S1.1 — What Changed & Why (block diagram: where EXP3/LN3 lived, what replaced them)
  S1.2 — Theory: GF(2^8) xtime derivation + coefficient table
  S1.3 — Results: LUT reduction tables + synthesis comparison
"""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from slide_engine import *
import matplotlib; matplotlib.use('Agg')
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
from matplotlib.patches import FancyBboxPatch, FancyArrowPatch
import matplotlib.patheffects as pe
import numpy as np
from pathlib import Path

ROOT   = Path(__file__).parent.parent
FIGS   = ROOT / "Thesis_report" / "figs"
CHARTS = ROOT / "docs" / "charts"
OUT    = ROOT / "phase_slides"
OUT.mkdir(exist_ok=True)


# ─────────────────────────────────────────────────────────────────────────────
# Helper: draw the AES datapath diagram showing WHERE the change happened
# ─────────────────────────────────────────────────────────────────────────────
def make_phase1_block_diagram():
    fig, axes = plt.subplots(1, 2, figsize=(14, 6.5))
    fig.patch.set_facecolor('#F4F6FA')

    for ax, title, is_after in zip(axes, ["BEFORE  (Baseline)", "AFTER  (Phase 1)"], [False, True]):
        ax.set_facecolor('#F4F6FA')
        ax.set_xlim(0, 10); ax.set_ylim(0, 10)
        ax.axis('off')
        ax.set_title(title, fontsize=14, fontweight='bold',
                     color='#B51919' if not is_after else '#176B38', pad=8)

        # AES round pipeline stages (simplified)
        stage_color = '#164E9C'
        for i, lbl in enumerate(['Round\nInput', 'SubBytes\n(SBox)', 'ShiftRows', 'MixColumns\n+ ARK', 'Round\nOutput']):
            bx, by = 1.0 + i*1.7, 5.5
            bw, bh = 1.35, 1.1
            ax.add_patch(FancyBboxPatch((bx, by), bw, bh,
                         boxstyle="round,pad=0.05",
                         facecolor=stage_color, edgecolor='white', linewidth=1.5))
            ax.text(bx + bw/2, by + bh/2, lbl, ha='center', va='center',
                    fontsize=8.5, color='white', fontweight='bold')
            if i < 4:
                ax.annotate('', xy=(bx + bw + 0.08, by + bh/2),
                            xytext=(bx + bw, by + bh/2),
                            arrowprops=dict(arrowstyle='->', color='#5A6A7A', lw=1.5))

        # Highlight MixColumns block
        mc_x, mc_y = 1.0 + 3*1.7, 5.5
        mc_w, mc_h = 1.35, 1.1
        ax.add_patch(FancyBboxPatch((mc_x, mc_y), mc_w, mc_h,
                     boxstyle="round,pad=0.05",
                     facecolor='#D45D00' if not is_after else '#176B38',
                     edgecolor='white', linewidth=2.5, zorder=3))
        ax.text(mc_x + mc_w/2, mc_y + mc_h/2, 'MixColumns\n+ ARK',
                ha='center', va='center', fontsize=8.5, color='white', fontweight='bold', zorder=4)

        # ROM boxes (before) or removed (after)
        if not is_after:
            # EXP3 ROM
            ax.add_patch(FancyBboxPatch((4.3, 3.2), 1.1, 0.8,
                         boxstyle="round,pad=0.05",
                         facecolor='#B51919', edgecolor='#800000', linewidth=1.5))
            ax.text(4.85, 3.6, 'EXP3[ ]\n256 entries', ha='center', va='center',
                    fontsize=8, color='white', fontweight='bold')
            # LN3 ROM
            ax.add_patch(FancyBboxPatch((5.65, 3.2), 1.1, 0.8,
                         boxstyle="round,pad=0.05",
                         facecolor='#B51919', edgecolor='#800000', linewidth=1.5))
            ax.text(6.2, 3.6, 'LN3[ ]\n256 entries', ha='center', va='center',
                    fontsize=8, color='white', fontweight='bold')
            # arrow from MC down to ROMs
            ax.annotate('', xy=(4.85, 4.0), xytext=(5.5, 5.5),
                        arrowprops=dict(arrowstyle='->', color='#B51919', lw=1.5))
            ax.annotate('', xy=(6.2, 4.0), xytext=(5.8, 5.5),
                        arrowprops=dict(arrowstyle='->', color='#B51919', lw=1.5))
            ax.text(5.5, 2.7, 'gmul(a,c) = EXP3[(LN3[a]+LN3[c]) mod 255]',
                    ha='center', va='center', fontsize=8.5,
                    color='#B51919', fontweight='bold',
                    bbox=dict(boxstyle='round,pad=0.3', facecolor='#FDE8D0', edgecolor='#B51919'))
            ax.text(5.5, 2.1, 'aes_array.sv: 512 table entries\naccessed every round cycle',
                    ha='center', va='center', fontsize=8,
                    color='#5A6A7A')
        else:
            # xtime logic box
            ax.add_patch(FancyBboxPatch((4.5, 3.0), 2.0, 1.2,
                         boxstyle="round,pad=0.05",
                         facecolor='#176B38', edgecolor='#0D4520', linewidth=1.5))
            ax.text(5.5, 3.6, 'xtime(a)\n(a<<1) XOR (a[7]?0x1B:0)',
                    ha='center', va='center', fontsize=8.5,
                    color='white', fontweight='bold')
            ax.annotate('', xy=(5.5, 4.2), xytext=(5.5, 5.5),
                        arrowprops=dict(arrowstyle='->', color='#176B38', lw=1.5))
            ax.text(5.5, 2.5, 'Pure combinational shift + XOR\n'
                    'aes_array.sv: DELETED\nEXP3/LN3 ports: REMOVED from 10 modules',
                    ha='center', va='center', fontsize=8.5,
                    color='#176B38', fontweight='bold',
                    bbox=dict(boxstyle='round,pad=0.3', facecolor='#D4EDDA', edgecolor='#176B38'))

        # InvMixColumns box (also affected)
        ax.add_patch(FancyBboxPatch((1.0, 7.2), 8.7, 0.7,
                     boxstyle="round,pad=0.04",
                     facecolor='#E8F0FE' if is_after else '#FDE8D0',
                     edgecolor='#164E9C' if is_after else '#D45D00', linewidth=1))
        ax.text(5.35, 7.55,
                'InvMixColumns (decryption path) — same change applied: xt4, xt8 chains'
                if is_after else
                'InvMixColumns (decryption path) — same EXP3/LN3 tables used',
                ha='center', va='center', fontsize=8.5,
                color='#164E9C' if is_after else '#D45D00')

        # Architecture labels
        ax.text(5.0, 9.4, 'Both FSM and Pipeline architectures affected',
                ha='center', va='center', fontsize=9, color='#5A6A7A', style='italic')

    plt.tight_layout(pad=1.5)
    path = CHARTS / "p1_block_diagram.png"
    plt.savefig(path, dpi=150, bbox_inches='tight', facecolor='#F4F6FA')
    plt.close()
    return path


def make_xtime_theory_diagram():
    fig, ax = plt.subplots(figsize=(13, 6.5))
    fig.patch.set_facecolor('#F4F6FA')
    ax.set_facecolor('#F4F6FA')
    ax.axis('off')
    ax.set_xlim(0, 13); ax.set_ylim(0, 7)

    # Title
    ax.text(6.5, 6.6, 'GF(2⁸) Multiplication: xtime Derivation',
            ha='center', va='center', fontsize=15, fontweight='bold', color='#0A234F')

    # Left column: xtime formula derivation
    left_content = [
        (0.3, 5.9, 14, 'Step 1: Multiply by x in GF(2⁸)', '#0A234F', 12, True),
        (0.3, 5.35, 12, 'Polynomial representation: a(x) = a₇x⁷ + a₆x⁶ + ⋯ + a₀', '#1A1A2E', 11, False),
        (0.3, 4.85, 12, 'a·x = a₇x⁸ + a₆x⁷ + ⋯ + a₀x  (shift left)', '#1A1A2E', 11, False),
        (0.3, 4.35, 12, 'Reduction modulo p(x) = x⁸+x⁴+x³+x+1:', '#1A1A2E', 11, False),
        (0.3, 3.7, 12.4, '  if a₇=1:  (a<<1) XOR 0x1B     [0x1B = 00011011 = x⁴+x³+x+1]', '#176B38', 11, True),
        (0.3, 3.2, 12.4, '  if a₇=0:  (a<<1)             [no reduction needed]', '#176B38', 11, True),
    ]
    for x, y, w, text, color, size, bold in left_content:
        ax.text(x, y, text, fontsize=size, color=color, fontweight='bold' if bold else 'normal',
                fontfamily='monospace' if '0x' in text or '<<' in text else 'sans-serif')

    # xtime formula box
    ax.add_patch(FancyBboxPatch((0.2, 2.55), 6.1, 0.55,
                 boxstyle="round,pad=0.08",
                 facecolor='#D8E8F8', edgecolor='#164E9C', linewidth=2))
    ax.text(3.25, 2.82,
            'xtime(a)  =  (a « 1)  XOR  ( a[7] ? 0x1B : 0x00 )',
            ha='center', va='center', fontsize=11,
            color='#164E9C', fontweight='bold', fontfamily='monospace')

    # Step 2: higher multiples
    ax.text(0.3, 2.1, 'Step 2: Higher Coefficients (MixColumns matrix {1,2,3} and InvMixColumns {9,11,13,14})',
            fontsize=12, color='#0A234F', fontweight='bold')

    # Coefficient table
    col_headers = ['Coeff', 'Derivation', 'Operations']
    col_data = [
        ('x1',  'a',                       '0 XOR gates'),
        ('x2',  'xtime(a)',                 '1 shift + 1 XOR'),
        ('x3',  'xtime(a) XOR a',           '1 shift + 2 XOR'),
        ('x4',  'xtime(xtime(a))',           '2 shifts + 2 XOR'),
        ('x8',  'xtime(xtime(xtime(a)))',    '3 shifts + 3 XOR'),
        ('x9',  'xt8 XOR a',                '3 shifts + 4 XOR'),
        ('x11', 'xt8 XOR xt2 XOR a',        '4 shifts + 5 XOR'),
        ('x13', 'xt8 XOR xt4 XOR a',        '4 shifts + 5 XOR'),
        ('x14', 'xt8 XOR xt4 XOR xt2',      '4 shifts + 5 XOR'),
    ]

    # Draw mini table
    tx = 0.2; ty = 0.2; tw = 6.2; th = 1.75
    col_widths = [0.6, 3.0, 2.6]
    # header
    cx = tx
    for hdr, cw in zip(col_headers, col_widths):
        ax.add_patch(FancyBboxPatch((cx, ty+th-0.22), cw-0.02, 0.22,
                     boxstyle="square,pad=0", facecolor='#0A234F', edgecolor='white', linewidth=0))
        ax.text(cx + cw/2, ty+th-0.11, hdr, ha='center', va='center',
                fontsize=9, color='white', fontweight='bold')
        cx += cw
    # rows
    for ri, (c, deriv, ops) in enumerate(col_data):
        row_y = ty + th - 0.22 - (ri+1)*0.185
        fill = '#EAF0F8' if ri % 2 == 0 else 'white'
        row_data = [c, deriv, ops]
        cx = tx
        for ci, (val, cw) in enumerate(zip(row_data, col_widths)):
            ax.add_patch(FancyBboxPatch((cx, row_y), cw-0.02, 0.185,
                         boxstyle="square,pad=0", facecolor=fill, edgecolor='#CCD5DF', linewidth=0.5))
            ax.text(cx + cw/2 if ci > 0 else cx+0.08, row_y+0.09, val,
                    ha='center' if ci > 0 else 'left', va='center',
                    fontsize=8.5, color='#1A1A2E',
                    fontfamily='monospace' if 'xt' in val or 'XOR' in val else 'sans-serif')
            cx += cw

    # Right: comparison — ROM vs xtime
    rx = 6.8
    ax.text(rx + 1.8, 6.5, 'Table-based vs xtime: Key Differences',
            ha='center', fontsize=12, color='#0A234F', fontweight='bold')

    # ROM box
    ax.add_patch(FancyBboxPatch((rx, 5.2), 3.0, 1.15,
                 boxstyle="round,pad=0.1",
                 facecolor='#FDE8D0', edgecolor='#B51919', linewidth=2))
    ax.text(rx+0.15, 6.15, '✘  ROM-based (Baseline)', fontsize=10, color='#B51919', fontweight='bold')
    ax.text(rx+0.15, 5.85, 'gmul(a,c) = EXP3[(LN3[a]+LN3[c]) mod 255]',
            fontsize=9.5, color='#1A1A2E', fontfamily='monospace')
    ax.text(rx+0.15, 5.55, '  • Requires 2 ROM lookups per multiply', fontsize=9, color='#5A6A7A')
    ax.text(rx+0.15, 5.3, '  • 512 entries → LUT RAM / BRAM on FPGA', fontsize=9, color='#5A6A7A')

    # xtime box
    ax.add_patch(FancyBboxPatch((rx, 3.85), 3.0, 1.2,
                 boxstyle="round,pad=0.1",
                 facecolor='#D4EDDA', edgecolor='#176B38', linewidth=2))
    ax.text(rx+0.15, 4.87, '✔  xtime (Phase 1)', fontsize=10, color='#176B38', fontweight='bold')
    ax.text(rx+0.15, 4.57, 'x2=xtime(a),  x3=xtime(a) XOR a',
            fontsize=9.5, color='#1A1A2E', fontfamily='monospace')
    ax.text(rx+0.15, 4.27, '  • Pure shift-and-XOR gates', fontsize=9, color='#5A6A7A')
    ax.text(rx+0.15, 4.0, '  • 0 ROM entries → fast combinational LUTs', fontsize=9, color='#5A6A7A')

    # Equivalence proof note
    ax.add_patch(FancyBboxPatch((rx, 2.9), 3.0, 0.75,
                 boxstyle="round,pad=0.1",
                 facecolor='#D8E8F8', edgecolor='#007A87', linewidth=1.5))
    ax.text(rx+0.15, 3.45, 'Semantic preservation:', fontsize=9.5, color='#007A87', fontweight='bold')
    ax.text(rx+0.15, 3.2, 'Both compute identical GF(2⁸) results.', fontsize=9, color='#1A1A2E')
    ax.text(rx+0.15, 2.97, 'xtime provably correct for all 256 inputs.', fontsize=9, color='#1A1A2E')

    # Which modules changed
    ax.add_patch(FancyBboxPatch((rx, 1.65), 3.0, 1.1,
                 boxstyle="round,pad=0.1",
                 facecolor='#F4F6FA', edgecolor='#5A6A7A', linewidth=1))
    ax.text(rx+0.15, 2.57, 'Files Modified (Phase 1):', fontsize=9.5, color='#0A234F', fontweight='bold')
    for yi, fn in enumerate(['aes_mcol.sv', 'aes_imcol.sv', 'aes_array.sv  (DELETED)']):
        col = '#B51919' if 'DELETED' in fn else '#176B38'
        ax.text(rx+0.25, 2.3 - yi*0.25, '• ' + fn, fontsize=9,
                color=col, fontfamily='monospace')

    ax.text(rx+0.15, 1.3, 'Port stubs removed from 10 modules', fontsize=9, color='#5A6A7A')

    plt.tight_layout(pad=0.5)
    path = CHARTS / "p1_xtime_theory.png"
    plt.savefig(path, dpi=150, bbox_inches='tight', facecolor='#F4F6FA')
    plt.close()
    return path


def make_phase1_results_chart():
    fig, axes = plt.subplots(1, 2, figsize=(13, 5.5))
    fig.patch.set_facecolor('#F4F6FA')

    # Chart 1: Yosys FSM LUT reduction
    ax = axes[0]
    ax.set_facecolor('#F4F6FA')
    ax.spines['top'].set_visible(False); ax.spines['right'].set_visible(False)
    ax.spines['left'].set_color('#CCD5DF'); ax.spines['bottom'].set_color('#CCD5DF')

    labels = ['AES-128', 'AES-192', 'AES-256']
    baseline = [184918, 193131, 202490]
    after    = [ 42181,  49381,  59710]
    x = np.arange(3); w = 0.35
    b1 = ax.bar(x - w/2, baseline, w, color='#B51919', label='Baseline', edgecolor='white', linewidth=1.5)
    b2 = ax.bar(x + w/2, after,    w, color='#176B38', label='After xtime', edgecolor='white', linewidth=1.5)

    for bar, val, pct in zip(b2, after, [77.2, 74.4, 70.5]):
        ax.text(bar.get_x()+bar.get_width()/2, bar.get_height()+2000,
                f'−{pct:.0f}%', ha='center', va='bottom',
                fontsize=10.5, fontweight='bold', color='#176B38')

    ax.set_xticks(x); ax.set_xticklabels(labels, fontsize=11)
    ax.set_ylabel('Yosys LUT Count', fontsize=11, color='#0A234F')
    ax.set_title('FSM Architecture — Yosys LUT\n(Phase 1: xtime + Table Removal)',
                 fontsize=11.5, fontweight='bold', color='#0A234F')
    ax.legend(frameon=False, fontsize=10)
    ax.set_ylim(0, 240000)
    ax.yaxis.set_major_formatter(plt.FuncFormatter(lambda v,_: f'{int(v):,}'))
    ax.yaxis.grid(True, color='#E2E8F0', linewidth=0.7, zorder=0); ax.set_axisbelow(True)

    # Chart 2: Vivado FSM LUT reduction
    ax2 = axes[1]
    ax2.set_facecolor('#F4F6FA')
    ax2.spines['top'].set_visible(False); ax2.spines['right'].set_visible(False)
    ax2.spines['left'].set_color('#CCD5DF'); ax2.spines['bottom'].set_color('#CCD5DF')

    v_baseline = [13268, 19896, 13938]
    v_after    = [ 5486, 12233,  6448]
    b3 = ax2.bar(x - w/2, v_baseline, w, color='#B51919', label='Baseline', edgecolor='white', linewidth=1.5)
    b4 = ax2.bar(x + w/2, v_after,    w, color='#007A87', label='After xtime', edgecolor='white', linewidth=1.5)

    for bar, val, pct in zip(b4, v_after, [58.6, 38.5, 53.7]):
        ax2.text(bar.get_x()+bar.get_width()/2, bar.get_height()+150,
                 f'−{pct:.0f}%', ha='center', va='bottom',
                 fontsize=10.5, fontweight='bold', color='#007A87')

    ax2.set_xticks(x); ax2.set_xticklabels(labels, fontsize=11)
    ax2.set_ylabel('Vivado Slice LUTs', fontsize=11, color='#0A234F')
    ax2.set_title('FSM Architecture — Vivado LUT\n(Artix-7 xc7a35t, Phase 1)',
                  fontsize=11.5, fontweight='bold', color='#0A234F')
    ax2.legend(frameon=False, fontsize=10)
    ax2.set_ylim(0, 25000)
    ax2.yaxis.set_major_formatter(plt.FuncFormatter(lambda v,_: f'{int(v):,}'))
    ax2.yaxis.grid(True, color='#E2E8F0', linewidth=0.7, zorder=0); ax2.set_axisbelow(True)

    plt.tight_layout(pad=1.5)
    path = CHARTS / "p1_results.png"
    plt.savefig(path, dpi=150, bbox_inches='tight', facecolor='#F4F6FA')
    plt.close()
    return path


# ─────────────────────────────────────────────────────────────────────────────
# Build slides
# ─────────────────────────────────────────────────────────────────────────────
def build():
    diag_path    = make_phase1_block_diagram()
    theory_path  = make_xtime_theory_diagram()
    results_path = make_phase1_results_chart()

    prs = new_prs()

    # ── SLIDE 1.1: What Changed & Architecture Diagram ────────────────────────
    sl = blank_slide(prs)
    slide_chrome(sl, "PHASE 1", "xtime Arithmetic & Table Elimination — What Changed",
                 subtitle="Target: MixColumns / InvMixColumns in both FSM and Pipeline architectures")

    add_img(sl, diag_path, MARGIN_L, Inches(0.85), Inches(12.43), Inches(5.65))
    footer(sl, "Phase 1 · aes_mcol.sv · aes_imcol.sv · aes_array.sv deleted",
           right_text="Yosys AES-128 FSM: 184,918 → 42,181 LUTs  (−77.2%)")

    # ── SLIDE 1.2: Theory ─────────────────────────────────────────────────────
    sl = blank_slide(prs)
    slide_chrome(sl, "PHASE 1", "xtime Theory: GF(2⁸) Multiplication by Shift-and-XOR",
                 subtitle="GF(2⁸) with reduction polynomial p(x) = x⁸ + x⁴ + x³ + x + 1  [hex: 0x11B]")

    add_img(sl, theory_path, MARGIN_L, Inches(0.85), Inches(12.43), Inches(5.65))
    footer(sl, "Phase 1 — xtime theory",
           right_text="Exhaustively equivalent to EXP3/LN3 table lookup for all 256 GF(2⁸) inputs")

    # ── SLIDE 1.3: Results ────────────────────────────────────────────────────
    sl = blank_slide(prs)
    slide_chrome(sl, "PHASE 1", "Phase 1 Results — LUT Reduction: Yosys & Vivado",
                 subtitle="Measured post-synthesis on Yosys 0.64 (synth_xilinx -family xc7) and Vivado 2023.2 (Artix-7 xc7a35t)")

    add_img(sl, results_path, MARGIN_L, Inches(0.82), Inches(9.2), Inches(4.55))

    # Side panel: key numbers
    callout_box(sl, "Key Results",
                "Yosys FSM AES-128\n  184,918 → 42,181  (−77.2%)\n\n"
                "Yosys FSM AES-192\n  193,131 → 49,381  (−74.4%)\n\n"
                "Yosys FSM AES-256\n  202,490 → 59,710  (−70.5%)\n\n"
                "Vivado FSM AES-128\n  13,268 → 5,486  (−58.6%)\n\n"
                "Pipeline AES-128 (Vivado)\n  91,467 → 21,816  (−76.2%)",
                Inches(9.8), Inches(0.85), Inches(3.1), Inches(4.55),
                accent=NAVY, bg=LIGHT_BLU)

    # Notes table
    headers = ["Observation", "Explanation"]
    rows = [
        ["Yosys shows larger absolute LUT counts than Vivado",
         "Yosys estimates pre-placement; Vivado packs after P&R"],
        ["Pipeline xtime reduction matches FSM percentage",
         "Same gmul used in every pipeline stage; all benefit equally"],
        ["No FF count change",
         "xtime removes ROM, not registers; state remains identical"],
    ]
    add_table(sl, headers, rows,
              MARGIN_L, Inches(5.55), Inches(12.43), Inches(1.7),
              header_size=10, row_size=9.5)

    footer(sl, "Phase 1 results — Yosys + Vivado synthesis",
           right_text="Largest single LUT step in the 7-phase sequence")

    prs.save(str(OUT / "Phase1_xtime.pptx"))
    print(f"  Phase1_xtime.pptx  ({len(prs.slides)} slides)")

if __name__ == "__main__":
    build()
