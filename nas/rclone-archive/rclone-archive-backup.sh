#!/bin/sh
# Encrypted cold-archive backup: multiple NAS shares -> GCS Archive (rclone crypt).
# copy (not sync): additive — a local deletion never destroys the cloud copy.
#
# This file is the version-controlled record of the script that runs on the NAS
# at /volume1/scripts/rclone-archive-backup.sh. The companion config
# (rclone.conf) and service-account key (gcs-sa.json) live ONLY on the NAS and
# are deliberately never committed — see README.md.

BASE=/volume1/scripts
RCLONE="$BASE/rclone"
CONF="$BASE/rclone.conf"
LOG="$BASE/rclone-backup.log"
LOCK="$BASE/.backup.lock"
DST="secure:"                 # crypt remote -> gcs:<bucket>/backups

SRCS='/volume1/Family VHS Tapes
/volume1/Photo Backups'

if ! mkdir "$LOCK" 2>/dev/null; then
  echo "$(date '+%F %T') skipped: a backup is already running" >> "$LOG"
  exit 0
fi
trap 'rmdir "$LOCK" 2>/dev/null' EXIT

overall=0
while IFS= read -r SRC; do
  [ -z "$SRC" ] && continue
  if [ ! -d "$SRC" ]; then
    echo "$(date '+%F %T') WARN: $SRC not found, skipping" >> "$LOG"
    overall=1; continue
  fi
  name=$(basename "$SRC")
  echo "===== $(date '+%F %T') backing up '$SRC' -> ${DST}${name} =====" >> "$LOG"
  "$RCLONE" copy "$SRC" "${DST}${name}" \
    --config "$CONF" \
    --transfers 8 --checkers 16 \
    --fast-list --size-only \
    --gcs-no-check-bucket \
    --log-file "$LOG" --log-level INFO --stats-one-line --stats 5m
  rc=$?
  echo "===== $(date '+%F %T') '$name' done, exit=$rc =====" >> "$LOG"
  [ "$rc" -ne 0 ] && overall=1
done <<EOF
$SRCS
EOF

[ "$overall" -ne 0 ] && echo "rclone archive backup had FAILURES — see $LOG" >&2
exit "$overall"
