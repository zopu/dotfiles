# NAS encrypted cold-archive backup (rclone → GCS Archive)

Offsite, client-side-encrypted backup of irreplaceable NAS shares to Google
Cloud Storage **Archive** class. This is the "1" of a 3-2-1 strategy: the local
fast-restore tier is Time Machine → NAS; this is the encrypted offsite tier.

- **Cost:** ~$1.2/TB/month storage (Archive, regional). ~$5/mo for ~4 TB.
  Uploads (ingest) are free. Retrieval costs ~$0.05/GB + ~$0.12/GB egress and
  has a 365-day minimum storage duration — this is a *backup*, not a live sync.
- **Encryption:** rclone `crypt` does zero-knowledge client-side encryption
  before upload. Google only ever sees ciphertext and encrypted filenames.
- **Design:** `copy`, not `sync` — additive only. A deletion on the NAS never
  propagates to the cloud copy. The service account also has **no delete
  permission** by design (bucket-level Object Viewer + Object Creator only).

## Layout (on the NAS, under `/volume1/scripts/`)

| File | Committed here? | Notes |
|------|-----------------|-------|
| `rclone-archive-backup.sh` | ✅ yes | The backup script (this repo is the source of truth). |
| `rclone` | ❌ no | The rclone binary. |
| `rclone.conf` | ❌ **never** | Contains obscured (reversible) crypt password. `chmod 600`. |
| `gcs-sa.json` | ❌ **never** | GCP service-account key. `chmod 600`. |
| `rclone-backup.log` | ❌ no | Run log. |
| `.backup.lock` | ❌ no | Atomic mkdir lock; cleared by the script's EXIT trap. |

A redacted `rclone.conf.example` is included here to document the structure.

## ⚠️ The one irreversible dependency

The crypt **password** (and **salt / `password2`**, if one was set) are escrowed
in **1Password**. They are *not* derivable from anything except the live
`rclone.conf` on the NAS. If both the NAS and the 1Password entry are lost, the
cloud copy is **permanently undecryptable**. The password is recoverable from a
live `rclone.conf` via `rclone reveal` (obscure is reversible) — but treat
1Password as the canonical store.

## Deploy / update

```sh
# Copy the script onto the NAS (scp -O forces legacy protocol for Synology sshd)
scp -O rclone-archive-backup.sh boss@<nas>:/volume1/scripts/
ssh boss@<nas> 'chmod +x /volume1/scripts/rclone-archive-backup.sh && sh -n /volume1/scripts/rclone-archive-backup.sh && echo OK'
```

## Schedule (DSM Task Scheduler)

- **Control Panel → Notification → Email** — configure sending first.
- **Task Scheduler → Create → Scheduled Task → User-defined script**
  - **User:** `root` (reads every file regardless of per-file ACLs).
  - **Schedule:** weekly, e.g. Sunday 02:00.
  - **Run command:** `sh /volume1/scripts/rclone-archive-backup.sh`
  - ✅ Send run details by email → ✅ **only when the script terminates abnormally**.

Because the scheduled job runs as `root`, do any manual reruns with `sudo` so
the root-owned log/lock stay writable.

## Verify a run

```sh
grep "=====" /volume1/scripts/rclone-backup.log | tail -8   # want exit=0 per share, no FAILURES
ls -ld /volume1/scripts/.backup.lock 2>/dev/null && echo "stale lock" || echo "clean"
```

Clear a stale lock after a crash: `rmdir /volume1/scripts/.backup.lock`.

## Restore (disaster recovery)

```sh
export RCLONE_CONFIG=/volume1/scripts/rclone.conf
# List what's there
./rclone ls "secure:Photo Backups" --gcs-no-check-bucket | head
# Restore one file / a whole share to a local path
./rclone copy "secure:Photo Backups/<file>" /volume1/restore --gcs-no-check-bucket
```

If the NAS itself is gone, recreate `rclone.conf` from the redacted template
plus the 1Password-escrowed password (+ salt), drop in a service-account key
with read access, and the same `rclone copy` restores everything.
