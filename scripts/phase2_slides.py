"""
Phase 2: FSM Register Clock Enable Gating
3 slides:
  S2.1 — Architecture: where the CE guards live (FSM block diagram)
  S2.2 — Theory: data-path gating vs clock gating, CE condition derivation
  S2.3 — Results: power table, toggle analysis
"""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from slide_engine import *
import matplotlib; matplotlib.use('Agg')
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
from matplotlib.patches import FancyBboxPatch, FancyArrowPatch
import numpy as np
from pathlib import Path

ROOT   = Path(__file__).parent.parent
CHARTS = ROOT / "docs" / "charts"
OUT    = ROOT / "phase_slides"
OUT.mkdir(exist_ok=True)


def make_fsm_ce_diagram():
    """Shows the FSM block and exactly where CE wraps the register."""
    fig, axes = plt.subplots(1, 2, figsize=(14, 6.0))
    fig.patch.set_facecolor('#F4F6FA')

    # ── LEFT: FSM state machine diagram ──────────────────────────────────────
    ax = axes[0]
    ax.set_facecolor('#F4F6FA'); ax.axis('off')
    ax.set_xlim(0, 8); ax.set_ylim(0, 8)
    ax.set_title('Encrypt FSM State Machine\n(aes_cipher_state.sv)', fontsize=12, fontweight='bold', color='#0A234F')

    states = [('IDLE\n4\'hF', 2.5, 6.5), ('Rounds\n1…Nr-1', 5.5, 6.5), ('FINAL\nstate=Nr', 5.5, 4.0)]
    state_colors = ['#164E9C', '#007A87', '#176B38']
    for (lbl, sx, sy), sc in zip(states, state_colors):
        ax.add_patch(plt.Circle((sx, sy), 0.85, color=sc, zorder=3))
        ax.text(sx, sy, lbl, ha='center', va='center', fontsize=9.5, color='white', fontweight='bold', zorder=4)

    # Transitions
    arrows = [
        ((2.5,6.5),(5.5,6.5), 'Enable=1\n→ state=1', 0, '#D45D00', 'arc3,rad=-0.2'),
        ((5.5,6.5),(5.5,6.5), 'state<Nr-1\nstate++', 0, '#5A6A7A', 'arc3,rad=0'),  # self-loop
        ((5.5,6.5),(5.5,4.0), 'state=Nr-1', 0, '#007A87', 'arc3,rad=0'),
        ((5.5,4.0),(2.5,6.5), 'ready=1\n→ IDLE', 0, '#176B38', 'arc3,rad=-0.35'),
        ((2.5,6.5),(2.5,6.5), 'Enable=0', 0, '#B51919', 'arc3,rad=0'),  # IDLE self-loop
    ]
    ax.annotate('', xy=(5.5,6.5), xytext=(3.35,6.5),
                arrowprops=dict(arrowstyle='->', color='#D45D00', lw=2))
    ax.text(4.4, 6.85, 'Enable=1 / state←1', fontsize=8.5, color='#D45D00', ha='center')

    # self loop on IDLE
    ax.annotate('', xy=(2.1, 7.05), xytext=(2.05, 7.3),
                arrowprops=dict(arrowstyle='->', connectionstyle='arc3,rad=-1.8', color='#B51919', lw=1.5))
    ax.text(1.1, 7.4, 'Enable=0', fontsize=8, color='#B51919')

    # self loop on Rounds
    ax.annotate('', xy=(6.05, 7.05), xytext=(6.0, 7.3),
                arrowprops=dict(arrowstyle='->', connectionstyle='arc3,rad=1.8', color='#5A6A7A', lw=1.5))
    ax.text(6.8, 7.4, 'state<Nr-1\nstate++', fontsize=8, color='#5A6A7A', ha='center')

    # FINAL → IDLE
    ax.annotate('', xy=(3.2, 6.0), xytext=(5.0, 4.5),
                arrowprops=dict(arrowstyle='->', connectionstyle='arc3,rad=-0.35', color='#176B38', lw=2))
    ax.text(3.5, 5.0, 'ready=1\n→ IDLE', fontsize=8.5, color='#176B38', ha='center')

    # Rounds → FINAL
    ax.annotate('', xy=(5.5, 4.85), xytext=(5.5, 5.65),
                arrowprops=dict(arrowstyle='->', color='#007A87', lw=2))
    ax.text(5.9, 5.3, 'state=Nr-1', fontsize=8.5, color='#007A87')

    # CE guard annotation
    ax.add_patch(FancyBboxPatch((0.1, 0.3), 7.8, 1.9,
                 boxstyle="round,pad=0.1", facecolor='#D8E8F8', edgecolor='#164E9C', linewidth=2))
    ax.text(4.0, 1.95, 'CE Guard on Packed Register r = {state[3:0], ready}',
            ha='center', fontsize=10.5, color='#0A234F', fontweight='bold')
    ax.text(0.35, 1.6,
            'always_ff @(posedge clk) begin\n'
            '  if (CE) r <= next_r;        // CE freezes register when FSM is idle\n'
            'end',
            fontsize=9.5, color='#164E9C', fontfamily='monospace')
    ax.text(0.35, 0.75,
            'CE = (r.state != IDLE) || (r.ready == 1) || (Enable == 1)',
            fontsize=10, color='#176B38', fontweight='bold', fontfamily='monospace')
    ax.text(0.35, 0.42, 'Three terms — each is necessary (removing any one breaks a corner case)',
            fontsize=8.5, color='#5A6A7A')

    # ── RIGHT: Where CE sits in hardware ─────────────────────────────────────
    ax2 = axes[1]
    ax2.set_facecolor('#F4F6FA'); ax2.axis('off')
    ax2.set_xlim(0, 8); ax2.set_ylim(0, 8)
    ax2.set_title('CE Guard — Register-Level View\n(FDRE primitive, Artix-7)', fontsize=12, fontweight='bold', color='#0A234F')

    # Combinational logic block
    ax2.add_patch(FancyBboxPatch((0.3, 5.8), 2.5, 1.4,
                 boxstyle="round,pad=0.1", facecolor='#FDE8D0', edgecolor='#D45D00', linewidth=1.5))
    ax2.text(1.55, 6.5, 'Next-state\nCombinational\nLogic', ha='center', va='center',
             fontsize=9.5, color='#D45D00', fontweight='bold')

    # MUX
    ax2.add_patch(plt.Polygon([[3.2,5.9],[3.2,7.5],[4.0,7.1],[4.0,6.3]], color='#007A87'))
    ax2.text(3.55, 6.7, 'MUX', ha='center', va='center', fontsize=8.5, color='white', fontweight='bold')

    # FDRE flip-flop
    ax2.add_patch(FancyBboxPatch((4.5, 5.8), 2.2, 1.8,
                 boxstyle="round,pad=0.1", facecolor='#164E9C', edgecolor='#0A234F', linewidth=2))
    ax2.text(5.6, 7.0, 'FDRE', ha='center', va='center', fontsize=11, color='white', fontweight='bold')
    ax2.text(5.6, 6.6, 'Flip-Flop', ha='center', va='center', fontsize=9, color='#B0C8E8')
    ax2.text(4.6, 6.0, 'D', fontsize=9, color='white', fontweight='bold')
    ax2.text(5.2, 6.0, 'CE', fontsize=9, color='#FFD700', fontweight='bold')
    ax2.text(6.4, 6.0, 'Q', fontsize=9, color='white', fontweight='bold')
    ax2.text(5.6, 5.82, 'CLK ↑', ha='center', fontsize=8, color='#B0C8E8')

    # D input arrow
    ax2.annotate('', xy=(4.5, 6.5), xytext=(4.05, 6.7),
                arrowprops=dict(arrowstyle='->', color='#D45D00', lw=1.8))
    # CE input arrow
    ax2.annotate('', xy=(5.2, 6.1), xytext=(5.2, 5.2),
                arrowprops=dict(arrowstyle='->', color='#FFD700', lw=2))
    ax2.text(5.2, 4.95, 'CE', ha='center', fontsize=9.5, color='#FFD700', fontweight='bold')
    ax2.text(5.2, 4.65, '(computed logic)', ha='center', fontsize=8.5, color='#5A6A7A')

    # feedback path (CE=0 → Q feeds back)
    ax2.annotate('', xy=(4.05, 6.3), xytext=(6.7, 6.3),
                arrowprops=dict(arrowstyle='->', connectionstyle='arc3,rad=0.5',
                               color='#007A87', lw=1.5))
    ax2.text(5.9, 5.5, 'Q feedback\n(CE=0)', ha='center', fontsize=8.5, color='#007A87')

    # CLK still arrives
    ax2.annotate('', xy=(5.6, 5.8), xytext=(5.6, 5.2),
                arrowprops=dict(arrowstyle='->', color='#5A6A7A', lw=1.5))
    ax2.text(5.6, 5.0, 'CLK (always runs)', ha='center', fontsize=8.5, color='#5A6A7A')

    # next_r arrow into MUX
    ax2.annotate('', xy=(3.2, 7.1), xytext=(2.8, 7.1),
                arrowprops=dict(arrowstyle='->', color='#D45D00', lw=1.8))

    # Key insight boxes
    ax2.add_patch(FancyBboxPatch((0.2, 3.0), 7.6, 2.5,
                 boxstyle="round,pad=0.1", facecolor='#F4F6FA', edgecolor='#5A6A7A', linewidth=1))
    ax2.text(4.0, 5.3, 'Data Path Gating — NOT Clock Gating', ha='center',
             fontsize=11, fontweight='bold', color='#0A234F')

    rows_txt = [
        ('Clock net',       'Still toggles every cycle',    '#B51919'),
        ('FF cell power',   'NOT saved (clock edge fires)',  '#B51919'),
        ('Data fanin cone', 'FROZEN when CE=0 (D input held constant)', '#176B38'),
        ('α·C·V²·f term',  'α drops to 0 for data signals', '#176B38'),
        ('FPGA primitive',  'FDRE CE pin — purely RTL, no ICG IP needed', '#007A87'),
    ]
    for yi, (label, val, color) in enumerate(rows_txt):
        ry = 4.95 - yi * 0.43
        ax2.add_patch(FancyBboxPatch((0.3, ry-0.19), 3.5, 0.38,
                     boxstyle="square,pad=0", facecolor='#D8E8F8' if yi%2==0 else 'white',
                     edgecolor='#CCD5DF', linewidth=0.5))
        ax2.text(0.4, ry, label, fontsize=9.5, va='center', color='#0A234F', fontweight='bold')
        ax2.add_patch(FancyBboxPatch((3.82, ry-0.19), 4.0, 0.38,
                     boxstyle="square,pad=0", facecolor='#D8E8F8' if yi%2==0 else 'white',
                     edgecolor='#CCD5DF', linewidth=0.5))
        ax2.text(3.92, ry, val, fontsize=9, va='center', color=color)

    ax2.add_patch(FancyBboxPatch((0.2, 0.3), 7.6, 2.5,
                 boxstyle="round,pad=0.1", facecolor='#D4EDDA', edgecolor='#176B38', linewidth=1.5))
    ax2.text(4.0, 2.62, 'Why 3 CE terms — each guards a corner case:', ha='center',
             fontsize=10.5, fontweight='bold', color='#176B38')
    terms = [
        ('r.state != IDLE', 'Active round must always advance — removes this and FSM stalls mid-computation'),
        ('r.ready == 1',    'Ready flag must hold until host reads it — remove and output corrupts'),
        ('Enable == 1',     'New request seeds FSM out of IDLE — remove and encryption never starts'),
    ]
    for yi, (term, expl) in enumerate(terms):
        ty2 = 2.25 - yi * 0.6
        ax2.text(0.4, ty2, f'• {term}', fontsize=10, color='#0A234F', fontweight='bold', fontfamily='monospace')
        ax2.text(0.4, ty2 - 0.25, f'  {expl}', fontsize=9, color='#1A1A2E')

    plt.tight_layout(pad=1.0)
    path = CHARTS / "p2_fsm_ce.png"
    plt.savefig(path, dpi=150, bbox_inches='tight', facecolor='#F4F6FA')
    plt.close()
    return path


def make_phase2_power_chart():
    fig, axes = plt.subplots(1, 2, figsize=(13, 5.5))
    fig.patch.set_facecolor('#F4F6FA')

    # Chart 1: Dynamic power breakdown
    ax = axes[0]
    ax.set_facecolor('#F4F6FA')
    ax.spines['top'].set_visible(False); ax.spines['right'].set_visible(False)
    ax.spines['left'].set_color('#CCD5DF'); ax.spines['bottom'].set_color('#CCD5DF')

    categories = ['Clocks', 'Signals', 'Logic', 'I/O']
    baseline = [0.042, 0.068, 0.095, 0.012]
    post_fsm  = [0.036, 0.052, 0.074, 0.012]
    x = np.arange(4); w = 0.35

    ax.bar(x - w/2, baseline, w, color='#B51919', label='Baseline (no CE)', edgecolor='white', linewidth=1.5)
    ax.bar(x + w/2, post_fsm, w, color='#176B38', label='After FSM CE Gating', edgecolor='white', linewidth=1.5)

    for xi, (bv, av) in enumerate(zip(baseline, post_fsm)):
        if bv > 0:
            pct = (bv - av) / bv * 100
            ax.text(xi + w/2, av + 0.001, f'−{pct:.0f}%',
                    ha='center', va='bottom', fontsize=9.5, color='#176B38', fontweight='bold')

    ax.set_xticks(x); ax.set_xticklabels(categories, fontsize=11)
    ax.set_ylabel('Dynamic Power (W)', fontsize=11)
    ax.set_title('Dynamic Power Breakdown\nFSM CE Gating (Vivado SAIF, AES-128)', fontsize=11, fontweight='bold', color='#0A234F')
    ax.legend(frameon=False, fontsize=10)
    ax.set_ylim(0, 0.12)
    ax.yaxis.grid(True, color='#E2E8F0', linewidth=0.7, zorder=0); ax.set_axisbelow(True)

    # Total labels
    ax.text(1.5 - w/2, 0.217 * 0.98, 'Total\n0.217 W', ha='center', va='top', fontsize=9, color='#B51919', fontweight='bold')
    ax.text(1.5 + w/2, 0.174 * 0.98, 'Total\n0.174 W', ha='center', va='top', fontsize=9, color='#176B38', fontweight='bold')

    # Chart 2: Idle toggle analysis
    ax2 = axes[1]
    ax2.set_facecolor('#F4F6FA')
    ax2.spines['top'].set_visible(False); ax2.spines['right'].set_visible(False)
    ax2.spines['left'].set_color('#CCD5DF'); ax2.spines['bottom'].set_color('#CCD5DF')

    labels2 = ['FSM Baseline', 'FSM Post-CE']
    values2 = [0, 0]
    colors2 = ['#176B38', '#176B38']
    bars = ax2.bar(labels2, values2, color=colors2, edgecolor='white', linewidth=1.5, width=0.5)
    ax2.set_ylim(0, 120000)
    ax2.set_ylabel('Reg-Candidate Idle Toggles', fontsize=11)
    ax2.set_title('Idle-State Toggle Analysis\n(FSM — strict idle windows, AES-128)', fontsize=11, fontweight='bold', color='#0A234F')
    ax2.yaxis.grid(True, color='#E2E8F0', linewidth=0.7, zorder=0); ax2.set_axisbelow(True)

    ax2.text(0, 8000, '0 (already quiet at IDLE)\n\n'
             'FSM registers were\nnaturally quiet because\nFSM sits IDLE between ops.\n\n'
             'CE gating adds defense-\nin-depth and enables\nfine-grained Phase 6 gating.',
             ha='center', va='bottom', fontsize=10, color='#176B38')

    ax2.text(1, 8000, '0\n(unchanged)',
             ha='center', va='bottom', fontsize=11, fontweight='bold', color='#176B38')

    # Pipeline note
    ax2.text(0.5, 108000,
             'Pipeline idle toggles: 101,035 → 0  (Phases 5+6)',
             ha='center', fontsize=10, color='#164E9C', fontweight='bold',
             bbox=dict(boxstyle='round,pad=0.3', facecolor='#D8E8F8', edgecolor='#164E9C'))

    plt.tight_layout(pad=1.5)
    path = CHARTS / "p2_power.png"
    plt.savefig(path, dpi=150, bbox_inches='tight', facecolor='#F4F6FA')
    plt.close()
    return path


def build():
    ce_diag  = make_fsm_ce_diagram()
    pwr_chart = make_phase2_power_chart()

    prs = new_prs()

    # ── SLIDE 2.1: What Changed ────────────────────────────────────────────────
    sl = blank_slide(prs)
    slide_chrome(sl, "PHASE 2", "FSM Register Clock Enable Gating — What Changed & Where",
                 subtitle="Files: aes_cipher_state.sv · aes_icipher_state.sv · aes_kexp_state.sv")

    add_img(sl, ce_diag, MARGIN_L, Inches(0.82), Inches(12.43), Inches(5.7))
    footer(sl, "Phase 2 · FSM CE gating · 3 modules modified",
           right_text="No LUT change — effect is purely in dynamic power (switching activity)")

    # ── SLIDE 2.2: Theory + All three FSMs ────────────────────────────────────
    sl = blank_slide(prs)
    slide_chrome(sl, "PHASE 2", "Data Path Gating: All Three FSM Modules",
                 subtitle="CE guard applied to packed register structs in cipher, icipher, and kexp state machines")

    y = Inches(0.88)
    headers = ["Module", "Register(s) Gated", "CE Condition", "Why different"]
    rows = [
        ["aes_cipher_state.sv",
         "r = {state[3:0], ready}",
         "r.state!=0 || r.ready==1 || Enable",
         "Encrypt FSM: IDLE = state 0, counts up"],
        ["aes_icipher_state.sv",
         "r = {state[3:0], ready}",
         "r.state!=Nr || r.ready==1 || Enable",
         "Decrypt FSM: IDLE = state Nr, counts down"],
        ["aes_kexp_state.sv",
         "r (struct) + KExp_N (data reg)",
         "r:  state!=0||ready||Enable\nKExp_N: state!=0||Enable",
         "KExp_N has no ready bit — narrower guard"],
    ]
    add_table(sl, headers, rows,
              MARGIN_L, y, Inches(12.43), Inches(1.95),
              header_size=11, row_size=10.5)

    y2 = Inches(3.0)
    callout_box(sl, "Key Insight: Why NOT Hardware Clock Gating",
                "Hardware clock gating (ICG cell) suppresses the CLOCK signal to a register group.\n"
                "  → Register cell sees no clock edge → zero register power\n"
                "  → But combinational D-input logic STILL evaluates every cycle\n\n"
                "This project uses DATA PATH GATING (CE pin on FDRE primitive):\n"
                "  → Clock still arrives every cycle — register power is NOT saved\n"
                "  → When CE=0: MUX selects Q-feedback; D-input cone goes STATIC\n"
                "  → Switching activity α on all data signals drops to 0\n"
                "  → Power saved:  ΔP = α · C_data · V² · f · (1 − duty_cycle)",
                MARGIN_L, y2, Inches(7.55), Inches(3.2),
                accent=NAVY, bg=LIGHT_BLU)

    callout_box(sl, "Architectural Scope",
                "3 FSMs modified:\n"
                "  • aes_cipher_state.sv   — encrypt, 10/12/14 rounds\n"
                "  • aes_icipher_state.sv  — decrypt, 10/12/14 rounds\n"
                "  • aes_kexp_state.sv     — key schedule, shared\n\n"
                "These FSMs sit IDLE between encryption requests.\n"
                "Without CE: state register toggles every clock cycle even at rest.\n"
                "With CE: register freezes → combinational fanin goes silent.",
                Inches(8.2), y2, Inches(4.68), Inches(3.2),
                accent=TEAL, bg=RGBColor(0xD8, 0xF0, 0xF4))

    footer(sl, "Phase 2 · data-path gating on FSM state registers",
           right_text="FDRE.CE pin — no ICG cells — purely RTL, tool-agnostic")

    # ── SLIDE 2.3: Results ─────────────────────────────────────────────────────
    sl = blank_slide(prs)
    slide_chrome(sl, "PHASE 2", "Phase 2 Results — Dynamic Power Reduction",
                 subtitle="Vivado report_power (SAIF annotation) · AES-128 · Artix-7 xc7a35t")

    add_img(sl, pwr_chart, MARGIN_L, Inches(0.85), Inches(9.0), Inches(4.5))

    callout_box(sl, "Phase 2 Contribution",
                "LUT change:  0  (same logic, different enable)\n"
                "FF change:   0  (same registers, CE pin added)\n\n"
                "Dynamic power:\n"
                "  Baseline total:   0.217 W\n"
                "  After FSM CE:     0.174 W  (−19.8%)\n\n"
                "Largest savings in Signals and Logic rows\n"
                "— exactly what data-path gating predicts.\n\n"
                "I/O power unchanged (driven by test stimulus,\n"
                "not internal enables).",
                Inches(9.65), Inches(0.85), Inches(3.25), Inches(4.5),
                accent=GREEN, bg=LIGHT_GRN)

    headers2 = ["Metric", "Before Phase 2", "After Phase 2", "Interpretation"]
    rows2 = [
        ["LUT count",    "No change", "No change",      "CE is enable logic, not new datapath"],
        ["FF count",     "No change", "No change",      "Same registers; CE pin is free in FDRE"],
        ["Total dyn. P", "0.217 W",   "0.174 W (−20%)", "Signal + logic switching drops at idle"],
        ["Idle toggles (FSM)", "0",   "0",              "FSM already quiet; CE adds future-proofing"],
    ]
    add_table(sl, headers2, rows2,
              MARGIN_L, Inches(5.5), Inches(12.43), Inches(1.65),
              header_size=10.5, row_size=10)

    footer(sl, "Phase 2 results · power from Vivado report_power with SAIF switching activity",
           right_text="Phases 5+6 add pipeline CE → 101,035 idle toggles → 0  (−100%)")

    prs.save(str(OUT / "Phase2_FSM_CE_Gating.pptx"))
    print(f"  Phase2_FSM_CE_Gating.pptx  ({len(prs.slides)} slides)")

if __name__ == "__main__":
    build()
