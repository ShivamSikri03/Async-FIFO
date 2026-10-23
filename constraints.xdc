# ==============================================================================
# File: constraints.xdc
# Description: Timing Constraints for Dual-Clock Asynchronous FIFO
# ==============================================================================

# Write Clock: 100 MHz (10.0 ns period)
create_clock -period 10.000 -name wclk -waveform {0.000 5.000} [get_ports wclk]

# Read Clock: 40 MHz (25.0 ns period)
create_clock -period 25.000 -name rclk -waveform {0.000 12.500} [get_ports rclk]

# Clock Domain Crossing (CDC) Constraint
# Tells STA that wclk and rclk are asynchronous, preventing false timing violations
set_clock_groups -asynchronous \
    -group [get_clocks wclk] \
    -group [get_clocks rclk]
