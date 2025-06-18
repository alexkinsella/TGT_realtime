import os
import glob
import numpy as np
import pandas as pd
from datetime import datetime, timedelta
from scipy.interpolate import interp1d
import xarray as xr
from utils import print_status, days_since_2025, circular_mean_deg, convert_nav, make_bins
import subprocess
from scipy.io import savemat
from pycoare import coare_35

def read_gps(logstart, logend, sharedrive, datadrive, cruise_ID):
    dateFormat = '%Y%m%d_%H%M'
    tmin = datetime.strptime(logstart, dateFormat)
    tmax = datetime.strptime(logend, dateFormat)

    gpsdir = os.path.join(datadrive + cruise_ID, 'scs', 'NAV')
    savedir = os.path.join(sharedrive + 'For_Science', 'Situational_Awareness_Processing', 'data', 'gps')
    os.makedirs(savedir, exist_ok=True)

    bin_edges, bin_centers = make_bins(tmin, tmax)

    INGGA = read_gps_INGGA(gpsdir, tmin, tmax, bin_edges, bin_centers)
    INVTG = read_gps_INVTG(gpsdir, tmin, tmax, bin_edges, bin_centers)
    PASHR = read_gps_PASHR(gpsdir, tmin, tmax, bin_edges, bin_centers)

    # Check all returned with status 0 and same length
    if (INGGA['status'] == 0 and INVTG['status'] == 0 and PASHR['status'] == 0
            and len(INGGA['dd']) == len(bin_centers)
            and len(INVTG['dd']) == len(bin_centers)
            and len(PASHR['dd']) == len(bin_centers)):
        savename = os.path.join(savedir, f'GPS_{logstart}.nc')
        if os.path.isfile(savename):
            os.remove(savename)
        ds = xr.Dataset(
            {
                'dday': ('dday', bin_centers),
                'lat': ('dday', INGGA['lat']),
                'lon': ('dday', INGGA['lon']),
                'cog': ('dday', INVTG['cog']),
                'sog': ('dday', INVTG['sog']),
                'hdg': ('dday', PASHR['heading']),
                'roll': ('dday', PASHR['roll']),
                'pitch': ('dday', PASHR['pitch']),
                'heave': ('dday', PASHR['heave']),
            }
        )
        ds['lat'].attrs['units'] = 'deg'
        ds['lon'].attrs['units'] = 'deg'
        ds['cog'].attrs['units'] = 'deg'
        ds['sog'].attrs['units'] = 'km/h'
        ds['hdg'].attrs['units'] = 'deg'
        ds['roll'].attrs['units'] = 'deg'
        ds['pitch'].attrs['units'] = 'deg'
        ds['heave'].attrs['units'] = 'm'
        ds['dday'].attrs['long_name'] = 'decimal day (UTC)'
        ds['dday'].attrs['units'] = 'days since Jan 01, 2025'
        
        ds.to_netcdf('tmp.nc')
        ds.close()
        cmd = "ncks --mk_rec_dmn dday " + 'tmp.nc' + " -O -o " + savename
        subprocess.run(cmd, check=True, shell=True)
        os.remove('tmp.nc')

        print_status(f"Created GPS file for {logstart}")
    else:
        print_status(f"GPS status not ready or bin mismatch for {logstart}","WARN")

def read_gps_PASHR(gpsdir, tmin, tmax, bin_edges, bin_centers):
    result = {}
    loaddate = tmin.strftime('%Y%m%d')
    search = f'POSMV-V5-PASHR-RAW_{loaddate}-'
    raw_files = [f for f in os.listdir(gpsdir) if f.startswith(search) and f.endswith('.Raw')]
    if not raw_files:
        result['status'] = 1
        return result
    loadname = os.path.join(gpsdir, raw_files[0])
    try:
        df = pd.read_csv(loadname, header=None, delimiter=',', dtype=str, names=[str(i) for i in range(14)])
        time = df['0'] + ' ' + df['1']
        dt = pd.to_datetime(time, format='%m/%d/%Y %H:%M:%S.%f')
        dd = (dt - datetime(2025, 1, 1)).dt.total_seconds() / 86400

        heading = pd.to_numeric(df['4'], errors='coerce')
        roll = pd.to_numeric(df['6'], errors='coerce')
        pitch = pd.to_numeric(df['7'], errors='coerce')
        heave = pd.to_numeric(df['8'], errors='coerce')

        # Bin using pandas cut and groupby (faster, more robust)
        cats = pd.cut(dd, bin_edges, labels=False, include_lowest=True, right=False)
        nbin = len(bin_centers)
        heading_b = np.full(nbin, np.nan)
        roll_b = np.full(nbin, np.nan)
        pitch_b = np.full(nbin, np.nan)
        heave_b = np.full(nbin, np.nan)
        for k in range(nbin):
            idx = (cats == k)
            if np.any(idx):
                heading_b[k] = circular_mean_deg(heading[idx])
                roll_b[k] = np.nanmean(roll[idx])
                pitch_b[k] = np.nanmean(pitch[idx])
                heave_b[k] = np.nanmean(heave[idx])
        result['dd'] = bin_centers
        result['heading'] = heading_b
        result['roll'] = roll_b
        result['pitch'] = pitch_b
        result['heave'] = heave_b
        result['status'] = 0
    except Exception as e:
        print(f"PASHR error: {e}")
        result['status'] = 1
    return result

def read_gps_INVTG(gpsdir, tmin, tmax, bin_edges, bin_centers):
    result = {}
    loaddate = tmin.strftime('%Y%m%d')
    search = f'POSMV-V5-INVTG-RAW_{loaddate}-'
    raw_files = [f for f in os.listdir(gpsdir) if f.startswith(search) and f.endswith('.Raw')]
    if not raw_files:
        result['status'] = 1
        return result
    loadname = os.path.join(gpsdir, raw_files[0])
    try:
        df = pd.read_csv(loadname, header=None, delimiter=',', dtype=str, names=[str(i) for i in range(14)])
        time = df['0'] + ' ' + df['1']
        dt = pd.to_datetime(time, format='%m/%d/%Y %H:%M:%S.%f')
        dd = (dt - datetime(2025, 1, 1)).dt.total_seconds() / 86400

        cog = pd.to_numeric(df['3'], errors='coerce')
        sog = pd.to_numeric(df['9'], errors='coerce')

        # Bin using pandas cut and groupby
        cats = pd.cut(dd, bin_edges, labels=False, include_lowest=True, right=False)
        nbin = len(bin_centers)
        cog_b = np.full(nbin, np.nan)
        sog_b = np.full(nbin, np.nan)
        for k in range(nbin):
            idx = (cats == k)
            if np.any(idx):
                cog_b[k] = np.nanmean(cog[idx])
                sog_b[k] = np.nanmean(sog[idx])
        result['dd'] = bin_centers
        result['cog'] = cog_b
        result['sog'] = sog_b
        result['status'] = 0
    except Exception as e:
        print(f"INVTG error: {e}")
        result['status'] = 1
    return result

def read_gps_INGGA(gpsdir, tmin, tmax, bin_edges, bin_centers):
    result = {}
    loaddate = tmin.strftime('%Y%m%d')
    search = f'POSMV-V5-INGGA-RAW_{loaddate}-'
    raw_files = [f for f in os.listdir(gpsdir) if f.startswith(search) and f.endswith('.Raw')]
    if not raw_files:
        result['status'] = 1
        return result
    loadname = os.path.join(gpsdir, raw_files[0])
    try:
        df = pd.read_csv(
            loadname,
            header=None,
            delimiter=',',
            dtype=str,
            names=[str(i) for i in range(17)]
        )
        time = df['0'] + ' ' + df['1']
        dt = pd.to_datetime(time, format='%m/%d/%Y %H:%M:%S.%f')
        dd = (dt - datetime(2025, 1, 1)).dt.total_seconds() / 86400

        # Full arrays
        lat = pd.to_numeric(df['4'], errors='coerce')
        lat_dir = df['5'].values
        lon = pd.to_numeric(df['6'], errors='coerce')
        lon_dir = df['7'].values

        lat = convert_nav(lat)
        lon = convert_nav(lon)
        lat[lat_dir == 'S'] = -lat[lat_dir == 'S']
        lon[lon_dir == 'W'] = -lon[lon_dir == 'W']

        # Assign bins (same length/order as bin_centers)
        cats = pd.cut(dd, bin_edges, labels=False, include_lowest=True, right=False)
        nbin = len(bin_centers)
        lat_b = np.full(nbin, np.nan)
        lon_b = np.full(nbin, np.nan)
        for k in range(nbin):
            idx = (cats == k)
            if np.any(idx):
                lat_b[k] = np.nanmean(lat[idx])
                lon_b[k] = np.nanmean(lon[idx])

        result['dd'] = bin_centers
        result['lat'] = lat_b
        result['lon'] = lon_b
        result['status'] = 0
    except Exception as e:
        print(f"INGGA error: {e}")
        result['status'] = 1
        result['error'] = str(e)
    return result

def read_tsg(logstart, logend, sharedrive, datadrive, cruise_ID):
    """Create NetCDF file with TSG data for specified interval."""
    # Time conversion
    date_fmt = "%Y%m%d_%H%M"
    tmin = datetime.strptime(logstart, date_fmt)
    tmax = datetime.strptime(logend, date_fmt)
    ddmin = days_since_2025(tmin)
    ddmax = days_since_2025(tmax)

    tsgdir = f"{datadrive}/{cruise_ID}/scs/SEAWATER/"
    gpsdir = f"{sharedrive}/For_Science/Situational_Awareness_Processing/data/gps/"
    savedir = f"{sharedrive}/For_Science/Situational_Awareness_Processing/data/tsg/"
    os.makedirs(savedir, exist_ok=True)

    # Use shared binning
    bin_edges, bin_centers = make_bins(tmin, tmax)

    TSG = read_tsg_TSG(tsgdir, tmin, tmax, bin_edges, bin_centers)
    SBE38 = read_tsg_SBE38(tsgdir, tmin, tmax, bin_edges, bin_centers)

    # Save NetCDF (pseudo-code, fill in with your NetCDF/xarray writer)
    if TSG['status'] == 0 and SBE38['status'] == 0:
        try:
            fname = os.path.join(gpsdir, f"GPS_{logstart}.nc")
            # Read lat/lon from existing GPS netcdf (use xarray or netCDF4)
            import xarray as xr
            ds_gps = xr.open_dataset(fname)
            latnew = ds_gps['lat'].values
            lonnew = ds_gps['lon'].values

            # Create output structure for NetCDF writing (this is where xarray is helpful)
            import xarray as xr
            dims = ('dday',)
            data_vars = {
                'dday': (dims, TSG['dd']),
                'lat': (dims, latnew),
                'lon': (dims, lonnew),
                'T': (dims, TSG['T']),
                'intakeT': (dims, SBE38['intakeT']),
                'S': (dims, TSG['S']),
                'C': (dims, TSG['C']),
                'sound_speed': (dims, TSG['soundsp']),
            }
            ds_out = xr.Dataset(data_vars)

            ds_out['lat'].attrs['units'] = 'deg'
            ds_out['lat'].attrs['long_name'] = 'latitude'
            ds_out['lon'].attrs['units'] = 'deg'
            ds_out['lon'].attrs['long_name'] = 'longitude'
            ds_out['T'].attrs['units'] = 'deg C'
            ds_out['T'].attrs['long_name'] = 'flowthrough temperature'
            ds_out['intakeT'].attrs['units'] = 'deg C'
            ds_out['intakeT'].attrs['long_name'] = 'intake temperature'
            ds_out['S'].attrs['units'] = 'PSU'
            ds_out['S'].attrs['long_name'] = 'flowthrough salinity'
            ds_out['C'].attrs['units'] = 'V'
            ds_out['C'].attrs['long_name'] = 'flowthrough conductivity'
            ds_out['sound_speed'].attrs['units'] = 'm/s'
            ds_out['sound_speed'].attrs['long_name'] = 'flowthrough sound speed'
            ds_out['dday'].attrs['long_name'] = 'decimal day (UTC)'
            ds_out['dday'].attrs['units'] = 'days since Jan 01, 2025'

            sname = f"TSG_{logstart}.nc"
            savename = os.path.join(savedir, sname)
            if os.path.isfile(savename):
                os.remove(savename)
            ds_out.to_netcdf('tmp.nc')
            ds_out.close()
            cmd = "ncks --mk_rec_dmn dday " + 'tmp.nc' + " -O -o " + savename
            subprocess.run(cmd, check=True, shell=True)
            os.remove('tmp.nc')
            print_status(f"Created TSG file for {logstart}")
        except Exception as e:
            print_status(f"TSG: GPS data not created yet for {logstart} -- {e}","WARN")
    else:
        print(f"TSG status not ready for {logstart}","WARN")

def read_tsg_TSG(tsgdir, tmin, tmax, bin_edges, bin_centers):
    """Read and bin TSG data from .Raw file."""
    loaddate = tmin.strftime("%Y%m%d")
    searchpat = os.path.join(tsgdir, f"TSG-RAW_{loaddate}-*.Raw")
    files = glob.glob(searchpat)
    if not files:
        return {'status': 1}
    fname = files[0]
    TSG = {}

    try:
        # Read the .RAW file
        df = pd.read_csv(
            fname, delimiter=",", header=None,
            names=['date', 'time', 'T', 'C', 'S', 'soundsp'],
            dtype=str
        )
        # Convert columns
        df['T'] = pd.to_numeric(df['T'], errors='coerce')
        df['C'] = pd.to_numeric(df['C'], errors='coerce')
        df['S'] = pd.to_numeric(df['S'], errors='coerce')
        df['soundsp'] = pd.to_numeric(df['soundsp'], errors='coerce')
        df['datetime'] = pd.to_datetime(df['date'] + " " + df['time'], format="%m/%d/%Y %H:%M:%S.%f")
        df['dd'] = df['datetime'].apply(days_since_2025)

        # Only data within window
        mask = (df['dd'] >= bin_edges[0]) & (df['dd'] < bin_edges[-1])
        df = df.loc[mask]

        # Bin using pandas cut and groupby (like GPS)
        cats = pd.cut(df['dd'], bin_edges, labels=False, include_lowest=True, right=False)
        nbin = len(bin_centers)
        TSG['T'] = np.full(nbin, np.nan)
        TSG['S'] = np.full(nbin, np.nan)
        TSG['C'] = np.full(nbin, np.nan)
        TSG['soundsp'] = np.full(nbin, np.nan)
        TSG['dd'] = bin_centers
        for k in range(nbin):
            idx = (cats == k)
            if np.any(idx):
                TSG['T'][k] = np.nanmean(df['T'][idx])
                TSG['S'][k] = np.nanmean(df['S'][idx])
                TSG['C'][k] = np.nanmean(df['C'][idx])
                TSG['soundsp'][k] = np.nanmean(df['soundsp'][idx])

        TSG['status'] = 0
    except Exception as e:
        print(f"TSG: {e}")
        TSG['status'] = 1
    return TSG

def read_tsg_SBE38(tsgdir, tmin, tmax, bin_edges, bin_centers):
    """Read and bin SBE38 data from .Raw file."""
    loaddate = tmin.strftime("%Y%m%d")
    searchpat = os.path.join(tsgdir, f"SBE38-RAW_{loaddate}-*.Raw")
    files = glob.glob(searchpat)
    if not files:
        return {'status': 1}
    fname = files[0]
    SBE38 = {}
    try:
        df = pd.read_csv(fname, delimiter=",", header=None, names=['date', 'time', 'intakeT'], dtype=str)

        # Try to convert intakeT to float; non-numeric (startup text) becomes NaN
        df['intakeT'] = pd.to_numeric(df['intakeT'], errors='coerce')

        df['datetime'] = pd.to_datetime(df['date'] + " " + df['time'], format="%m/%d/%Y %H:%M:%S.%f")
        df['dd'] = df['datetime'].apply(days_since_2025)

        # Only data within window
        mask = (df['dd'] >= bin_edges[0]) & (df['dd'] < bin_edges[-1])
        df = df.loc[mask]

        # Bin using pandas cut and groupby
        cats = pd.cut(df['dd'], bin_edges, labels=False, include_lowest=True, right=False)
        nbin = len(bin_centers)
        SBE38['intakeT'] = np.full(nbin, np.nan)
        SBE38['dd'] = bin_centers
        for k in range(nbin):
            idx = (cats == k)
            if np.any(idx):
                SBE38['intakeT'][k] = np.nanmean(df['intakeT'][idx])

        SBE38['status'] = 0
    except Exception as e:
        print(f"SBE38: {e}")
        SBE38['status'] = 1
    return SBE38

def read_met(logstart, logend, sharedrive, datadrive, cruise_ID):
    """
    Entry point to process and save MET netCDF, using shared 1-min bins.
    """
    from datetime import datetime
    import os
    import xarray as xr

    dateFormat = "%Y%m%d_%H%M"
    tmin = datetime.strptime(logstart, dateFormat)
    tmax = datetime.strptime(logend, dateFormat)

    metdir = f"{datadrive}/{cruise_ID}/scs/MET/"
    gpsdir = f"{sharedrive}/For_Science/Situational_Awareness_Processing/data/gps/"
    savedir = f"{sharedrive}/For_Science/Situational_Awareness_Processing/data/met/"
    os.makedirs(savedir, exist_ok=True)

    # --- Use shared bins
    bin_edges, bin_centers = make_bins(tmin, tmax)

    SONIC   = read_met_SONIC(metdir, tmin, tmax, bin_edges, bin_centers)
    PORT_TW = read_met_BRIDGE_WIND_PORT_DRV(metdir, tmin, tmax, bin_edges, bin_centers)
    STBD_TW = read_met_BRIDGE_WIND_STBD_DRV(metdir, tmin, tmax, bin_edges, bin_centers)
    BOWMET  = read_met_BOWMET(metdir, tmin, tmax, bin_edges, bin_centers)
    RAD     = read_met_RAD(metdir, tmin, tmax, bin_edges, bin_centers)

    # Check status and matching bin sizes
    nbin = len(bin_centers)
    checks = [SONIC, PORT_TW, STBD_TW, BOWMET, RAD]
    if (all(d['status'] == 0 for d in checks)
        and all(len(d['dd']) == nbin for d in checks)):
        try:
            gps_file = os.path.join(gpsdir, f"GPS_{logstart}.nc")
            ds_gps = xr.open_dataset(gps_file)
            latnew = ds_gps['lat'].values
            lonnew = ds_gps['lon'].values

            sname = f"MET_{logstart}.nc"
            savename = os.path.join(savedir, sname)
            if os.path.isfile(savename):
                os.remove(savename)

            # Wind median
            TWS = np.vstack([SONIC["TWS"], PORT_TW["TWS"], STBD_TW["TWS"]]).T
            TWD = np.vstack([SONIC["TWD"], PORT_TW["TWD"], STBD_TW["TWD"]]).T
            TWU = -TWS * np.cos(np.deg2rad(90 - TWD))
            TWV = -TWS * np.sin(np.deg2rad(90 - TWD))
            TWU_median = np.nanmedian(TWU, axis=1)
            TWV_median = np.nanmedian(TWV, axis=1)
            TWS_median = np.sqrt(TWU_median**2 + TWV_median**2)
            TWD_median = (90 - np.rad2deg(np.arctan2(TWV_median, TWU_median)) + 180) % 360

            dims = ("dday",)
            ds_out = xr.Dataset({
                "dday":         (dims, bin_centers),
                "lat":          (dims, latnew),
                "lon":          (dims, lonnew),
                "TWS":          (dims, TWS_median),
                "TWD":          (dims, TWD_median),
                "TWS_SONIC":    (dims, SONIC["TWS"]),
                "TWD_SONIC":    (dims, SONIC["TWD"]),
                "TWS_port":     (dims, PORT_TW["TWS"]),
                "TWD_port":     (dims, PORT_TW["TWD"]),
                "TWS_stbd":     (dims, STBD_TW["TWS"]),
                "TWD_stbd":     (dims, STBD_TW["TWD"]),
                "RWS":          (dims, BOWMET["RWS"]),
                "RWD":          (dims, BOWMET["RWD"]),
                "AT":           (dims, BOWMET["AT"]),
                "RH":           (dims, BOWMET["RH"]),
                "P":            (dims, BOWMET["P"]),
                "LW":           (dims, RAD["LW"]),
                "SW":           (dims, RAD["SW"]),
            })

            # Add long_name and units attributes for each variable
            ds_out["dday"].attrs.update(long_name="decimal day (UTC)", units="days since Jan 01, 2025")
            ds_out["lat"].attrs.update(long_name="latitude", units="degrees_north")
            ds_out["lon"].attrs.update(long_name="longitude", units="degrees_east")
            ds_out["TWS"].attrs.update(long_name="median true wind speed", units="m/s")
            ds_out["TWD"].attrs.update(long_name="median true wind direction", units="degrees")
            ds_out["TWS_SONIC"].attrs.update(long_name="sonic anemometer wind speed", units="m/s")
            ds_out["TWD_SONIC"].attrs.update(long_name="sonic anemometer wind direction", units="degrees")
            ds_out["TWS_port"].attrs.update(long_name="port wind speed", units="m/s")
            ds_out["TWD_port"].attrs.update(long_name="port wind direction", units="degrees")
            ds_out["TWS_stbd"].attrs.update(long_name="starboard wind speed", units="m/s")
            ds_out["TWD_stbd"].attrs.update(long_name="starboard wind direction", units="degrees")
            ds_out["RWS"].attrs.update(long_name="bow relative wind speed", units="m/s")
            ds_out["RWD"].attrs.update(long_name="bow relative wind direction", units="degrees")
            ds_out["AT"].attrs.update(long_name="bow air temperature", units="degC")
            ds_out["RH"].attrs.update(long_name="bow relative humidity", units="%")
            ds_out["P"].attrs.update(long_name="bow air pressure", units="hPa")
            ds_out["LW"].attrs.update(long_name="longwave radiation", units="W/m^2")
            ds_out["SW"].attrs.update(long_name="shortwave radiation", units="W/m^2")

            ds_out.to_netcdf('tmp.nc')
            ds_out.close()
            cmd = "ncks --mk_rec_dmn dday " + 'tmp.nc' + " -O -o " + savename
            subprocess.run(cmd, check=True, shell=True)
            os.remove('tmp.nc')
            print_status(f"Created MET file for {logstart}")
        except Exception as e:
            print_status(f"MET: GPS data not created yet for {logstart} -- {e}","WARN")
    else:
        print_status(f"MET status not ready or bin mismatch for {logstart}","WARN")

def read_met_SONIC(metdir, tmin, tmax, bin_edges, bin_centers):
    loaddate = tmin.strftime("%Y%m%d")
    files = glob.glob(os.path.join(metdir, f"SONIC-TWIND-RAW_{loaddate}-*.Raw"))
    SONIC = {}
    if not files:
        SONIC["status"] = 1
        return SONIC

    try:
        df = pd.read_csv(files[0], delimiter=',', header=None,
                         names=['d1','d2','d3','TWS','TWD','junk1','junk2','junk3','junk4','junk5','junk6'])
        # Time conversion
        time = df['d1'] + ' ' + df['d2']
        dt = pd.to_datetime(time, format='%m/%d/%Y %H:%M:%S.%f')
        dd = (dt - pd.Timestamp("2025-01-01")).dt.total_seconds() / 86400

        # Mask to data within requested window
        mask = (dd >= bin_edges[0]) & (dd < bin_edges[-1])
        dd = dd[mask]
        TWS = pd.to_numeric(df.loc[mask, 'TWS'], errors='coerce') * 0.514444  # knots to m/s
        TWS[TWS > 100] = np.nan
        TWD = pd.to_numeric(df.loc[mask, 'TWD'], errors='coerce')

        # Assign bins
        cats = pd.cut(dd, bin_edges, labels=False, include_lowest=True, right=False)
        nbin = len(bin_centers)
        TWS_b = np.full(nbin, np.nan)
        TWD_b = np.full(nbin, np.nan)
        for k in range(nbin):
            idx = (cats == k)
            if np.any(idx):
                TWS_b[k] = np.nanmean(TWS[idx])
                TWD_b[k] = circular_mean_deg(TWD[idx])  # Circular mean for wind direction

        SONIC["dd"] = bin_centers
        SONIC["TWS"] = TWS_b
        SONIC["TWD"] = TWD_b
        SONIC["status"] = 0
    except Exception as e:
        print(f"SONIC: {e}")
        SONIC["status"] = 1
    return SONIC

def read_met_BRIDGE_WIND_PORT_DRV(metdir, tmin, tmax, bin_edges, bin_centers):
    return _read_met_bridge_wind(metdir, tmin, tmax, bin_edges, bin_centers, "PORT")

def read_met_BRIDGE_WIND_STBD_DRV(metdir, tmin, tmax, bin_edges, bin_centers):
    return _read_met_bridge_wind(metdir, tmin, tmax, bin_edges, bin_centers, "STBD")

def _read_met_bridge_wind(metdir, tmin, tmax, bin_edges, bin_centers, side):
    loaddate = tmin.strftime("%Y%m%d")
    fname = f"BRIDGE-WIND-{side}-DRV-Data_{loaddate}-*.Raw"
    files = glob.glob(os.path.join(metdir, fname))
    TW = {}
    if not files:
        TW["status"] = 1
        return TW
    try:
        df = pd.read_csv(
            files[0], delimiter=',', header=None,
            names=['d1','d2','d3','TWS','TWD','junk1','junk2','junk3','junk4','junk5','junk6']
        )
        # Time conversion
        time = df['d1'] + ' ' + df['d2']
        dt = pd.to_datetime(time, format='%m/%d/%Y %H:%M:%S.%f')
        dd = (dt - pd.Timestamp("2025-01-01")).dt.total_seconds() / 86400

        # Keep only data within bin range
        mask = (dd >= bin_edges[0]) & (dd < bin_edges[-1])
        dd = dd[mask]
        TWS = pd.to_numeric(df.loc[mask, 'TWS'], errors='coerce') * 0.514444
        TWS[TWS > 100] = np.nan
        TWD = pd.to_numeric(df.loc[mask, 'TWD'], errors='coerce')

        # Bin using pandas cut and groupby
        cats = pd.cut(dd, bin_edges, labels=False, include_lowest=True, right=False)
        nbin = len(bin_centers)
        TWS_b = np.full(nbin, np.nan)
        TWD_b = np.full(nbin, np.nan)
        for k in range(nbin):
            idx = (cats == k)
            if np.any(idx):
                TWS_b[k] = np.nanmean(TWS[idx])
                TWD_b[k] = circular_mean_deg(TWD[idx]) 

        TW["dd"] = bin_centers
        TW["TWS"] = TWS_b
        TW["TWD"] = TWD_b
        TW["status"] = 0
    except Exception as e:
        print(f"BRIDGE_WIND_{side}: {e}")
        TW["status"] = 1
    return TW

def read_met_BOWMET(metdir, tmin, tmax, bin_edges, bin_centers):
    loaddate = tmin.strftime("%Y%m%d")
    files = glob.glob(os.path.join(metdir, f"BOW-MET-RAW_{loaddate}-*.Raw"))
    BOWMET = {}
    if not files:
        BOWMET["status"] = 1
        return BOWMET
    try:
        df = pd.read_csv(files[0], delimiter=',', header=None,
                         names=['d1','d2','d3','RWS','RWD','AT','RH','P','junk1'])
        # Parse datetime and decimal day
        time = df['d1'] + ' ' + df['d2']
        dt = pd.to_datetime(time, format='%m/%d/%Y %H:%M:%S.%f')
        dd = (dt - pd.Timestamp("2025-01-01")).dt.total_seconds() / 86400

        # Only data within bin window
        mask = (dd >= bin_edges[0]) & (dd < bin_edges[-1])
        dd = dd[mask]
        RWS = pd.to_numeric(df.loc[mask, 'RWS'], errors='coerce') * 0.514444
        RWS[RWS > 100] = np.nan
        RWD = pd.to_numeric(df.loc[mask, 'RWD'], errors='coerce')
        AT = pd.to_numeric(df.loc[mask, 'AT'], errors='coerce')
        RH = pd.to_numeric(df.loc[mask, 'RH'], errors='coerce')
        P = pd.to_numeric(df.loc[mask, 'P'], errors='coerce')

        # Bin using pandas.cut and robust groupby logic
        cats = pd.cut(dd, bin_edges, labels=False, include_lowest=True, right=False)
        nbin = len(bin_centers)
        BOWMET["dd"] = bin_centers
        BOWMET["RWS"] = np.full(nbin, np.nan)
        BOWMET["RWD"] = np.full(nbin, np.nan)
        BOWMET["AT"] = np.full(nbin, np.nan)
        BOWMET["RH"] = np.full(nbin, np.nan)
        BOWMET["P"] = np.full(nbin, np.nan)
        for k in range(nbin):
            idx = (cats == k)
            if np.any(idx):
                BOWMET["RWS"][k] = np.nanmean(RWS[idx])
                BOWMET["RWD"][k] = np.nanmean(RWD[idx])
                BOWMET["AT"][k]  = np.nanmean(AT[idx])
                BOWMET["RH"][k]  = np.nanmean(RH[idx])
                BOWMET["P"][k]   = np.nanmean(P[idx])
        BOWMET["status"] = 0
    except Exception as e:
        print(f"BOWMET: {e}")
        BOWMET["status"] = 1
    return BOWMET

def read_met_RAD(metdir, tmin, tmax, bin_edges, bin_centers):

    loaddate = tmin.strftime("%Y%m%d")
    files = glob.glob(os.path.join(metdir, f"Campbell-RAD_{loaddate}-*.Raw"))
    RAD = {}
    if not files:
        RAD["status"] = 1
        return RAD
    try:
        df = pd.read_csv(files[0], delimiter=',', header=None,
                         names=['d1','d2','d3','junk1','LW','junk2','SW'])
        time = df['d1'] + ' ' + df['d2']
        dt = pd.to_datetime(time, format='%m/%d/%Y %H:%M:%S.%f')
        dd = (dt - pd.Timestamp("2025-01-01")).dt.total_seconds() / 86400

        # Only keep data within bin window
        mask = (dd >= bin_edges[0]) & (dd < bin_edges[-1])
        dd = dd[mask]
        LW = pd.to_numeric(df.loc[mask, 'LW'], errors='coerce')
        SW = pd.to_numeric(df.loc[mask, 'SW'], errors='coerce')

        # Bin using pandas.cut and robust groupby logic
        cats = pd.cut(dd, bin_edges, labels=False, include_lowest=True, right=False)
        nbin = len(bin_centers)
        RAD["dd"] = bin_centers
        RAD["LW"] = np.full(nbin, np.nan)
        RAD["SW"] = np.full(nbin, np.nan)
        for k in range(nbin):
            idx = (cats == k)
            if np.any(idx):
                RAD["LW"][k] = np.nanmean(LW[idx])
                RAD["SW"][k] = np.nanmean(SW[idx])
        RAD["status"] = 0
    except Exception as e:
        print(f"RAD: {e}")
        RAD["status"] = 1
    return RAD

def make_flux(logstart, sharedrive):
    # Constants
    zu = 22.6 # These are the heights of the sensors in meters
    zt = 15
    zq = 15
    alb = 0.1 # Albedo and emissivity are chosen as constants
    em = 0.97
    sb = 5.67e-8  # Stefan-Boltzmann constant

    # File paths
    metfile = f"{sharedrive}/For_Science/Situational_Awareness_Processing/data/met/MET_{logstart}.nc"
    tsgfile = f"{sharedrive}/For_Science/Situational_Awareness_Processing/data/tsg/TSG_{logstart}.nc"
    savename = f"{sharedrive}/For_Science/Situational_Awareness_Processing/data/flux/FLUX_{logstart}.nc"
    os.makedirs(f"{sharedrive}/For_Science/Situational_Awareness_Processing/data/flux", exist_ok=True)

    # Check for files
    if not (os.path.isfile(metfile) and os.path.isfile(tsgfile)):
        print(f"No met and/or TSG for {logstart}")
        return

    # Read data
    with xr.open_dataset(metfile) as ds_met, xr.open_dataset(tsgfile) as ds_tsg:
        TWS = ds_met['TWS'].values
        AT = ds_met['AT'].values
        RH = ds_met['RH'].values
        P = ds_met['P'].values
        SWdwn = ds_met['SW'].values
        LWdwn = ds_met['LW'].values
        lat = ds_met['lat'].values
        lon = ds_met['lon'].values
        dday = ds_met['dday'].values
        SST = ds_tsg['T'].values

    # --- Compute using COARE
    A = coare_35(
        u=TWS, zu=zu, t=AT, zt=zt, rh=RH, zq=zq, p=P, ts=SST,
        rs=SWdwn, rl=LWdwn, lat=lat
    )
    tau = A.fluxes.tau  # wind stress
    shf = A.fluxes.hsb  # sensible heat flux
    lhf = A.fluxes.hlb  # latent heat flux

    LWnet = em * (LWdwn - sb * (SST + 273.15) ** 4)
    nhf = (1 - alb) * SWdwn + LWnet - shf - lhf

    # Remove existing file if needed
    if os.path.isfile(savename):
        os.remove(savename)

    # Save to netcdf (xarray)
    ds_out = xr.Dataset(
        data_vars={
            'dday':      ('dday', dday),
            'lat':       ('dday', lat),
            'lon':       ('dday', lon),
            'tau':       ('dday', tau),
            'shf':       ('dday', shf),
            'lhf':       ('dday', lhf),
            'lwdwn':     ('dday', LWdwn),
            'swdwn':     ('dday', SWdwn),
            'nhf':       ('dday', nhf)
        }
    )

    #ds_out['dday'].attrs.update(long_name="decimal day (UTC)", units="days since Jan 01, 2025")
    ds_out['lat'].attrs.update(long_name="latitude", units="degrees_north")
    ds_out['lon'].attrs.update(long_name="longitude", units="degrees_east")
    ds_out['tau'].attrs.update(long_name="surface wind stress", units="N/m^2")
    ds_out['shf'].attrs.update(long_name="sensible heat flux", units="W/m^2")
    ds_out['lhf'].attrs.update(long_name="latent heat flux", units="W/m^2")
    ds_out['lwdwn'].attrs.update(long_name="downwelling longwave radiation", units="W/m^2")
    ds_out['swdwn'].attrs.update(long_name="downwelling shortwave radiation", units="W/m^2")
    ds_out['nhf'].attrs.update(long_name="net heat flux", units="W/m^2")

    ds_out.to_netcdf('tmp.nc')
    ds_out.close()
    cmd = "ncks --mk_rec_dmn dday " + 'tmp.nc' + " -O -o " + savename
    subprocess.run(cmd, check=True, shell=True)
    os.remove('tmp.nc')

    print(f"Created FLUX file for {logstart}")

def chunk_ADCP(sharedrive, datadrive, cruisestart, cruiseend, cruise_ID):
    # Directories
    datadir = os.path.join(sharedrive, "For_Science", "Situational_Awareness_Processing", "data", "adcp")
    os.makedirs(datadir, exist_ok=True)
    adcpsrc = os.path.join(datadrive, cruise_ID, "adcp", "proc", "wh300", "contour", "wh300.nc")

    # Load full ADCP file once
    ds = xr.open_dataset(adcpsrc)
    # Time in decimal days since Jan 1, 2025
    time_days = ds['time'].values  # Assume float (days since 2025-01-01)

    # Generate chunk intervals
    looptime = []
    t = cruisestart
    while t <= cruiseend:
        looptime.append(t)
        t += timedelta(minutes=10)
    loopfile = [dt.strftime('%Y%m%d_%H%M') for dt in looptime]

    for il in range(len(loopfile) - 1):
        outname = os.path.join(datadir, f"ADCP_{loopfile[il]}.nc")
        if not os.path.isfile(outname):
            logstart = looptime[il]
            logend = looptime[il+1]
            # Select all time points >= logstart and < logend
            mask = (time_days >= np.datetime64(logstart)) & (time_days < np.datetime64(logend))
            if np.any(mask):
                # Subset variables along 'dday' dimension (time)
                to_write = ds.isel(time=mask)
                # Save to NetCDF with appropriate attrs (optional: set chunk attrs if needed)
                to_write.to_netcdf(outname)
                cmd = f'ncks --mk_rec_dmn time "{outname}" -O -o "{outname}"'
                subprocess.run(cmd, check=True, shell=True)
                print_status(f"Created ADCP file for {loopfile[il]}","INFO")

    ds.close()


def subset_adcp(sharedrive, datadrive, cruisestart, cruiseend, cruise_ID):
    """
    Subset ADCP netcdf to time window [cruisestart, cruiseend).
    - adcpsrc: path to input ADCP netcdf file
    - outname: path to output subset netcdf
    - cruisestart, cruiseend: Python datetime objects in UTC
    """
    datadir = os.path.join(sharedrive, "For_Science", "Situational_Awareness_Processing", "data", "adcp")
    os.makedirs(datadir, exist_ok=True)
    adcpsrc = os.path.join(datadrive, cruise_ID, "adcp", "proc", "wh300", "contour", "wh300.nc")
    outname = os.path.join(sharedrive, "For_Science", "Situational_Awareness_Shipboard_Data", "adcp_compiled.nc")

    # Open dataset
    ds = xr.open_dataset(adcpsrc)

    # ADCP time variable is in 'days since 2025-01-01'
    units = ds['time'].attrs.get('units', 'days since 2025-01-01 00:00:00')
    base_date_str = units.split('since')[1].strip().split()[0]
    base_date = datetime.strptime(base_date_str, "%Y-%m-%d")
    # If there's a time (not just date)
    if len(units.split('since')[1].strip().split()) > 1:
        base_date = datetime.strptime(units.split('since')[1].strip(), "%Y-%m-%d %H:%M:%S")

    # Convert cruisestart/end to float days since base_date
    # def dt_to_days(dt):
    #     return (dt - base_date).total_seconds() / 86400

    # tmin = dt_to_days(cruisestart)
    # tmax = dt_to_days(cruiseend)

    # Mask time variable (assume variable name is 'time')
    mask = (ds['time'].values >= np.datetime64(cruisestart)) & (ds['time'].values < np.datetime64(cruiseend))
    if not np.any(mask):
        print(f"No ADCP data in window {cruisestart} to {cruiseend}")
        ds.close()
        return

    ds_sub = ds.isel(time=mask)
    ds_sub.to_netcdf(outname)
    print(f"Wrote subsetted ADCP file: {outname}")
    ds.close()

    # --- Prepare dict for .mat saving ---
    adcp_mat = {}

    for var in ds_sub.data_vars:
        arr = ds_sub[var].values
        adcp_mat[var] = arr

    # Also save coordinates (depth_cell, etc) as needed
    for coord in ds_sub.coords:
        if coord not in adcp_mat:
            if coord == 'time':
                arr = ds_sub[coord].values
                # Get units attribute, e.g. "days since 2025-01-01 00:00:00"
                units = ds_sub['time'].attrs.get('units', 'days since 2025-01-01 00:00:00')
                base_str = units.split('since')[1].strip()
                # Try both possible formats (with or without time)
                try:
                    base_date = np.datetime64(datetime.strptime(base_str, "%Y-%m-%d %H:%M:%S"))
                except ValueError:
                    base_date = np.datetime64(datetime.strptime(base_str.split()[0], "%Y-%m-%d"))
                # Convert to days since base_date
                arr = arr.astype('datetime64[s]')
                base_date = np.datetime64(base_date, 's')
                days_since = (arr - base_date) / np.timedelta64(1, 'D')
                days_since = days_since.astype(float)
                arr = np.array(days_since, dtype=float)
            adcp_mat[coord] = arr

    savemat(outname.replace('.nc', '.mat'), {'ADCP': adcp_mat})
    print_status(f"Wrote MATLAB .mat file: {outname.replace('.nc', '.mat')}")

    ds_sub.close()

def subset_adcp_compr(sharedrive, datadrive, cruisestart, cruiseend, cruise_ID):
    """
    Concatenate and subset daily ADCP netcdf files to time window [cruisestart, cruiseend).
    """
    adcpdir = os.path.join(datadrive, cruise_ID, "adcp", "proc", "wh300", "contour")
    datadir = os.path.join(sharedrive, "For_Science", "Situational_Awareness_Processing", "data", "adcp")
    os.makedirs(datadir, exist_ok=True)
    compiled_nc = os.path.join(datadir, "adcp_compiled_ship.nc")
    outname = os.path.join(sharedrive, "For_Science", "Situational_Awareness_Shipboard_Data", "adcp_compiled.nc")
    outmat = outname.replace('.nc', '.mat')

    # --- Find and filter files ---
    files = sorted(glob.glob(os.path.join(adcpdir, "wh300_*_compr.nc")))
    selected = []
    for f in files:
        try:
            yd = int(os.path.basename(f).split('_')[1])
            if yd >= 146:
                selected.append(f)
        except Exception:
            continue

    if not selected:
        print("No ADCP daily files found for cruise window.")
        return

    # --- Ensure 'time' is unlimited for each file ---
    rec_files = []
    for f in selected:
        fname = os.path.basename(f)
        rec_file = os.path.join(datadir, fname + ".rec.nc")
        try:
            cmd = ["ncks", "--mk_rec_dmn", "time", f, "-O", "-o", rec_file]
            subprocess.run(cmd, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        except Exception as e:
            print(f"[WARN] Skipping corrupted ADCP file: {f}")
            continue
        rec_files.append(rec_file)

    # --- Concatenate along unlimited 'time' dimension ---
    #if not os.path.isfile(compiled_nc):
    cmd = ['ncrcat','-O'] + rec_files + [compiled_nc]
    subprocess.run(cmd, check=True)
    print(f"Concatenated {len(rec_files)} ADCP daily files to {compiled_nc}")

    # --- Subset and save ---
    ds = xr.open_dataset(compiled_nc)
    units = ds['time'].attrs.get('units', 'days since 2025-01-01 00:00:00')
    base_date_str = units.split('since')[1].strip().split()[0]
    base_date = datetime.strptime(base_date_str, "%Y-%m-%d")
    if len(units.split('since')[1].strip().split()) > 1:
        base_date = datetime.strptime(units.split('since')[1].strip(), "%Y-%m-%d %H:%M:%S")

    tmin = (cruisestart - base_date).total_seconds() / 86400
    tmax = (cruiseend - base_date).total_seconds() / 86400
    tmin_dt64 = np.datetime64(base_date) + np.timedelta64(int(tmin * 86400), 's')
    tmax_dt64 = np.datetime64(base_date) + np.timedelta64(int(tmax * 86400), 's')

    mask = (ds['time'].values >= tmin_dt64) & (ds['time'].values < tmax_dt64)
    if not np.any(mask):
        print(f"No ADCP data in window {cruisestart} to {cruiseend}")
        ds.close()
        return

    ds_sub = ds.isel(time=mask)
    ds_sub.to_netcdf(outname)
    print(f"Wrote subsetted ADCP file: {outname}")

    # --- Save to .mat (with days since base) ---
    adcp_mat = {}
    for var in ds_sub.data_vars:
        arr = ds_sub[var].values
        adcp_mat[var] = arr
    for coord in ds_sub.coords:
        if coord not in adcp_mat:
            if coord == 'time':
                arr = ds_sub[coord].values
                #adcp_mat[coord] = arr.astype(float)
                adcp_mat[coord] = (arr-np.datetime64(base_date))/ np.timedelta64(1, 'D')
            else:
                adcp_mat[coord] = ds_sub[coord].values

    savemat(outmat, {'ADCP': adcp_mat})
    print(f"Wrote MATLAB .mat file: {outmat}")
    ds_sub.close()

def read_wamos(logstart, logend, sharedrive, datadrive, cruise_ID):
    """Create netcdf file with WAMOS data for specified start and end time."""
    from datetime import datetime
    from netCDF4 import Dataset
    from scipy.interpolate import interp1d

    # Parse datetime
    date_format = "%Y%m%d_%H%M"
    tmin = datetime.strptime(logstart, date_format)
    tmax = datetime.strptime(logend, date_format)

    # Directories
    wamosdir = f"{datadrive}/{cruise_ID}/scs/ANCILLARY/"
    gpsdir = f"{sharedrive}/For_Science/Situational_Awareness_Processing/data/gps/"
    savedir = f"{sharedrive}/For_Science/Situational_Awareness_Processing/data/wamos/"
    os.makedirs(savedir, exist_ok=True)

    # Make 1-min bins
    bin_edges, bin_centers = make_bins(tmin, tmax)

    # Read and bin WAMOS data
    WAMOS = read_wamos_WAMOS(wamosdir, tmin, tmax, bin_edges, bin_centers)

    if WAMOS["status"] == 0:
        sname = f"WAMOS_{logstart}.nc"
        savename = os.path.join(savedir, sname)

        try:
            # Load position data
            fname = os.path.join(gpsdir, f"GPS_{logstart}.nc")
            with Dataset(fname) as ds:
                dd = ds.variables['dday'][:]
                lat = ds.variables['lat'][:]
                lon = ds.variables['lon'][:]
            # Interpolate lat/lon to WAMOS bin centers
            lat_interp = interp1d(dd, lat, bounds_error=False, fill_value="extrapolate")
            lon_interp = interp1d(dd, lon, bounds_error=False, fill_value="extrapolate")
            WAMOS['lat'] = lat_interp(bin_centers)
            WAMOS['lon'] = lon_interp(bin_centers)
            WAMOS['dd'] = bin_centers

            # Delete existing file if exists
            if os.path.isfile(savename):
                os.remove(savename)

            # Save to netCDF
            save_wamos_to_netcdf(savename, WAMOS)

            print_status(f"Created WAMOS file for {logstart}")

        except Exception as e:
            print(f"WAMOS: GPS data not created yet for {logstart}: {e}")
    else:
        print(f"WAMOS status not ready for {logstart}")

def read_wamos_WAMOS(wamosdir, tmin, tmax, bin_edges, bin_centers):
    """
    Read WAMOS raw file for the given time window and bin.
    Returns a dict with binned wave parameters and a 'status' flag.
    """
    import numpy as np
    import pandas as pd
    from datetime import datetime
    import glob
    import warnings

    WAMOS = {}
    try:
        loaddate = tmin.strftime("%Y%m%d")
        files = glob.glob(os.path.join(wamosdir, f"WAMOS-RAW_{loaddate}-*.Raw"))
        if not files:
            WAMOS["status"] = 1
            return WAMOS
        loadname = files[0]

        # col_names = [
        #     'date', 'time', 'a', 'sig_wave_h', 'mean_period', 'peak_wavedir',
        #     'peak_waveperiod', 'peak_wavelength', 'swell_wavedir', 'swell_waveperiod',
        #     'swell_wavelength', 'wind_seawave_dir', 'wind_seawave_waveperiod',
        #     'wind_seawave_currentdir', 'currentdir', 'currentspeed', 'b', 'c', 'd', 'e'
        # ]
        # df = pd.read_csv(loadname, header=None, names=col_names, delimiter=',', engine='python')
        col_names = [
        'date', 'time', 'a', 'sig_wave_h', 'mean_period', 'peak_wavedir',
        'peak_waveperiod', 'peak_wavelength', 'swell_wavedir', 'swell_waveperiod',
        'swell_wavelength', 'wind_seawave_dir', 'wind_seawave_waveperiod',
        'wind_seawave_currentdir', 'currentdir', 'currentspeed', 'b', 'c', 'd', 'e'
        ]
        N_expected = len(col_names)

        rows = []
        with open(loadname, 'r') as f:
            for linenum, line in enumerate(f, 1):
                # Split on comma, strip whitespace and newline
                parts = [p.strip() for p in line.rstrip('\n').split(',')]
                if len(parts) < N_expected:
                    # Pad with empty strings (interpreted as NaN later)
                    parts += [np.nan] * (N_expected - len(parts))
                elif len(parts) > N_expected:
                    print(f"WAMOS reader: Line {linenum} has {len(parts)} entries, expected {N_expected}. Filling with NaN.")
                    parts = parts[:N_expected]  # Truncate extras
                rows.append(parts)

        df = pd.DataFrame(rows, columns=col_names)
        dt = pd.to_datetime(df['date'] + ' ' + df['time'], format='%m/%d/%Y %H:%M:%S.%f', errors='coerce')
        dd = (dt - datetime(2025, 1, 1)).dt.total_seconds() / 86400

        # Only keep valid times
        valid = ~np.isnan(dd)
        df = df.loc[valid]
        dd = dd[valid]

        # Only data within window
        mask = (dd >= bin_edges[0]) & (dd < bin_edges[-1])
        df = df.loc[mask]
        dd = dd[mask]

        # Bin using pandas cut
        cats = pd.cut(dd, bin_edges, labels=False, include_lowest=True, right=False)
        nbin = len(bin_centers)
        def safe_nan(series):  # -5 is sometimes fill
            arr = pd.to_numeric(series, errors='coerce').values
            arr[arr < -5] = np.nan
            return arr

        binned = {}
        for key in ['sig_wave_h','mean_period','peak_wavedir','peak_waveperiod','peak_wavelength',
                    'swell_wavedir','swell_waveperiod','swell_wavelength',
                    'wind_seawave_dir','wind_seawave_waveperiod','wind_seawave_currentdir',
                    'currentdir','currentspeed']:
            binned[key] = np.full(nbin, np.nan)
            vals = safe_nan(df[key])
            for k in range(nbin):
                idx = (cats == k)
                if np.any(idx):
                    with warnings.catch_warnings():
                        warnings.simplefilter("ignore", category=RuntimeWarning)
                        binned[key][k] = np.nanmean(vals[idx])

        for k in binned:
            WAMOS[k] = binned[k]
        WAMOS['status'] = 0
    except Exception as e:
        print(f"WAMOS binning: {e}")
        WAMOS['status'] = 1
    return WAMOS

def save_wamos_to_netcdf(savename, WAMOS):
    """Write WAMOS dictionary to a netCDF file using xarray."""
    ds = xr.Dataset(
        {
            #"dday": ("dday", WAMOS['dd']),
            "lat": ("dday", WAMOS['lat']),
            "lon": ("dday", WAMOS['lon']),
            "sig_wave_h": ("dday", WAMOS['sig_wave_h']),
            "mean_period": ("dday", WAMOS['mean_period']),
            "peak_wavedir": ("dday", WAMOS['peak_wavedir']),
            "peak_waveperiod": ("dday", WAMOS['peak_waveperiod']),
            "peak_wavelength": ("dday", WAMOS['peak_wavelength']),
            "swell_wavedir": ("dday", WAMOS['swell_wavedir']),
            "swell_waveperiod": ("dday", WAMOS['swell_waveperiod']),
            "swell_wavelength": ("dday", WAMOS['swell_wavelength']),
            "wind_seawave_dir": ("dday", WAMOS['wind_seawave_dir']),
            "wind_seawave_waveperiod": ("dday", WAMOS['wind_seawave_waveperiod']),
            "wind_seawave_currentdir": ("dday", WAMOS['wind_seawave_currentdir']),
            "currentdir": ("dday", WAMOS['currentdir']),
            "currentspeed": ("dday", WAMOS['currentspeed']),
        },
        coords={"dday": WAMOS['dd']},
    )

    # Add attributes (optional)
    ds['dday'].attrs = {
        'long_name': 'decimal day (UTC)',
        'units': 'days since Jan 01, 2025'
    }
    ds['lat'].attrs = {'long_name': 'latitude', 'units': 'deg'}
    ds['lon'].attrs = {'long_name': 'longitude', 'units': 'deg'}
    ds['sig_wave_h'].attrs = {'long_name': 'significant wave height', 'units': 'm'}
    ds['mean_period'].attrs = {'long_name': 'mean period', 'units': 's'}
    ds['peak_wavedir'].attrs = {'long_name': 'peak wave direction', 'units': 'deg (coming from)'}
    ds['peak_waveperiod'].attrs = {'long_name': 'peak wave period', 'units': 's'}
    ds['peak_wavelength'].attrs = {'long_name': 'peak wavelength', 'units': 'm'}
    ds['swell_wavedir'].attrs = {'long_name': 'swell wave direction', 'units': 'deg (coming from)'}
    ds['swell_waveperiod'].attrs = {'long_name': 'swell wave period', 'units': 's'}
    ds['swell_wavelength'].attrs = {'long_name': 'swell wavelength', 'units': 'm'}
    ds['wind_seawave_dir'].attrs = {'long_name': 'wind sea wave direction', 'units': 'deg (coming from)'}
    ds['wind_seawave_waveperiod'].attrs = {'long_name': 'wind sea wave period', 'units': 's'}
    ds['wind_seawave_currentdir'].attrs = {'long_name': 'wind sea wave current direction', 'units': 'deg'}
    ds['currentdir'].attrs = {'long_name': 'current direction', 'units': 'deg'}
    ds['currentspeed'].attrs = {'long_name': 'current speed', 'units': 'm/s'}

    ds.to_netcdf('tmp.nc')
    ds.close()
    cmd = f'ncks --mk_rec_dmn dday tmp.nc -O -o "{savename}"'
    subprocess.run(cmd, check=True, shell=True)
    os.remove('tmp.nc')
