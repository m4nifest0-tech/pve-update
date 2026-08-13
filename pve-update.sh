#!/usr/bin/env bash

# pve-update.sh
#
# Copyright 2026 m4nifest0-tech
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Update, upgrade e pulizia profonda per host Proxmox VE.
# Non tocca mai: backup (vzdump), dischi/immagini VM e CT, template ISO/CT.
#
# Test automazione checksum SHA256 (verifica GitHub Action update-checksum.yml)
# Uso:
#   sudo ./pve-update.sh
#
# Opzioni:
#   -y   non chiede conferma prima di procedere
#   -r   riavvia automaticamente se necessario
#   -k N mantieni N kernel installati (default 2, incluso quello in uso)
#   -h   mostra l'help

set -euo pipefail

AUTO_YES=0
AUTO_REBOOT=0
KEEP_KERNELS=2

CY='\033[0;36m'
NC='\033[0m'

header() {
    clear
    printf "${CY}"
    cat <<"EOF"
    ____ _    ________   __  __          __      __
   / __ \ |  / / ____/  / / / /___  ____/ /___ _/ /____
  / /_/ / | / / __/    / / / / __ \/ __  / __ `/ __/ _ \
 / ____/| |/ / /___   / /_/ / /_/ / /_/ / /_/ / /_/  __/
/_/     |___/_____/   \____/ .___/\__,_/\__,_/\__/\___/
                          /_/
EOF
    printf "${NC}\n"
    echo "This script will update, upgrade and clean up this Proxmox VE host."
    echo "Non tocca mai backup (vzdump), immagini VM/CT o template."
    echo
}

usage() {
    echo "Uso: $0 [-y] [-r] [-k N]"
    echo "  -y   non chiede conferma prima di procedere"
    echo "  -r   riavvia automaticamente se necessario"
    echo "  -k N mantieni N kernel installati (default 2, incluso quello in uso)"
    exit 1
}

while getopts "yrk:h" opt; do
    case "$opt" in
        y) AUTO_YES=1 ;;
        r) AUTO_REBOOT=1 ;;
        k) KEEP_KERNELS="$OPTARG" ;;
        h) usage ;;
        *) usage ;;
    esac
done

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

if [[ "$(id -u)" -ne 0 ]]; then
    echo "Questo script deve essere eseguito come root (usa sudo)." >&2
    exit 1
fi

header

if [[ "$AUTO_YES" -ne 1 ]]; then
    read -rp "Start the Proxmox VE Update & Cleanup Script (y/n)? " ans
    [[ "$ans" =~ ^[Yy]$ ]] || { echo "Annullato."; exit 0; }
fi

if ! command -v pveversion >/dev/null 2>&1; then
    echo "Attenzione: 'pveversion' non trovato, questo non sembra un host Proxmox VE." >&2
    if [[ "$AUTO_YES" -ne 1 ]]; then
        read -rp "Continuare comunque? [y/N] " ans
        [[ "$ans" =~ ^[Yy]$ ]] || exit 1
    fi
fi

KERNEL_BEFORE="$(uname -r)"

log "=== Inizio manutenzione Proxmox ==="

log "--- apt update ---"
apt update

log "--- apt full-upgrade ---"
DEBIAN_FRONTEND=noninteractive apt full-upgrade -y

log "--- apt autoremove --purge ---"
apt autoremove --purge -y

log "--- apt autoclean / clean ---"
apt autoclean -y
apt clean

if command -v pveam >/dev/null 2>&1; then
    log "--- aggiornamento indice template PVE (pveam update) ---"
    pveam update || log "pveam update fallito (non bloccante)"
fi

# --- Rimozione kernel vecchi (mai quello in uso), header/immagini corrispondenti ---
log "--- ricerca kernel installati (mantengo $KEEP_KERNELS, incluso quello attivo: $KERNEL_BEFORE) ---"
mapfile -t KERNEL_PKGS < <(dpkg-query -W -f='${Package} ${Version}
' 'pve-kernel-[0-9]*' 2>/dev/null \
    | awk '{print $1}' | sort -V)

if [[ "${#KERNEL_PKGS[@]}" -gt "$KEEP_KERNELS" ]]; then
    TO_REMOVE=()
    KEEP_COUNT=0
    for (( idx=${#KERNEL_PKGS[@]}-1; idx>=0; idx-- )); do
        pkg="${KERNEL_PKGS[$idx]}"
        ver="${pkg#pve-kernel-}"
        if [[ "$ver" == "$KERNEL_BEFORE" ]]; then
            continue
        fi
        if [[ "$KEEP_COUNT" -lt $((KEEP_KERNELS - 1)) ]]; then
            KEEP_COUNT=$((KEEP_COUNT + 1))
            continue
        fi
        TO_REMOVE+=("$pkg")
        hdr="pve-headers-${ver}"
        dpkg -l "$hdr" >/dev/null 2>&1 && TO_REMOVE+=("$hdr")
    done

    if [[ "${#TO_REMOVE[@]}" -gt 0 ]]; then
        log "Kernel da rimuovere: ${TO_REMOVE[*]}"
        if [[ "$AUTO_YES" -ne 1 ]]; then
            read -rp "Confermi la rimozione di questi kernel? [y/N] " ans
            [[ "$ans" =~ ^[Yy]$ ]] || TO_REMOVE=()
        fi
        if [[ "${#TO_REMOVE[@]}" -gt 0 ]]; then
            apt purge -y "${TO_REMOVE[@]}"
        fi
    else
        log "Nessun kernel da rimuovere."
    fi
else
    log "Kernel installati (${#KERNEL_PKGS[@]}) entro il limite di $KEEP_KERNELS, nessuna rimozione."
fi

log "--- pulizia journal systemd (mantiene ultimi 3 giorni / max 100M) ---"
journalctl --vacuum-time=3d || true
journalctl --vacuum-size=100M || true

log "--- pulizia file temporanei più vecchi di 7 giorni (/tmp, /var/tmp) ---"
find /tmp -mindepth 1 -mtime +7 -exec rm -rf {} + 2>/dev/null || true
find /var/tmp -mindepth 1 -mtime +7 -exec rm -rf {} + 2>/dev/null || true

if [[ -d /var/crash ]]; then
    log "--- pulizia core dump in /var/crash ---"
    rm -rf /var/crash/* 2>/dev/null || true
fi

if command -v pvenode >/dev/null 2>&1; then
    log "--- versioni componenti PVE ---"
    pveversion -v || true
fi

KERNEL_AFTER="$(uname -r)"
REBOOT_NEEDED=0
if [[ -f /var/run/reboot-required ]] || [[ "$KERNEL_BEFORE" != "$KERNEL_AFTER" ]]; then
    REBOOT_NEEDED=1
fi

log "=== Manutenzione completata ==="

if [[ "$REBOOT_NEEDED" -eq 1 ]]; then
    log "È necessario un riavvio (kernel o componenti core aggiornati)."
    if [[ "$AUTO_REBOOT" -eq 1 ]]; then
        log "Riavvio automatico in corso..."
        reboot
    else
        log "Esegui 'reboot' manualmente quando opportuno (nessuna VM/CT critica in esecuzione)."
    fi
else
    log "Nessun riavvio necessario."
fi
