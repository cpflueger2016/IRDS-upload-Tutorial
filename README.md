# IRDS-upload via Rclone to IRDS Share Transfer Tutorial

Kaya or PEB server user upload to IRDS WITHOUT the need to mount an SMB share through gio-mount.


This tutorial walks you through installing `rclone`, configuring it for SMB shares, 
creating `.tar` archives, and transferring them (including bulk transfer) to the IRDS share.

---

## 1. Install rclone with conda

You can install `rclone` from `conda-forge`:

```bash
conda install -c conda-forge rclone
```

Verify installation:

```bash
rclone version
```

---

## 2. Setup rclone to connect to the SMB share

Run the interactive configuration:

```bash
rclone config
```

Follow the prompts:

1. **`n`** — Create a new remote  
2. Name: `IRDS` (or any name you like)  
3. Storage type: type `smb`  
4. **host**: `drive.irds.uwa.edu.au`  
5. **user**: Your SMB username (e.g., `0009xxxx`)  
6. **domain**: UNIWA
7. **pass**: Your password (hidden input)  
8. Accept defaults for other settings unless required by your environment.


List a specific share and test the connection:

```bash
rclone lsf IRDS:ceps-ll-015/
```

---

## 3. Tar folders into a tarball

To compress a folder into a `.tar` archive:

```bash
tar -cvf my_folder.tar my_folder/
```

- `c` = create archive  
- `v` = verbose output  
- `f` = file name of archive

Example:

```bash
tar -cvf ~/scratch/tar_files_forIRDS_upload/experiment_01.tar experiment_01/
```

---

## 4. Upload tarball to IRDS share with rclone

To copy a single tarball with progress and verbose logs:

```bash
rclone copy ~/scratch/tar_files_forIRDS_upload/experiment_01.tar IRDS:ceps-ll-0xx/Backup_experiments/ --progress -v
```

- `--progress` shows real-time transfer stats  
- `-v` (verbose) gives detailed logging  

Dry run first (no actual transfer):

```bash
rclone copy ~/scratch/tar_files_forIRDS_upload/experiment_01.tar IRDS:ceps-ll-0xx/Backup_experiments/ --dry-run -v
```

---

## 5. Bulk transfer with `rclone_batch_copy.sh`

### Start a screen or demux session to upload in the background

Start a screen session to have the upload persistent in the background (will continue even when the ssh session terminates).

```
screen -S upload_IRDS
```

### Create the TSV list

Each line: `<local_file_path> <TAB> <remote_folder_path>`

Example `file_list.tsv`:

```
/path/to/experiment_01.tar.gz    ceps-ll-0xx/Backup_experiments
/path/to/experiment_02.tar.gz    ceps-ll-0xx/Backup_experiments
```

### Run bash script `rclone_batch_copy.sh`
`rclone_batch_copy.sh file_list.tsv IRDS`

### Script: `rclone_batch_copy.sh`

```bash
#!/bin/bash
# Usage: ./rclone_batch_copy.sh file_list.tsv IRDS

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
    DEST_DIR="$REMOTE_NAME:$DEST/"

    echo "[$(date '+%F %T')] Starting copy: $SRC -> $DEST_DIR" | tee -a "$LOGFILE"

    if rclone copy "$SRC" "$DEST_DIR" --progress --log-level INFO --log-file "rclone_internal_$TIMESTAMP.log"; then
        echo "✅ [$BASENAME] Copy successful." | tee -a "$LOGFILE"
    else
        echo "❌ [$BASENAME] Copy failed." | tee -a "$LOGFILE"
    fi

    echo "" | tee -a "$LOGFILE"
done < "$INPUT_TSV"

echo "Batch copy completed at $(date)" | tee -a "$LOGFILE"
```

Make executable:

```bash
chmod +x rclone_batch_copy.sh
```

Run:

```bash
./rclone_batch_copy.sh file_list.tsv IRDS
```

---

**Notes:**
- Use `--dry-run` in `rclone` commands to preview before actual transfer.
- Always verify large transfers with `rclone check` if possible.

---

**Generated:** 2025-08-08 06:46:50

