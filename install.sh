#!/usr/bin/env bash
#
# install.sh
#
# Copyright 2026 m4nifest0-tech
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Scarica pve-update.sh, verifica il suo hash SHA256 rispetto al checksum
# pubblicato in questo repository e lo esegue solo se corrisponde.
#
# Uso:
#   bash -c "$(curl -fsSL https://raw.githubusercontent.com/m4nifest0-tech/pve-update/main/install.sh)"
#   bash -c "$(curl -fsSL https://raw.githubusercontent.com/m4nifest0-tech/pve-update/main/install.sh)" -- -y -k 3

set -euo pipefail

BASE_URL="https://raw.githubusercontent.com/m4nifest0-tech/pve-update/main"
SCRIPT_NAME="pve-update.sh"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

SCRIPT_PATH="$TMP_DIR/$SCRIPT_NAME"
SUM_PATH="$TMP_DIR/$SCRIPT_NAME.sha256"

echo "Download di $SCRIPT_NAME..."
curl -fsSL "$BASE_URL/$SCRIPT_NAME" -o "$SCRIPT_PATH"

echo "Download del checksum pubblicato..."
curl -fsSL "$BASE_URL/$SCRIPT_NAME.sha256" -o "$SUM_PATH"

EXPECTED_HASH="$(awk '{print $1}' "$SUM_PATH")"
ACTUAL_HASH="$(sha256sum "$SCRIPT_PATH" | awk '{print $1}')"

if [[ "$ACTUAL_HASH" != "$EXPECTED_HASH" ]]; then
echo "ERRORE: l'hash SHA256 di $SCRIPT_NAME non corrisponde a quello pubblicato." >&2
echo "Atteso:  $EXPECTED_HASH" >&2
echo "Trovato: $ACTUAL_HASH" >&2
echo "Esecuzione interrotta per sicurezza." >&2
exit 1
fi

echo "Hash verificato correttamente."
chmod +x "$SCRIPT_PATH"
exec bash "$SCRIPT_PATH" "$@"
