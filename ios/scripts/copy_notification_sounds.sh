#!/bin/sh
set -e

SOURCE_DIR="${PROJECT_DIR}/Runner/NotificationSounds"
DEST_DIR="${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"

if [ ! -d "${SOURCE_DIR}" ]; then
  echo "[iOS Sounds] Source directory missing: ${SOURCE_DIR}"
  exit 0
fi

SOUND_COUNT=$(find "${SOURCE_DIR}" -type f -name "*.caf" | wc -l | tr -d ' ')
if [ "${SOUND_COUNT}" = "0" ]; then
  echo "[iOS Sounds] No .caf files found in ${SOURCE_DIR}"
  exit 0
fi

mkdir -p "${DEST_DIR}"
find "${SOURCE_DIR}" -type f -name "*.caf" -print0 | while IFS= read -r -d '' file; do
  cp -f "${file}" "${DEST_DIR}/"
done

echo "[iOS Sounds] Copied ${SOUND_COUNT} sound file(s) to app bundle"
