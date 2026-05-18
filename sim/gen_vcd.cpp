#include <stdlib.h>
#include <iostream>
#include <cstdlib>
#include <cstring>
#include <verilated.h>
#include <verilated_vcd_c.h>
#include "Vaes_vcd_tb.h"

// Simulation harness for VCD generation.
// Usage: gen_vcd [max_sim_time_ps] [output.vcd]
// Default max_sim_time: 500000 ps (sufficient for 3 burst cycles at 100 MHz virtual time)

vluint64_t sim_time = 0;

int main(int argc, char** argv, char** env)
{
  vluint64_t max_sim_time = 500000;
  const char *filename = "dump.vcd";

  if (argc >= 2)
    max_sim_time = atoll(argv[1]);
  if (argc >= 3)
    filename = argv[2];

  Verilated::commandArgs(argc, argv);
  Vaes_vcd_tb *dut = new Vaes_vcd_tb;

#if VM_TRACE
  Verilated::traceEverOn(true);
  VerilatedVcdC *trace = new VerilatedVcdC;
  // Trace full hierarchy (depth 0 = unlimited)
  dut->trace(trace, 0);
  trace->open(filename);
#endif

  bool finished = false;

  while (sim_time < max_sim_time)
  {
    // Reset for first 10 time steps
    dut->rst = (sim_time < 10) ? 0 : 1;

    // Toggle clock every step (period = 2 ps in virtual time,
    // matches existing run.cpp; Vivado power report uses the annotated
    // switching activity, not the VCD timescale, so clock frequency
    // is set separately in Vivado's Report Power dialog at 100 MHz)
    dut->clk ^= 1;

    dut->eval();

#if VM_TRACE
    trace->dump(sim_time);
#endif

    sim_time++;

    if (Verilated::gotFinish()) {
      finished = true;
      break;
    }
  }

  if (!finished) {
    std::cerr << "\033[33mWARNING: simulation hit time limit before $finish\033[0m" << std::endl;
    std::cerr << "  Increase max_sim_time (current=" << max_sim_time << " ps)" << std::endl;
  } else {
    std::cout << "VCD written: " << filename << "  (finished @" << sim_time << " ps)" << std::endl;
  }

#if VM_TRACE
  trace->close();
#endif

  delete dut;
  return finished ? EXIT_SUCCESS : 1;
}
