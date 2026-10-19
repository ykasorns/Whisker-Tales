#!/bin/sh
# Copies the game's data files into the app bundle (Flutter assets must live
# inside the app package). Run after editing design/balance or design/data;
# app/test/content_sync_test.dart fails when the copies are stale.
set -e
cd "$(dirname "$0")/.."
dest=app/assets/content
rm -rf "$dest"
mkdir -p "$dest/design/balance" "$dest/design/data"
cp design/balance/idle_balance_v1.json "$dest/design/balance/"
cp design/data/*.json "$dest/design/data/"
echo "synced $(ls "$dest/design/data" | wc -l | tr -d ' ') data files + balance into $dest"
