import xarray as xr
import numpy as np
import glob
import os
import subprocess
import shutil
from scipy.io import savemat
from utils import print_status
from datetime import datetime, timedelta


def save_mat(ds, matname, nameUpper):
    """
    Save xarray.Dataset to a MATLAB .mat file as a struct.
    """
    base = np.datetime64("2025-01-01")

    mdict = {}
    for v in ds.data_vars:
        arr = ds[v].values
        # Force conversion for 'dday' (or 'time' if that's what your file uses)
        if v == 'dday':
            # If float, assume already in days; if not, convert from datetime64
            if np.issubdtype(arr.dtype, np.datetime64):
                arr = (arr - base) / np.timedelta64(1, 'D')
                arr = arr.astype(float)
        mdict[v] = arr
    # Add coords if not in data_vars
    for c in ds.coords:
        if c not in mdict:
            arr = ds[c].values
            if c == 'dday':
                if np.issubdtype(arr.dtype, np.datetime64):
                    arr = (arr - base) / np.timedelta64(1, 'D')
                    arr = arr.astype(float)
            mdict[c] = arr
    savemat(matname, {nameUpper: mdict})
    print_status(f"Wrote {matname}")

def compile_all(datadir, compiledir, nameUpper):
    """Concatenate all data .nc files into one compiled NetCDF using ncrcat."""
    files = sorted(glob.glob(os.path.join(datadir, nameUpper+"*.nc")))
    if not files:
        print(f"No data files found in {datadir}")
        return

    savename = os.path.join(compiledir, nameUpper.lower()+"_compiled.nc")

    # Remove existing output file if needed
    if os.path.isfile(savename):
        os.remove(savename)

    # Use ncrcat for fast concatenation
    try:
        # ncrcat does not accept wildcards in quotes; expand list
        cmd = ['ncrcat'] + files + [savename]
        subprocess.run(cmd, check=True)
        cmd = 'ncatted -a history,global,d,, ' + [savename]
        subprocess.run(cmd, check=True, shell=True)
        print_status(f"Wrote {savename}","INFO")
    except Exception as e:
        print_status(f"ncrcat failed: {e}","ERROR")
        return

    # Save .mat 
    ds_combined = xr.open_dataset(savename)
    savename_mat = os.path.join(compiledir, nameUpper.lower()+"_compiled.mat")
    save_mat(ds_combined, savename_mat)
    ds_combined.close()

import glob, os, subprocess, shutil
import xarray as xr

def extract_file_time(filename, prefix):
    basename = os.path.basename(filename)
    # Split on the first underscore and remove extension
    dt_str = basename.split("_", 1)[1].replace(".nc", "")
    return dt_str

def last_compiled_datetime(compiled_nc, ref_datetime=datetime(2025,1,1)):
    ds = xr.open_dataset(compiled_nc)
    dday = ds['dday'].values
    ds.close()
    if dday.size == 0:
        return ref_datetime  # If empty, return reference
    last_days = dday[-1]
    return last_days

def files_to_add(files, prefix, last_dt):
    result = []
    ref = np.datetime64('2025-01-01T00:00')
    is_float = isinstance(last_dt, float) or np.issubdtype(type(last_dt), np.floating)
    for f in files:
        try:
            file_time_str = extract_file_time(f, prefix)  # Should be 'YYYYMMDD_HHMM'
            # Convert 'YYYYMMDD_HHMM' to 'YYYY-MM-DDTHH:MM'
            file_time_fmt = f"{file_time_str[:4]}-{file_time_str[4:6]}-{file_time_str[6:8]}T{file_time_str[9:11]}:{file_time_str[11:]}"
            file_dt = np.datetime64(file_time_fmt)  # ns precision
            
            if is_float:
                delta = (file_dt - ref).astype('timedelta64[ns]').astype(float) / (24 * 60 * 60 * 1e9)  # Fractional days
                if delta > last_dt:
                    result.append(f)
            else:
                if file_dt > last_dt:
                    result.append(f)
        except Exception as e:
            print(f"Skipping file {f}: {e}")
            continue
    return sorted(result)

def compile_incremental(datadir, compiledir, nameUpper):
    files = sorted(glob.glob(os.path.join(datadir, nameUpper + "*.nc")))
    if not files:
        print(f"No data files found in {datadir}")
        return

    compiled_nc = os.path.join(compiledir, nameUpper.lower() + "_compiled.nc")
    compiled_mat = os.path.join(compiledir, nameUpper.lower() + "_compiled.mat")

    if not os.path.isfile(compiled_nc):
        print(nameUpper + ": No compiled file found; running full compilation with ncrcat.")
        cmd = ['ncrcat'] + files + [compiled_nc]
        try:
            subprocess.run(cmd, check=True)
            cmd = ['ncatted', '-a', 'history,global,d,,', compiled_nc] # Remove long history 
            subprocess.run(cmd, check=True)
            print_status(f"Wrote {compiled_nc}", "INFO")
        except Exception as e:
            print_status(f"ncrcat failed: {e}", "ERROR")
            return
        ds_combined = xr.open_dataset(compiled_nc)
        save_mat(ds_combined, compiled_mat, nameUpper)
        ds_combined.close()
        return

    # Use only filenames to filter
    last_dt = last_compiled_datetime(compiled_nc)
    add_files = files_to_add(files, nameUpper+'_', last_dt)

    if not add_files:
        print("No new files to add.")
        return

    print(f"Appending {len(add_files)} new files.")
    cmd = ['ncrcat', compiled_nc] + add_files + [compiled_nc + ".tmp"]
    try:
        subprocess.run(cmd, check=True)
        shutil.move(compiled_nc + ".tmp", compiled_nc)
        cmd = ['ncatted', '-a', 'history,global,d,,', compiled_nc] # Remove long history 
        subprocess.run(cmd, check=True)
        print_status(f"Updated {compiled_nc}", "INFO")
    except Exception as e:
        print_status(f"ncrcat failed: {e}", "ERROR")
        return

    ds_combined = xr.open_dataset(compiled_nc)
    save_mat(ds_combined, compiled_mat, nameUpper)
    ds_combined.close()
