# PVE Update

Script Bash per **Proxmox VE** che automatizza gli aggiornamenti del sistema e la pulizia dell'host, mantenendo intatti dati e dischi di VM e container.

## Features

* `apt update` e `full-upgrade`
* Rimozione pacchetti inutilizzati
* Pulizia cache APT
* Aggiornamento indice template Proxmox
* Rimozione automatica dei vecchi kernel
* Pulizia `systemd journal`
* Pulizia `/tmp` e `/var/tmp`
* Pulizia dei crash dump
* Rilevamento della necessita di reboot
* Reboot automatico opzionale

> Lo script non interviene sui dischi, backup, ISO o template delle VM/CT.

## Requirements

* Proxmox VE
* Bash
* Privilegi `root`
* `curl` per l'installazione diretta

## Quick Start

Il modo consigliato per eseguire lo script da remoto e tramite `install.sh`, che scarica `pve-update.sh`, verifica il suo hash SHA256 rispetto al checksum pubblicato nel repository e lo esegue solo se corrisponde:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/m4nifest0-tech/pve-update/main/install.sh)"
```

Con opzioni:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/m4nifest0-tech/pve-update/main/install.sh)" -- -y -k 3
```

Se l'hash non corrisponde, l'esecuzione viene interrotta e non viene lanciato nulla.

> **Warning:** anche con la verifica dell'hash, resta buona norma dare un'occhiata al codice prima di eseguirlo su un host di produzione.

## Verifica dell'integrita (SHA256)

Ogni versione di `pve-update.sh` ha un checksum pubblicato nel file [`pve-update.sh.sha256`](pve-update.sh.sha256), aggiornato automaticamente da una GitHub Action ad ogni modifica dello script.

Per verificare manualmente il file scaricato:

```bash
curl -fsSL https://raw.githubusercontent.com/m4nifest0-tech/pve-update/main/pve-update.sh -o pve-update.sh
curl -fsSL https://raw.githubusercontent.com/m4nifest0-tech/pve-update/main/pve-update.sh.sha256 -o pve-update.sh.sha256
sha256sum -c pve-update.sh.sha256
```

Se il controllo restituisce `OK`, il file scaricato corrisponde esattamente a quello pubblicato nel repository.

## Installation

### Clone repository

```bash
git clone https://github.com/m4nifest0-tech/pve-update.git
cd pve-update
chmod +x pve-update.sh
```

### Direct download

```bash
curl -fsSL https://raw.githubusercontent.com/m4nifest0-tech/pve-update/main/pve-update.sh -o pve-update.sh
chmod +x pve-update.sh
```

## Usage

Esecuzione standard:

```bash
sudo ./pve-update.sh
```

### Options

| Option | Description |
| :----: | ------------------------------------- |
| `-y` | Esegue senza richieste di conferma |
| `-r` | Riavvia automaticamente se necessario |
| `-k N` | Mantiene `N` kernel installati |
| `-h` | Mostra l'help |

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

### Remote execution

Il modo consigliato e tramite `install.sh` (vedi Quick Start), che verifica l'hash prima di eseguire lo script.

In alternativa e possibile eseguire `pve-update.sh` direttamente, senza verifica automatica dell'hash:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/m4nifest0-tech/pve-update/main/pve-update.sh)"
```

Con opzioni:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/m4nifest0-tech/pve-update/main/pve-update.sh)" -- -y -k 3
```

## Kernel Management

Per impostazione predefinita vengono mantenuti **2 kernel**, incluso quello attualmente in uso.

E possibile modificare il numero con:

```bash
sudo ./pve-update.sh -k 3
```

I relativi `pve-headers` dei kernel rimossi vengono eliminati quando presenti.

## Safety

Lo script opera direttamente sull'host Proxmox e utilizza comandi di sistema come:

* `apt full-upgrade`
* `apt autoremove --purge`
* `apt purge`
* `rm -rf`

Prima dell'utilizzo in produzione e consigliato verificare la presenza di backup funzionanti.

Il reboot automatico (`-r`) deve essere utilizzato esclusivamente durante una finestra di manutenzione.

## License

This project is licensed under the **Apache License 2.0**.

See the [LICENSE](LICENSE) file for details.
