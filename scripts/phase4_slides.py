"""
Phase 4: CFA S-Box (Composite Field Arithmetic)
3 slides:
  S4.1 — What Changed: ROM → combinational logic, block diagram
  S4.2 — Theory: tower-field decomposition, GF(2^4) inversion chain
  S4.3 — Results: LUT tables, LUTRAM elimination
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


def make_cfa_block_diagram():
    fig, axes = plt.subplots(1, 2, figsize=(14, 6.5))
    fig.patch.set_facecolor('#F4F6FA')

    for ax, title, is_after in zip(axes, ["BEFORE  (Phase 3 Baseline)", "AFTER  (Phase 4 — CFA S-Box)"], [False, True]):
        ax.set_facecolor('#F4F6FA'); ax.axis('off')
        ax.set_xlim(0, 9); ax.set_ylim(0, 10)
        ax.set_title(title, fontsize=12.5, fontweight='bold',
                     color='#B51919' if not is_after else '#176B38', pad=6)

        # AES datapath (simplified round)
        round_blocks = ['AddRoundKey', 'SubBytes\n(x16)', 'ShiftRows', 'MixColumns']
        for i, blk in enumerate(round_blocks):
            bx, by = 0.4, 8.5 - i*1.6
            bw, bh = 3.0, 1.1
            highlight = (i == 1)  # SubBytes
            fc = '#B51919' if (highlight and not is_after) else \
                 '#176B38' if (highlight and is_after) else '#164E9C'
            lw = 2.5 if highlight else 1.5
            ax.add_patch(FancyBboxPatch((bx, by), bw, bh,
                         boxstyle="round,pad=0.06",
                         facecolor=fc, edgecolor='white', linewidth=lw))
            ax.text(bx+bw/2, by+bh/2, blk, ha='center', va='center',
                    fontsize=9.5, color='white', fontweight='bold')
            if i < 3:
                ax.annotate('', xy=(bx+bw/2, by-0.12), xytext=(bx+bw/2, by),
                            arrowprops=dict(arrowstyle='->', color='#5A6A7A', lw=1.5))

        # Key Schedule on right
        ax.add_patch(FancyBboxPatch((4.5, 6.0), 2.5, 1.1,
                     boxstyle="round,pad=0.06", facecolor='#5A6A7A', edgecolor='white', linewidth=1.5))
        ax.text(5.75, 6.55, 'Key Schedule\n(SubWord)', ha='center', va='center',
                fontsize=9, color='white', fontweight='bold')
        ax.annotate('', xy=(3.4, 8.4), xytext=(4.5, 6.55),
                    arrowprops=dict(arrowstyle='->', color='#5A6A7A', lw=1.2, linestyle='dashed'))

        # SubBytes implementation detail
        if not is_after:
            # ROM box
            ax.add_patch(FancyBboxPatch((3.8, 7.0), 4.8, 2.8,
                         boxstyle="round,pad=0.1", facecolor='#FDE8D0', edgecolor='#B51919', linewidth=2))
            ax.text(6.2, 9.6, 'SubBytes Implementation', ha='center', fontsize=10.5,
                    color='#B51919', fontweight='bold')
            ax.add_patch(FancyBboxPatch((4.0, 8.1), 2.1, 1.4,
                         boxstyle="round,pad=0.06", facecolor='#B51919', edgecolor='#800000', linewidth=1.5))
            ax.text(5.05, 8.8, 'SBox[256]\n8-bit ROM', ha='center', va='center',
                    fontsize=9, color='white', fontweight='bold')
            ax.add_patch(FancyBboxPatch((6.4, 8.1), 2.1, 1.4,
                         boxstyle="round,pad=0.06", facecolor='#B51919', edgecolor='#800000', linewidth=1.5))
            ax.text(7.45, 8.8, 'IBox[256]\n8-bit ROM', ha='center', va='center',
                    fontsize=9, color='white', fontweight='bold')
            ax.text(6.2, 7.7, '256 entries × 8-bit = 2 Kbit ROM per S-Box', ha='center',
                    fontsize=8.5, color='#B51919', style='italic')
            ax.text(6.2, 7.35, 'aes_array.sv: SBox[ ] and IBox[ ] ports\n'
                    'propagated to ALL 12 modules in hierarchy', ha='center',
                    fontsize=8.5, color='#B51919')
            ax.text(6.2, 7.05, '→ Maps to LUT RAM (Yosys) or BRAM (Vivado)', ha='center',
                    fontsize=9, color='#B51919', fontweight='bold')
        else:
            # CFA box
            ax.add_patch(FancyBboxPatch((3.8, 7.0), 4.8, 2.8,
                         boxstyle="round,pad=0.1", facecolor='#D4EDDA', edgecolor='#176B38', linewidth=2))
            ax.text(6.2, 9.6, 'SubBytes Implementation', ha='center', fontsize=10.5,
                    color='#176B38', fontweight='bold')

            # Tower field chain
            blocks_cfa = [
                ('Basis Change\nφ: GF(2⁸)→GF(2⁴)²', 4.0, 9.0, 2.1, 0.7, '#007A87'),
                ('GF(2⁴)² Inversion\n(aes_gf8_inv)', 4.0, 8.1, 2.1, 0.7, '#164E9C'),
                ('Inv Basis + Affine\nφ⁻¹ + 0x63', 4.0, 7.2, 2.1, 0.7, '#176B38'),
            ]
            for lbl, bx2, by2, bw2, bh2, fc2 in blocks_cfa:
                ax.add_patch(FancyBboxPatch((bx2, by2), bw2, bh2,
                             boxstyle="round,pad=0.05", facecolor=fc2, edgecolor='white', linewidth=1.5))
                ax.text(bx2+bw2/2, by2+bh2/2, lbl, ha='center', va='center',
                        fontsize=8.5, color='white', fontweight='bold')
                if by2 > 7.2:
                    ax.annotate('', xy=(bx2+bw2/2, by2-0.05), xytext=(bx2+bw2/2, by2),
                                arrowprops=dict(arrowstyle='->', color='#5A6A7A', lw=1.2))

            # GF(2^4) primitives side
            ax.add_patch(FancyBboxPatch((6.3, 7.7), 2.1, 1.6,
                         boxstyle="round,pad=0.06", facecolor='#EAF0F8', edgecolor='#164E9C', linewidth=1.2))
            ax.text(7.35, 9.15, 'GF(2⁴) primitives', ha='center', fontsize=9, color='#164E9C', fontweight='bold')
            for yi2, prim in enumerate(['gf4_sq_scl', 'gf4_mul', 'gf4_inv']):
                ax.text(7.35, 8.9-yi2*0.35, prim, ha='center', fontsize=8.5, color='#164E9C', fontfamily='monospace')
            ax.annotate('', xy=(6.1, 8.45), xytext=(6.3, 8.45),
                        arrowprops=dict(arrowstyle='<-', color='#164E9C', lw=1.2, linestyle='dashed'))

            ax.text(6.2, 7.35, '~100 XOR/AND gates, purely combinational', ha='center',
                    fontsize=8.5, color='#176B38', fontweight='bold')
            ax.text(6.2, 7.05, 'aes_array.sv DELETED — 0 ROM entries', ha='center',
                    fontsize=9, color='#176B38', fontweight='bold')

        # Impact annotation at bottom
        fill_b = '#FDE8D0' if not is_after else '#D4EDDA'
        edge_b = '#B51919' if not is_after else '#176B38'
        ax.add_patch(FancyBboxPatch((0.3, 0.2), 8.3, 1.5,
                     boxstyle="round,pad=0.08", facecolor=fill_b, edgecolor=edge_b, linewidth=1.5))
        if not is_after:
            ax.text(4.45, 1.5, 'Yosys FSM AES-128: 42,181 LUTs  |  Vivado: 5,486 LUTs',
                    ha='center', fontsize=9.5, color='#B51919', fontweight='bold')
            ax.text(4.45, 1.1, 'SBox[ ]/IBox[ ] ROM ports flow through 12 modules', ha='center',
                    fontsize=9, color='#B51919')
            ax.text(4.45, 0.7, 'Vivado maps ROM to BRAM (free in LUT count) | Yosys maps to LUT RAM', ha='center',
                    fontsize=8.5, color='#5A6A7A')
            ax.text(4.45, 0.35, 'LUTRAM count: 3 (Vivado post-synthesis)', ha='center',
                    fontsize=8.5, color='#B51919')
        else:
            ax.text(4.45, 1.5, 'Yosys FSM AES-128: 17,484 LUTs  (−58.5% from xtime boundary)',
                    ha='center', fontsize=9.5, color='#176B38', fontweight='bold')
            ax.text(4.45, 1.1, 'Vivado FSM AES-128: 3,185 LUTs  |  Pipeline: 4,200 LUTs',
                    ha='center', fontsize=9, color='#176B38')
            ax.text(4.45, 0.7, 'Cumulative: −90.5% from Yosys baseline  (184,918→17,484)', ha='center',
                    fontsize=8.5, color='#176B38')
            ax.text(4.45, 0.35, 'LUTRAM count: 3 → 0  (Vivado)  — frees routing capacity', ha='center',
                    fontsize=9, color='#176B38', fontweight='bold')

    plt.tight_layout(pad=1.2)
    path = CHARTS / "p4_block_diagram.png"
    plt.savefig(path, dpi=150, bbox_inches='tight', facecolor='#F4F6FA')
    plt.close()
    return path


def make_cfa_theory_diagram():
    fig, ax = plt.subplots(figsize=(13, 6.5))
    fig.patch.set_facecolor('#F4F6FA')
    ax.set_facecolor('#F4F6FA'); ax.axis('off')
    ax.set_xlim(0, 13); ax.set_ylim(0, 7)

    ax.text(6.5, 6.75, 'CFA S-Box: Tower-Field Inversion (Canright 2005)', ha='center', va='center',
            fontsize=14, fontweight='bold', color='#0A234F')

    # ── LEFT: Step-by-step derivation ────────────────────────────────────────
    ax.text(0.2, 6.3, 'AES S-Box Definition:', fontsize=11.5, color='#0A234F', fontweight='bold')
    ax.text(0.2, 5.95, '  S(a)  =  AffineTransform( a⁻¹  in GF(2⁸) )    [a ≠ 0]',
            fontsize=10.5, color='#1A1A2E', fontfamily='monospace')
    ax.text(0.2, 5.65, '  S(0)  =  0x63                                   [special case]',
            fontsize=10.5, color='#1A1A2E', fontfamily='monospace')

    ax.text(0.2, 5.2, 'Problem: Direct GF(2⁸) inversion is expensive in hardware.', fontsize=10, color='#B51919')
    ax.text(0.2, 4.85, 'Solution: Lift to tower field GF((2⁴)²) using an isomorphic basis change.', fontsize=10, color='#176B38')

    steps = [
        ('#007A87', 'Step 1 — Basis Change  φ: GF(2⁸) → GF((2⁴)²)',
         '  [b₇..b₀] = B_matrix · [a₇..a₀]    (8×8 matrix multiply over GF(2))\n'
         '  Decomposes 8-bit input into two 4-bit elements (A, B) ∈ GF(2⁴)²'),
        ('#164E9C', 'Step 2 — Tower Field Inversion  (aes_gf8_inv)',
         '  (A,B)⁻¹ = ( d·B,  d·(A ⊕ B) )\n'
         '  where  d = ( A·B ⊕ ν·(A⊕B)² )⁻¹  in GF(2⁴)\n'
         '  ν = coefficient of tower extension polynomial\n'
         '  Decomposes to: 2× GF(2⁴) multiply · 1× GF(2⁴) square-scale · 1× GF(2⁴) invert'),
        ('#176B38', 'Step 3 — Inverse Basis + Affine Transform',
         '  [out] = B⁻¹_matrix · [inv_result]  ⊕  0x63_embedded\n'
         '  0x63 constant embedded via XNOR gates (no separate adder required)'),
    ]
    y_step = 4.3
    for color, title, body in steps:
        ax.add_patch(FancyBboxPatch((0.15, y_step - 0.9), 6.1, 0.95,
                     boxstyle="round,pad=0.07", facecolor='#F4F6FA', edgecolor=color, linewidth=1.5))
        ax.text(0.3, y_step - 0.05, title, fontsize=10, color=color, fontweight='bold')
        ax.text(0.3, y_step - 0.55, body, fontsize=9, color='#1A1A2E', fontfamily='monospace')
        y_step -= 1.1

    # Semantic preservation
    ax.add_patch(FancyBboxPatch((0.15, 0.25), 6.1, 0.9,
                 boxstyle="round,pad=0.07", facecolor='#D4EDDA', edgecolor='#176B38', linewidth=1.5))
    ax.text(0.3, 0.95, 'Semantic Preservation:', fontsize=10, color='#176B38', fontweight='bold')
    ax.text(0.3, 0.65, 'Isomorphic ring homomorphism GF(2⁸)→GF((2⁴)²) preserves field inversion.',
            fontsize=9.5, color='#1A1A2E')
    ax.text(0.3, 0.38, '256/256 inputs verified:  SBox[0x00]=0x63, SBox[0x53]=0xCA, IBox[0x63]=0x00',
            fontsize=9.5, color='#176B38', fontweight='bold')

    # ── RIGHT: Module hierarchy ───────────────────────────────────────────────
    ax.text(6.8, 6.3, 'GF(2⁴) Primitive Module Chain', fontsize=11.5, color='#0A234F', fontweight='bold')

    chain = [
        ('aes_cfa_sbox / aes_cfa_isbox', '#164E9C', 6.7, 5.7, 5.9, 0.6, True),
        ('aes_gf8_inv', '#007A87', 7.4, 4.75, 4.5, 0.55, False),
        ('aes_gf4_mul', '#5A6A7A', 6.7, 3.85, 1.8, 0.5, False),
        ('aes_gf4_sq_scl', '#5A6A7A', 8.8, 3.85, 1.8, 0.5, False),
        ('aes_gf4_inv', '#5A6A7A', 10.9, 3.85, 1.8, 0.5, False),
        ('GF(2²) ops:\nXOR + AND gates', '#176B38', 8.5, 2.75, 2.5, 0.7, False),
    ]
    for lbl, fc, bx, by, bw, bh, top in chain:
        ax.add_patch(FancyBboxPatch((bx, by), bw, bh,
                     boxstyle="round,pad=0.07", facecolor=fc, edgecolor='white', linewidth=1.5))
        ax.text(bx+bw/2, by+bh/2, lbl, ha='center', va='center',
                fontsize=8.5 if not top else 9.5, color='white', fontweight='bold')

    # Arrows between chain
    ax.annotate('', xy=(9.65, 5.3), xytext=(9.65, 5.7),
                arrowprops=dict(arrowstyle='->', color='#5A6A7A', lw=1.5))
    for bx2 in [7.6, 9.7, 11.8]:
        ax.annotate('', xy=(bx2, 3.85), xytext=(bx2, 4.75),
                    arrowprops=dict(arrowstyle='->', color='#5A6A7A', lw=1.2))
    ax.annotate('', xy=(9.75, 3.45), xytext=(9.75, 3.85),
                arrowprops=dict(arrowstyle='->', color='#5A6A7A', lw=1.2))

    # Area annotation
    ax.add_patch(FancyBboxPatch((6.6, 1.6), 6.1, 1.0,
                 boxstyle="round,pad=0.07", facecolor='#EAF0F8', edgecolor='#164E9C', linewidth=1.2))
    ax.text(9.65, 2.4, 'Area Comparison (AES-128 FSM)', ha='center', fontsize=10.5, color='#0A234F', fontweight='bold')
    rows_a = [('ROM (Yosys LUT RAM)', '~42,181 LUTs total incl. ROM overhead'),
              ('CFA combinational',   '~17,484 LUTs  (−58.5% from post-xtime)'),
              ('LUTRAM (Vivado)',      '3 → 0 after CFA substitution')]
    for yi2, (k, v) in enumerate(rows_a):
        ry2 = 2.15 - yi2 * 0.27
        ax.text(6.75, ry2, f'• {k}:', fontsize=9, color='#0A234F', fontweight='bold')
        ax.text(9.0, ry2, v, fontsize=9, color='#176B38' if 'CFA' in k or '→' in v else '#1A1A2E')

    ax.add_patch(FancyBboxPatch((6.6, 0.2), 6.1, 1.2,
                 boxstyle="round,pad=0.07", facecolor='#D4EDDA', edgecolor='#176B38', linewidth=1.2))
    ax.text(9.65, 1.2, 'Why CFA < ROM on FPGA (Yosys)', ha='center', fontsize=10, color='#176B38', fontweight='bold')
    ax.text(6.75, 0.9, '• ROM (LUT RAM): each S-Box instance synthesised as distributed LUT RAM',
            fontsize=9, color='#1A1A2E')
    ax.text(6.75, 0.65, '• CFA: cascade of small XOR/AND → compact 4-input LUT mapping',
            fontsize=9, color='#1A1A2E')
    ax.text(6.75, 0.4, '• Vivado: if ROM was BRAM, CFA looks like an increase (artefact — BRAM was free)',
            fontsize=9, color='#B51919')

    plt.tight_layout(pad=0.5)
    path = CHARTS / "p4_cfa_theory.png"
    plt.savefig(path, dpi=150, bbox_inches='tight', facecolor='#F4F6FA')
    plt.close()
    return path


def make_cfa_results():
    fig, axes = plt.subplots(1, 2, figsize=(13, 5.5))
    fig.patch.set_facecolor('#F4F6FA')

    # Chart 1: Yosys cumulative LUT (FSM 128/192/256)
    ax = axes[0]
    ax.set_facecolor('#F4F6FA')
    ax.spines['top'].set_visible(False); ax.spines['right'].set_visible(False)
    ax.spines['left'].set_color('#CCD5DF'); ax.spines['bottom'].set_color('#CCD5DF')

    labels = ['AES-128', 'AES-192', 'AES-256']
    baseline = [184918, 193131, 202490]
    post_xtime = [42181, 49381, 59710]
    post_cfa   = [17484, 24512, 35444]
    x = np.arange(3); w = 0.26

    b1 = ax.bar(x - w, baseline,   w, color='#B51919', label='Baseline', edgecolor='white', linewidth=1.2)
    b2 = ax.bar(x,     post_xtime, w, color='#D45D00', label='Post-xtime', edgecolor='white', linewidth=1.2)
    b3 = ax.bar(x + w, post_cfa,   w, color='#176B38', label='Post-CFA S-Box', edgecolor='white', linewidth=1.2)

    for i, (bar, val) in enumerate(zip(b3, post_cfa)):
        pcts = [90.5, 87.3, 82.5]
        ax.text(bar.get_x()+bar.get_width()/2, bar.get_height()+1800,
                f'−{pcts[i]:.0f}%', ha='center', va='bottom',
                fontsize=9.5, fontweight='bold', color='#176B38')

    ax.set_xticks(x); ax.set_xticklabels(labels, fontsize=11)
    ax.set_ylabel('Yosys LUT Count', fontsize=11)
    ax.set_title('Yosys LUT — FSM Architecture\n(Cumulative through Phase 4)', fontsize=11, fontweight='bold', color='#0A234F')
    ax.legend(frameon=False, fontsize=10)
    ax.set_ylim(0, 240000)
    ax.yaxis.set_major_formatter(plt.FuncFormatter(lambda v,_: f'{int(v):,}'))
    ax.yaxis.grid(True, color='#E2E8F0', linewidth=0.7, zorder=0); ax.set_axisbelow(True)

    # Chart 2: Vivado — FSM + Pipeline
    ax2 = axes[1]
    ax2.set_facecolor('#F4F6FA')
    ax2.spines['top'].set_visible(False); ax2.spines['right'].set_visible(False)
    ax2.spines['left'].set_color('#CCD5DF'); ax2.spines['bottom'].set_color('#CCD5DF')

    labels2 = ['FSM\nAES-128', 'FSM\nAES-192', 'FSM\nAES-256', 'Pipeline\nAES-128']
    viv_before = [5486,  12233,  6448, 21816]
    viv_after  = [3185,   9605,  4913,  4200]
    x2 = np.arange(4); w2 = 0.35

    ax2.bar(x2 - w2/2, viv_before, w2, color='#D45D00', label='Post-xtime', edgecolor='white', linewidth=1.2)
    ax2.bar(x2 + w2/2, viv_after,  w2, color='#176B38', label='Post-CFA S-Box', edgecolor='white', linewidth=1.2)

    pcts2 = [41.9, 21.5, 23.8, 80.7]
    for i, (bar, pct) in enumerate(zip(ax2.containers[1], pcts2)):
        ax2.text(bar.get_x()+bar.get_width()/2, bar.get_height()+120,
                 f'−{pct:.0f}%', ha='center', va='bottom',
                 fontsize=9.5, fontweight='bold', color='#176B38')

    ax2.set_xticks(x2); ax2.set_xticklabels(labels2, fontsize=10)
    ax2.set_ylabel('Vivado Slice LUTs', fontsize=11)
    ax2.set_title('Vivado LUT — FSM & Pipeline\n(Artix-7 xc7a35t, Phase 4)', fontsize=11, fontweight='bold', color='#0A234F')
    ax2.legend(frameon=False, fontsize=10)
    ax2.set_ylim(0, 26000)
    ax2.yaxis.set_major_formatter(plt.FuncFormatter(lambda v,_: f'{int(v):,}'))
    ax2.yaxis.grid(True, color='#E2E8F0', linewidth=0.7, zorder=0); ax2.set_axisbelow(True)

    plt.tight_layout(pad=1.5)
    path = CHARTS / "p4_results.png"
    plt.savefig(path, dpi=150, bbox_inches='tight', facecolor='#F4F6FA')
    plt.close()
    return path


def build():
    blk  = make_cfa_block_diagram()
    thy  = make_cfa_theory_diagram()
    res  = make_cfa_results()

    prs = new_prs()

    sl = blank_slide(prs)
    slide_chrome(sl, "PHASE 4", "CFA S-Box — What Changed: ROM Eliminated, Combinational Logic Inserted",
                 subtitle="Target: SubBytes & InvSubBytes in 12 modules (aes_cipher.sv, aes_icipher.sv, aes_kexp.sv branches)")
    add_img(sl, blk, MARGIN_L, Inches(0.82), Inches(12.43), Inches(5.7))
    footer(sl, "Phase 4 · aes_cfa_sbox.sv · aes_cfa_isbox.sv · aes_array.sv DELETED",
           right_text="Yosys FSM AES-128: 42,181 → 17,484 LUTs  (−58.5%)")

    sl = blank_slide(prs)
    slide_chrome(sl, "PHASE 4", "CFA S-Box Theory: GF((2⁴)²) Tower-Field Inversion (Canright 2005)",
                 subtitle="Isomorphic decomposition of GF(2⁸) inversion into GF(2⁴) primitives → terminates in XOR + AND gates")
    add_img(sl, thy, MARGIN_L, Inches(0.82), Inches(12.43), Inches(5.7))
    footer(sl, "Phase 4 — CFA S-Box theory",
           right_text="0x63 affine constant embedded via XNOR — no separate adder")

    sl = blank_slide(prs)
    slide_chrome(sl, "PHASE 4", "Phase 4 Results — LUT Reduction: Yosys & Vivado",
                 subtitle="Yosys 0.64 synth_xilinx -family xc7  |  Vivado 2023.2  |  Artix-7 xc7a35t")
    add_img(sl, res, MARGIN_L, Inches(0.82), Inches(9.1), Inches(4.6))

    callout_box(sl, "Key Results",
                "Yosys FSM AES-128\n  42,181 → 17,484  (−58.5%)\n  Cumulative: −90.5%\n\n"
                "Yosys Pipeline AES-128\n  380,018 → 134,289  (−64.7%)\n\n"
                "Vivado FSM AES-128\n  5,486 → 3,185  (−41.9%)\n\n"
                "Vivado Pipeline AES-128\n  21,816 → 4,200  (−80.7%)\n\n"
                "LUTRAM (Vivado):\n  3 → 0  (all architectures)",
                Inches(9.35), Inches(0.85), Inches(3.55), Inches(4.6),
                accent=NAVY, bg=LIGHT_BLU)

    headers = ["Observation", "Root Cause"]
    rows = [
        ["Yosys shows large LUT reduction; Vivado shows smaller", "Vivado mapped ROM to BRAM (free in LUT count); Yosys used LUT RAM"],
        ["LUTRAM count: 3 → 0 in Vivado",                       "ROM S-Box eliminated → frees routing resources beyond raw LUT number"],
        ["Toggle count rises 57× after Phase 4",                 "ROM accessed once/round; CFA logic toggles on every clock edge (expected)"],
    ]
    add_table(sl, headers, rows,
              MARGIN_L, Inches(5.6), Inches(12.43), Inches(1.6),
              header_size=10.5, row_size=10)

    footer(sl, "Phase 4 results — Yosys + Vivado synthesis",
           right_text="−90.5% cumulative LUT reduction from baseline (AES-128 FSM, Yosys)")

    prs.save(str(OUT / "Phase4_CFA_SBox.pptx"))
    print(f"  Phase4_CFA_SBox.pptx  ({len(prs.slides)} slides)")

if __name__ == "__main__":
    build()
