# iOS Notification Sounds Setup

This app expects these custom notification sounds in `ios/Runner/NotificationSounds`:

- `a2trb.caf`
- `shoro2.caf`
- `azan-alah-akbr.caf`
- `saly.caf`

## One-time setup on Mac

1. Install ffmpeg:
   - `brew install ffmpeg`
2. Generate the `.caf` files:
   - `cd ios`
   - `sh scripts/prepare_notification_sounds.sh`
3. Build from Xcode or Flutter as usual.

## How it is wired

- `ios/scripts/copy_notification_sounds.sh` copies every `.caf` from
  `ios/Runner/NotificationSounds` into the app bundle on each iOS build.
- The Xcode project already has a build phase named `Copy Notification Sounds`.

If a sound file is missing, iOS will fall back to default notification sound.
