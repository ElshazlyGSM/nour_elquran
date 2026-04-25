#!/bin/sh
set -e

# Usage:
#   cd ios
#   sh scripts/prepare_notification_sounds.sh
#
# Requires:
#   - ffmpeg (brew install ffmpeg)

if ! command -v ffmpeg >/dev/null 2>&1; then
  echo "ffmpeg is required. Install with: brew install ffmpeg"
  exit 1
fi

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TEMP_DIR="${ROOT_DIR}/.tmp_notification_sounds"
OUT_DIR="${ROOT_DIR}/Runner/NotificationSounds"

mkdir -p "${TEMP_DIR}"
mkdir -p "${OUT_DIR}"

copy_and_convert_local() {
  src="$1"
  out="$2"
  if [ ! -f "${src}" ]; then
    echo "Missing local source: ${src} (skip)"
    return 1
  fi
  ffmpeg -y -i "${src}" -ac 1 -ar 44100 -c:a pcm_s16le "${OUT_DIR}/${out}"
}

# Local bundled sounds (prefer Android raw, then Flutter assets)
copy_and_convert_local "${ROOT_DIR}/../android/app/src/main/res/raw/a2trb.ogg" "a2trb.caf" \
  || copy_and_convert_local "${ROOT_DIR}/../assets/a2trb.ogg" "a2trb.caf" || true
copy_and_convert_local "${ROOT_DIR}/../android/app/src/main/res/raw/shoro2.ogg" "shoro2.caf" \
  || copy_and_convert_local "${ROOT_DIR}/../assets/audio/shoro2.ogg" "shoro2.caf" || true
copy_and_convert_local "${ROOT_DIR}/../android/app/src/main/res/raw/azan_alah_akbr.ogg" "azan-alah-akbr.caf" \
  || copy_and_convert_local "${ROOT_DIR}/../assets/audio/azan-alah-akbr.ogg" "azan-alah-akbr.caf" || true
copy_and_convert_local "${ROOT_DIR}/../android/app/src/main/res/raw/saly.ogg" "saly.caf" || true

echo "Done. Generated notification sounds in: ${OUT_DIR}"
