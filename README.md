# TGT_realtime

Python code for real-time processing of shipboard instruments on the R/V Thomas G. Thompson. It generates continuously updating `.nc` and `.mat` files from GPS, TSG, MET, and ADCP data, and computes bulk air-sea fluxes using the COARE 3.5 algorithm.

If you're heading out on a cruise aboard the Thompson, this package can help generate situational awareness files and real-time visualizations directly from shipboard data.

---

## Background

The original version was written in MATLAB by Ankitha Kannad and Alex Kinsella for the EKAMSAT IOP1 cruise (April–June 2024). The code was ported to Python for EKAMSAT IOP2 (May–June 2025) to run autonomously on a Raspberry Pi 5B.

If you use this code and have suggestions or improvements, please feel free to fork the repo and open a pull request — collaboration is welcome!

---

## Getting Started on a Raspberry Pi

### 1. Download the code

Clone the GitHub repository or download the contents of the `python/` directory manually:

```bash
git clone https://github.com/YOUR_USERNAME/TGT_realtime.git
cd TGT_realtime/python
```

### 2. Set up a virtual environment

Create a virtual environment in the parent directory and install the required packages:

```bash
cd ..
python3 -m venv tgt_realtime_venv
source tgt_realtime_venv/bin/activate   # On Windows: tgt_realtime_venv\Scripts\activate
pip install -r python/requirements.txt
```

Your folder structure should look like this:

```
TGT_realtime/
├── python/
│   ├── main.py
│   ├── ...
└── tgt_realtime_venv/
```

---

### 3. Mount the ship servers

Edit your `/etc/fstab` file to mount the SMB shares at boot:

```bash
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

### 4. Create necessary directories

On the **cruiseshare server**, manually create:

```bash
/mnt/cruiseshare/For_Science/Situational_Awareness_Processing/data
/mnt/cruiseshare/For_Science/Situational_Awareness_Processing/data/tmp
/mnt/cruiseshare/For_Science/Situational_Awareness_Shipboard_Data
```

Other directories will be created automatically. If you encounter "Permission denied" errors when writing NetCDF files, check that the full directory path exists.

---

### 5. Configure the script

At the top of `main.py`, set the following parameters:
- **Cruise start time** (when the instruments began logging)
- **Cruise end time** (default is `"now"`; adjust if, e.g., you’ve entered an EEZ)
- **Cruise ID** (e.g., `TN444` for EKAMSAT IOP2)

---

### 6. Run the code

Start continuous processing with:

```bash
python autorun.py
```

By default, this runs `main.py` every **10 minutes**.

---

## Script Overview

The codebase consists of five core files:

- `autorun.py` — Calls the main script at regular intervals.
- `main.py` — Main orchestrator that reads, compiles, and outputs data.
- `data_readers.py` — Reads raw data from ship instruments and bins to 1-minute resolution.
- `compilers.py` — Concatenates time chunks into `.nc` and `.mat` files.
- `utils.py` — Helper functions shared across the codebase.

---

## License and Citation

Licensed under the **MIT License**.  
If you use this software, please cite it appropriately. (Add DOI once available.)

---

## Contact

Maintainers:
- Alex Kinsella (alex.kinsella@whoi.edu)
- Ankitha Kannad
