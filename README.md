# PVE Update

Script Bash per **Proxmox VE** che automatizza aggiornamenti del sistema e pulizia dell'host, mantenendo intatti dati e dischi di VM e container.

## Features

* `apt update` e `full-upgrade`
* Rimozione pacchetti inutilizzati
* Pulizia cache APT
* Aggiornamento indice template Proxmox
* Rimozione automatica dei vecchi kernel
* Pulizia `systemd journal`
* Pulizia `/tmp` e `/var/tmp`
* Pulizia dei crash dump
* Rilevamento della necessità di reboot
* Reboot automatico opzionale

> Lo script non interviene sui dischi, backup, ISO o template delle VM/CT.

## Requirements

* Proxmox VE
* Bash
* Privilegi `root`

## Installation

```bash
git clone https://github.com/USERNAME/pve-update.git
cd pve-update
chmod +x pve-update.sh
```

Oppure copia direttamente lo script sull'host:

```bash
chmod +x pve-update.sh
```

## Usage

Esecuzione standard:

```bash
sudo ./pve-update.sh
```

### Options

| Opzione | Descrizione                           |
| ------- | ------------------------------------- |
| `-y`    | Esegue senza richieste di conferma    |
| `-r`    | Riavvia automaticamente se necessario |
| `-k N`  | Mantiene `N` kernel installati        |
| `-h`    | Mostra l'help                         |

### Examples

```bash
# Manutenzione standard
sudo ./pve-update.sh

# Senza conferme
sudo ./pve-update.sh -y

# Mantiene 3 kernel
sudo ./pve-update.sh -k 3

# Esecuzione automatica con reboot
sudo ./pve-update.sh -y -r
```

## Kernel Management

Per impostazione predefinita vengono mantenuti **2 kernel**, incluso quello attualmente in uso.

È possibile modificare il numero con:

```bash
sudo ./pve-update.sh -k 3
```

I relativi `pve-headers` dei kernel rimossi vengono eliminati quando presenti.

## Safety

Lo script opera direttamente sull'host Proxmox e utilizza comandi di sistema come `apt purge`, `apt autoremove` e `rm -rf`.

Prima dell'utilizzo in produzione è consigliato verificare la presenza di backup funzionanti.

Il reboot automatico (`-r`) deve essere utilizzato esclusivamente durante una finestra di manutenzione.

## License

MIT
