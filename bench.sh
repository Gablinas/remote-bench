#!/bin/sh
# Small fixed-work benchmark. Prints one JSON line. No network, no secrets.
now() { cut -d" " -f1 /proc/uptime; }
elapsed() { awk -v a="$1" -v b="$2" 'BEGIN{printf "%.2f", b-a}'; }
cores=$(nproc 2>/dev/null || echo 1)
mem_mb=$(awk '/MemTotal/{printf "%d",$2/1024}' /proc/meminfo 2>/dev/null || echo 0)
cpu=$(awk -F: '/model name/{gsub(/^ /,"",$2);print $2;exit}' /proc/cpuinfo 2>/dev/null)
# 1 thread: hash 1 GiB of zeros
t0=$(now); dd if=/dev/zero bs=1M count=1024 2>/dev/null | sha256sum >/dev/null; t1=$(now)
single=$(elapsed "$t0" "$t1")
# all cores: same work per core
t0=$(now); i=0
while [ "$i" -lt "$cores" ]; do (dd if=/dev/zero bs=1M count=1024 2>/dev/null | sha256sum >/dev/null) & i=$((i+1)); done; wait
t1=$(now); multi=$(elapsed "$t0" "$t1")
# disk: write 512 MiB with sync in the current directory
t0=$(now); dd if=/dev/zero of=bench.tmp bs=1M count=512 conv=fsync 2>/dev/null; t1=$(now); rm -f bench.tmp
disk=$(elapsed "$t0" "$t1")
printf '{"provider":"%s","host":"%s","cores":%s,"mem_mb":%s,"cpu":"%s","single_thread_s":%s,"all_cores_s":%s,"disk_512mb_s":%s}\n' \
  "${BENCH_PROVIDER:-unknown}" "$(hostname)" "$cores" "$mem_mb" "$cpu" "$single" "$multi" "$disk"
