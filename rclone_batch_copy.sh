#!/bin/bash

# Usage: ./rclone_batch_copy.sh file_list.tsv IRDS
# Arguments:
#   $1 = TSV file with src and dest columns
#   $2 = rclone remote name (e.g., IRDS)

set -euo pipefail

INPUT_TSV="$1"
REMOTE_NAME="$2"
TIMESTAMP=$(date '+%Y-%m-%d_%H-%M-%S')
LOGFILE="rclone_copy_log_$TIMESTAMP.txt"

echo "Starting batch rclone copy at $(date)" | tee -a "$LOGFILE"
echo "Input file: $INPUT_TSV" | tee -a "$LOGFILE"
echo "Rclone remote: $REMOTE_NAME" | tee -a "$LOGFILE"
echo "" | tee -a "$LOGFILE"

while IFS=$'\t' read -r SRC DEST; do
    if [[ -z "$SRC" || -z "$DEST" ]]; then
        echo "[SKIP] Empty line or malformed input" | tee -a "$LOGFILE"
        continue
    fi

    if [[ ! -f "$SRC" ]]; then
        echo "[ERROR] Source file not found: $SRC" | tee -a "$LOGFILE"
        continue
    fi

    BASENAME=$(basename "$SRC")
    DEST_PATH="$REMOTE_NAME:$DEST/"

    echo "[$(date '+%F %T')] Starting copy: $SRC -> $DEST_PATH" | tee -a "$LOGFILE"

    if rclone copy "$SRC" "$DEST_PATH" --progress --log-level INFO --log-file "rclone_internal_$TIMESTAMP.log"; then
        echo "✅ [$BASENAME] Copy successful." | tee -a "$LOGFILE"
    else
        echo "❌ [$BASENAME] Copy failed." | tee -a "$LOGFILE"
    fi

    echo "" | tee -a "$LOGFILE"

done < "$INPUT_TSV"

echo "Batch copy completed at $(date)" | tee -a "$LOGFILE"