#!/bin/sh

echo -n > ZX_Next.qip
for vhd in $(find . -name "*.v"); do
	echo "set_global_assignment -name VERILOG_FILE [file join $::quartus(qip_path) $vhd      ]" >> F2.qip
done
for vhd in $(find . -name "*.sv"); do
	echo "set_global_assignment -name SYSTEMVERILOG_FILE [file join $::quartus(qip_path) $vhd      ]" >> F2.qip
done