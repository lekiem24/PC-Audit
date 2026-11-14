# PC Audit

Read-only Windows hardware inventory. No third-party modules or administrator rights are normally required.

## Reports
- Windows edition, version, build, architecture, computer make/model
- Motherboard and BIOS
- CPU, cores/threads, clock information
- Installed RAM vs Windows-usable RAM
- Individual RAM sticks: slot, capacity, manufacturer, part number, configured and rated MHz
- GPU, Windows-reported adapter memory, driver and resolution
- Physical drives: model, media type, bus type (NVMe when exposed), capacity and health
- Logical volumes: drive letters, file systems, capacity and free space
- Enabled physical network adapters

## Run locally
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\PC-Audit.ps1
```

## Run from GitHub
After publishing this repository, inspect the script and then run:
```powershell
irm https://raw.githubusercontent.com/lekiem24/PC-Audit/main/PC-Audit.ps1 | iex
```

**Security:** `irm ... | iex` immediately executes downloaded code. Only use it from a repository you trust and after reviewing the script. Safer alternative:
```powershell
irm https://raw.githubusercontent.com/lekiem24/PC-Audit/main/PC-Audit.ps1 -OutFile .\PC-Audit.ps1
notepad .\PC-Audit.ps1
.\PC-Audit.ps1
```

## Accuracy limitations
- RAM module data/speeds depend on BIOS/SMBIOS. Configured speed is the firmware-reported operating speed; rated speed is the module-reported value. Either may be unavailable.
- Windows-reported GPU adapter memory is not guaranteed dedicated VRAM, particularly on integrated graphics.
- SSD/HDD/NVMe identification depends on the Windows Storage provider. Some RAID, USB enclosures, or older drivers may report generic values.
- A drive letter is a logical volume, not necessarily a separate physical drive.
- This script does not upload results, collect documents, or change system settings.
