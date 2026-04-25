#!/bin/sh
set -e

# Usage:
#   cd ios
#   ./scripts/prepare_notification_sounds.sh
#
# Requires:
#   - ffmpeg (brew install ffmpeg)
#   - curl (available by default on macOS)

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

download_and_convert() {
  url="$1"
  ext="$2"
  out="$3"
  tmp="${TEMP_DIR}/${out}.${ext}"
  if ! curl -L --fail --retry 3 --connect-timeout 10 "${url}" -o "${tmp}"; then
    echo "Failed to download ${url} (skip)"
    return 0
  fi
  ffmpeg -y -i "${tmp}" -ac 1 -ar 44100 -c:a pcm_s16le "${OUT_DIR}/${out}"
}

# Local bundled sounds (prefer Android raw, then Flutter assets)
copy_and_convert_local "${ROOT_DIR}/../android/app/src/main/res/raw/a2trb.ogg" "a2trb.caf" \
  || copy_and_convert_local "${ROOT_DIR}/../assets/a2trb.ogg" "a2trb.caf" || true
copy_and_convert_local "${ROOT_DIR}/../android/app/src/main/res/raw/shoro2.ogg" "shoro2.caf" \
  || copy_and_convert_local "${ROOT_DIR}/../assets/audio/shoro2.ogg" "shoro2.caf" || true
copy_and_convert_local "${ROOT_DIR}/../android/app/src/main/res/raw/azan_alah_akbr.ogg" "azan-alah-akbr.caf" \
  || copy_and_convert_local "${ROOT_DIR}/../assets/audio/azan-alah-akbr.ogg" "azan-alah-akbr.caf" || true
copy_and_convert_local "${ROOT_DIR}/../android/app/src/main/res/raw/saly.ogg" "saly.caf" || true

# Adhan profiles from production mirrors
download_and_convert "https://huggingface.co/datasets/HaoElshazly/quran_data/resolve/main/azan-nsr-elden.mp3" "mp3" "azan-nsr-elden.caf"
download_and_convert "https://huggingface.co/datasets/HaoElshazly/quran_data/resolve/main/abdelbast.ogg" "ogg" "abdelbast.caf"
download_and_convert "https://huggingface.co/datasets/HaoElshazly/quran_data/resolve/main/azan-elmnshawy.mp3" "mp3" "azan-elmnshawy.caf"
download_and_convert "https://huggingface.co/datasets/HaoElshazly/quran_data/resolve/main/azan-mowahd.mp3" "mp3" "azan-mowahd.caf"
download_and_convert "https://huggingface.co/datasets/HaoElshazly/quran_data/resolve/main/harm.ogg" "ogg" "harm.caf"
download_and_convert "https://huggingface.co/datasets/HaoElshazly/quran_data/resolve/main/mashary.ogg" "ogg" "mashary.caf"

echo "Done. Generated notification sounds in: ${OUT_DIR}"
