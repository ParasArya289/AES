#!/usr/bin/env python3
"""
VCD toggle counter with subsystem grouping.
Usage: python3 scripts/toggle_count.py <path-to-vcd> [label]
Output: per-subsystem toggle counts + TOTAL line to stdout;
        appends CSV line "label,subsystem,count" to scripts/toggle_results.txt if label provided.
"""
import re
import sys
from collections import defaultdict

def count_toggles(vcd_path, label=None):
    with open(vcd_path) as f:
        content = f.read()

    # Phase 1: build signal ID -> hierarchical path map
    sig_map = {}
    current_scope = []
    for line in content.splitlines():
        line = line.strip()
        if line.startswith('$scope module'):
            m = re.search(r'\$scope module (\S+)', line)
            if m:
                current_scope.append(m.group(1))
        elif line.startswith('$upscope'):
            if current_scope:
                current_scope.pop()
        elif line.startswith('$var'):
            m = re.search(r'\$var\s+\w+\s+\d+\s+(\S+)\s+(\S+)', line)
            if m:
                sig_id = m.group(1)
                sig_name = m.group(2)
                sig_map[sig_id] = '.'.join(current_scope) + '.' + sig_name

    # Phase 2: count scalar toggle events (single-char ID lines starting with 0/1/x/z)
    toggle_counts = defaultdict(int)
    for line in content.splitlines():
        line = line.strip()
        if len(line) >= 2 and line[0] in '01xzXZ' and ' ' not in line:
            sig_id = line[1:]
            toggle_counts[sig_id] += 1

    # Phase 3: group by subsystem (first component after top-level scope)
    subsystem_totals = defaultdict(int)
    total = 0
    for sig_id, count in toggle_counts.items():
        path = sig_map.get(sig_id, 'unknown')
        parts = path.split('.')
        # subsystem = second component of hierarchy (e.g. sbox_cfa, kexp, cipher_state)
        subsystem = parts[1] if len(parts) > 1 else 'other'
        subsystem_totals[subsystem] += count
        total += count

    # Phase 4: print results
    print(f"Toggle counts by subsystem ({vcd_path}):")
    for sub, cnt in sorted(subsystem_totals.items(), key=lambda x: -x[1]):
        print(f"  {sub:<24}: {cnt:>8}")
    print(f"  {'TOTAL':<24}: {total:>8}")

    # Phase 5: append CSV if label provided
    if label:
        results_path = 'scripts/toggle_results.txt'
        with open(results_path, 'a') as out:
            for sub, cnt in subsystem_totals.items():
                out.write(f"{label},{sub},{cnt}\n")
            out.write(f"{label},TOTAL,{total}\n")

    return total

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print(f"Usage: {sys.argv[0]} <vcd_path> [label]", file=sys.stderr)
        sys.exit(1)
    vcd_path = sys.argv[1]
    label = sys.argv[2] if len(sys.argv) > 2 else None
    count_toggles(vcd_path, label)
