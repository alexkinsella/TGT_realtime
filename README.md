# TGT_realtime

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.23695975.svg)](https://doi.org/10.5281/zenodo.23695975)

Python code for real-time processing of shipboard instruments on the R/V Thomas G. Thompson. It generates continuously updating `.nc` and `.mat` files from GPS, TSG, MET, ADCP, and WAMOS data, and computes bulk air-sea fluxes using the COARE 3.5 algorithm.

If you're heading out on a cruise aboard the Thompson, this package can help generate situational awareness files and real-time visualizations directly from shipboard data.

---

## Background

The original version was written in MATLAB by Ankitha Kannad and Alex Kinsella for the EKAMSAT IOP1 cruise (April–June 2024). The code was ported to Python for EKAMSAT IOP2 (May–June 2025) to run autonomously on a Raspberry Pi 5.

If you use this code and have suggestions or improvements, please feel free to fork the repo and open a pull request — collaboration is welcome!

---

## Getting Started on a Raspberry Pi

### 1. Install system requirements

You need Python 3.10 or newer and the [NCO](https://nco.sourceforge.net/) command-line tools (`ncks`, `ncrcat`, `ncatted`), which are used to write and join the NetCDF files:

```bash
sudo apt install python3-venv nco cifs-utils
```

### 2. Download the code

```bash
git clone https://github.com/alexkinsella/TGT_realtime.git
cd TGT_realtime
```

### 3. Set up a virtual environment

```bash
python3 -m venv tgt_realtime_venv
source tgt_realtime_venv/bin/activate
pip install -r python/requirements.txt
```

Your folder structure should look like this:

```
TGT_realtime/
├── python/
│   ├── config.py
│   ├── main.py
│   ├── ...
└── tgt_realtime_venv/
```

---

### 4. Mount the ship servers

Create the mount points and add these lines to `/etc/fstab` to mount the SMB shares at boot:

```bash
sudo mkdir -p /mnt/tgt-data /mnt/cruiseshare
```

```
# Mount tgt-data SMB share
//rvtgt.uw.edu/tgt-data      /mnt/tgt-data      cifs   guest,iocharset=utf8,vers=3.0,uid=1000,gid=1000,nofail 0 0

# Mount cruiseshare SMB share
//rvtgt.uw.edu/cruiseshare   /mnt/cruiseshare   cifs   guest,iocharset=utf8,vers=3.0,uid=1000,gid=1000,nofail 0 0
```

Apply changes with:

```bash
sudo mount -a
```

---

### 5. Create necessary directories

On the **cruiseshare server**, manually create:

```
/mnt/cruiseshare/For_Science/Situational_Awareness_Processing/data
/mnt/cruiseshare/For_Science/Situational_Awareness_Shipboard_Data
```

Other directories will be created automatically. If you encounter "Permission denied" errors when writing NetCDF files, check that the full directory path exists.

---

### 6. Configure the cruise

Edit `python/config.py`:
- **`CRUISE_ID`** — the cruise ID used in the ship's data directory (e.g., `TN444` for EKAMSAT IOP2)
- **`CRUISE_START`** — when the instruments began logging (UTC, on a 10-minute boundary)
- **`CRUISE_END`** — `None` to process up to the present, or a time to stop at (e.g., when entering an EEZ)
- **`SHAREDRIVE`**, **`DATADRIVE`** — where the shares are mounted (defaults match step 4)
- **`PERIOD_MIN`** — how often to run (default 10 minutes)

---

### 7. Run the code

Start continuous processing with:

```bash
cd python
python autorun.py
```

This processes all data since `CRUISE_START` that hasn't been processed yet, then repeats every `PERIOD_MIN` minutes. A failed run (for example, if a share is temporarily unavailable) is logged and retried at the next interval. To run the processing once, use `python main.py`.

#### Running automatically at boot (optional)

To keep the code running unattended and restart it after a reboot, create `/etc/systemd/system/tgt-realtime.service` (adjust the user and paths):

```ini
[Unit]
Description=TGT realtime situational awareness processing
After=network-online.target remote-fs.target
Wants=network-online.target

[Service]
User=pi
WorkingDirectory=/home/pi/TGT_realtime/python
ExecStart=/home/pi/TGT_realtime/tgt_realtime_venv/bin/python -u autorun.py
Restart=always
RestartSec=60

[Install]
WantedBy=multi-user.target
```

Then enable it and follow the log:

```bash
sudo systemctl enable --now tgt-realtime
journalctl -u tgt-realtime -f
```

---

## Outputs

Each instrument is binned to 1-minute resolution in 10-minute files under `Situational_Awareness_Processing/data/`, which are joined into `<instrument>_compiled.nc` and `<instrument>_compiled.mat` in `Situational_Awareness_Shipboard_Data/`. Time (`dday`) is decimal days since 2025-01-01 00:00 UTC.

Air-sea fluxes are computed with COARE 3.5 (via [pycoare](https://pypi.org/project/pycoare/)) using the median true wind of the three anemometers, bow air temperature, humidity, and pressure, and SST from the SBE38 intake temperature sensor. Sensor heights are set in `make_flux` in `data_readers.py`.

These are real-time products for situational awareness and are not quality controlled.

---

## Script Overview

The Python code (`python/`) consists of:

- `config.py` — Cruise-specific settings.
- `autorun.py` — Calls the main script at regular intervals.
- `main.py` — Main orchestrator that reads, compiles, and outputs data.
- `data_readers.py` — Reads raw data from ship instruments and bins to 1-minute resolution.
- `compilers.py` — Concatenates time chunks into `.nc` and `.mat` files.
- `utils.py` — Helper functions shared across the codebase.

The `matlab/` directory contains the original MATLAB version used on EKAMSAT IOP1 (2024). It is kept for reference and is no longer maintained. It includes `coare35vn.m` (COARE 3.5; Fairall et al., 2003; Edson et al., 2013) and an ADCP loader adapted from code by Janet Sprintall.

---

## License and Citation

Licensed under the **MIT License**.
If this software is useful for your cruise, please cite it using DOI [10.5281/zenodo.23695975](https://doi.org/10.5281/zenodo.23695975), which always points to the latest version. Full citation information is in [`CITATION.cff`](CITATION.cff) (GitHub's "Cite this repository" button).

---

## Contact

Maintainers:
- Alex Kinsella (alex.kinsella@whoi.edu)
- Ankitha Kannad (akannad@ucsd.edu)
