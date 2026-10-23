@echo off
echo ===================================================
echo   Compiling Asynchronous FIFO with Icarus Verilog
echo ===================================================
iverilog -o sim_fifo.vvp sync_2ff.v fifomem.v rptr_empty.v wptr_full.v async_fifo.v tb_async_fifo.v
if %errorlevel% neq 0 (
    echo [ERROR] Compilation failed!
    pause
    exit /b %errorlevel%
)

echo.
echo ===================================================
echo   Running Simulation and Logging Results
echo ===================================================
vvp sim_fifo.vvp | tee simulation.log
if %errorlevel% neq 0 (
    vvp sim_fifo.vvp > simulation.log
    type simulation.log
)

echo.
echo ===================================================
echo   Launching GTKWave with Preconfigured Signals
echo ===================================================
start gtkwave async_fifo.vcd wave.gtkw
