import numpy as np
import pandas as pd
import glob
import os
from datetime import datetime, timedelta


def average_WD(wd_arr):
    # Wind direction averaging (in degrees)
    wd_arr = np.asarray(wd_arr)
    if len(wd_arr) == 0 or np.all(np.isnan(wd_arr)):
        return np.nan
    radians = np.deg2rad(wd_arr)
    sin_sum = np.nanmean(np.sin(radians))
    cos_sum = np.nanmean(np.cos(radians))
    avg_rad = np.arctan2(sin_sum, cos_sum)
    avg_deg = np.rad2deg(avg_rad)
    avg_deg = avg_deg % 360
    return avg_deg

def print_status(msg, kind='INFO'):
    print(f"[{kind}] {msg}")

def days_since_2025(dt):
    return (dt - datetime(2025, 1, 1)).total_seconds() / 86400

def circular_mean_deg(arr):
    """Compute circular mean of angles in degrees, ignoring nans."""
    arr = np.asarray(arr)
    arr = arr[~np.isnan(arr)]
    if len(arr) == 0:
        return np.nan
    # Convert degrees to radians
    radians = np.deg2rad(arr)
    mean_angle = np.arctan2(np.nanmean(np.sin(radians)), np.nanmean(np.cos(radians)))
    # Convert back to degrees and ensure 0-360 range
    mean_deg = np.rad2deg(mean_angle) % 360
    return mean_deg

def convert_nav(raw):
    """Convert NMEA position strings like 4112.345 to decimal degrees."""
    raw = np.array(raw, dtype=str)
    vals = []
    for r in raw:
        if not r or r == 'nan':
            vals.append(np.nan)
            continue
        if '.' in r:
            parts = r.split('.')
            degrees = int(parts[0][:-2])
            minutes = float(parts[0][-2:] + '.' + parts[1])
        else:
            degrees = int(r[:-2])
            minutes = float(r[-2:])
        vals.append(degrees + minutes / 60)
    return np.array(vals)

def make_bins(tmin, tmax):
    """Return bin centers and left/right edges for 1-minute bins within [tmin, tmax)."""
    ddmin = days_since_2025(tmin)
    ddmax = days_since_2025(tmax)
    # Bin edges every 1 minute
    bin_edges = np.arange(ddmin, ddmax + 1e-10, 1/1440)
    # Bin centers offset by +0.5 min (30s)
    bin_centers = bin_edges[:-1] + 0.5/1440
    return bin_edges, bin_centers

def days_to_datetime64(days, ref=np.datetime64('2025-01-01T00:00:00')):
    # days: array-like of floats (days since ref)
    ms_per_day = 24 * 60 * 60 * 1000
    ms = np.array(days) * ms_per_day
    # Add to reference date in milliseconds
    return ref + ms.astype('timedelta64[ms]')