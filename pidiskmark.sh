#!/bin/sh

crystalread() {
  awk -F \; '/^fio:/ { print; next } { printf("%32s : %8.2f MB/s [%9.1f IOPS]\n", $3, $7*1024/1e6, $8) }'
}

crystalwrite() {
  awk -F \; '/^fio:/ { print; next } { printf("%32s : %8.2f MB/s [%9.1f IOPS]\n", $3, $48*1024/1e6, $49) }'
}

crystaltest() {
  echo "${SIZE}B (x${ITERATIONS}) [Interval=$INTERVAL sec]"
}

crystalvolume() {
  local dfi="$(df --sync -h --output=source,pcent,used,size "${FILE}" | tail -n1)"
  local source="$(echo "$dfi" | awk '{print $1}')"
  local pcent="$(echo "$dfi" | awk '{print $2}')"
  local used="$(echo "$dfi" | awk '{print $3}')"
  local size="$(echo "$dfi" | awk '{print $4}')"
  eval $(/usr/sbin/blkid -o export "$source")
  echo "${LABEL:-$PARTLABEL}: $pcent used ($used / $size)"
}

crystaldevice() {
  local dfi="$(df --sync -h --output=source,pcent,used,size "${FILE}" | tail -n1)"
  local source="$(echo "$dfi" | awk '{print $1}')"
  local relsource="$(realpath --relative-to=/dev/disk/by-id "$source")"
  local devname="$(ls /dev/disk/by-id -o1 | awk "\$10 == \"$relsource\" { print \$8 }")"
  echo "$devname ($source)"
}

crystalcpu() {
  local vendor="$(lscpu | awk '/^Vendor ID:/ { print $3; exit }')"
  local model="$(lscpu | awk '/Model name:/ { print $3; exit }')"
  echo "$vendor $model"
}

crystaldate() {
  date -Iseconds | sed -e 's/+00:00/Z/'
}

crystalos() {
  if [ -r /etc/lsb-release ]; then
    . /etc/lsb-release
    distrib="${DISTRIB_DESCRIPTION}"
  else
    distrib="$(uname -o)"
  fi
  echo "$distrib ($(uname -srm))"
}

FILE="$1"
SIZE="${2:-1Gi}"
ITERATIONS="${3:-5}"
DURATION="${4:-5}"
INTERVAL="${5:-5}"
ATOMIC="${6:-0}"

if ! fio -v > /dev/null 2>&1; then
  echo "Please install fio." > /dev/stderr
  exit 1
fi

if [ -z "$FILE" ]; then
  echo Usage: $0 test_file_name [size=1Gi] [iterations=5] [duration=5] [interval=5] [atomic=0] > /dev/stderr
  exit 1
fi

if [ -e "$FILE" ]; then
  echo "$FILE" already exists! Please specify a file name that does not exist. > /dev/stderr
  exit 2
fi

if ! touch "$FILE" 2>/dev/null; then
  echo "$FILE" is not accessible! >/dev/stderr
  exit 3
fi

OPTS="--ioengine=libaio --direct=1 --atomic=${ATOMIC} --buffered=0 --iodepth_batch_complete=0 --userspace_reap --output-format=terse"
CONFIG="--loops=${ITERATIONS} --ramp_time=2s --runtime=${DURATION}s --size=$SIZE"

echo "---------------------------------------------------------------------"
echo "PiDiskMark 1.1 (C) 2020-2026 Nikolay Botev"
echo ""
echo "---------------------------------------------------------------------"
echo "* MB/s = 1,000,000 bytes/s [SATA/600 = 600,000,000 bytes/s]"
echo "* KB = 1,000 bytes, KiB = 1,024 bytes"
echo "* MB = 1,000,000 bytes, MiB = 1,048,576 bytes"
echo ""

fio $OPTS $CONFIG --filename="$FILE" --name="  Sequential Read 1MiB (QD=   8)" --bs=1m  --iodepth=8 --rw=read      | crystalread
sleep "$INTERVAL"
fio $OPTS $CONFIG --filename="$FILE" --name=" Sequential Write 1MiB (QD=   8)" --bs=1m  --iodepth=8 --rw=write     | crystalwrite
sleep "$INTERVAL"
fio $OPTS $CONFIG --filename="$FILE" --name="     Sequential Read 1MiB (QD=1)" --bs=1m  --iodepth=1 --rw=read      | crystalread
sleep "$INTERVAL"
fio $OPTS $CONFIG --filename="$FILE" --name="    Sequential Write 1MiB (QD=1)" --bs=1m  --iodepth=1 --rw=write     | crystalwrite
sleep "$INTERVAL"
fio $OPTS $CONFIG --filename="$FILE" --name="      Random Read 4KiB (QD=  64)" --bs=4k --iodepth=64 --rw=randread  | crystalread
sleep "$INTERVAL"
fio $OPTS $CONFIG --filename="$FILE" --name="     Random Write 4KiB (QD=  64)" --bs=4k --iodepth=64 --rw=randwrite | crystalwrite
sleep "$INTERVAL"
fio $OPTS $CONFIG --filename="$FILE" --name="         Random Read 4KiB (QD=1)" --bs=4k  --iodepth=1 --rw=randread  | crystalread
sleep "$INTERVAL"
fio $OPTS $CONFIG --filename="$FILE" --name="        Random Write 4KiB (QD=1)" --bs=4k  --iodepth=1 --rw=randwrite | crystalwrite

echo ""
echo "    Test : $(crystaltest)"
echo "  Volume : $(crystalvolume)"
echo "  Device : $(crystaldevice)"
echo "     CPU : $(crystalcpu)"
echo "    Date : $(crystaldate)"
echo "      OS : $(crystalos)"

rm "$FILE"
