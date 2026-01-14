# Verilator Simulation Workflow

1. build simulator (cmake or verilator --cc/--exe)
2. run simulation binary
3. use args to control:
   - seed
   - runtime limit
   - verbosity
4. store outputs in ./sim/<testname> directory
5. save exit code and summary logs
