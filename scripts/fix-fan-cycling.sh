#!/bin/bash
# Fix fan cycling on TUXEDO Stellaris 17 Gen6

# Set CPU to power-saving mode to reduce heat
sudo cpupower frequency-set -g powersave

# Set energy performance preference to balanced-power
echo "balance_power" | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference

# Optional: Limit turbo boost slightly to prevent temperature spikes
echo 90 | sudo tee /sys/devices/system/cpu/intel_pstate/max_perf_pct

echo "Fan cycling mitigation applied. CPU temp should stay below 55°C threshold."
