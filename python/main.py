import os
from datetime import datetime, timedelta, timezone
from data_readers import (
    read_gps, read_tsg, read_met, read_wamos, make_flux, subset_adcp, subset_adcp_compr
)

from compilers import compile_incremental
import config

def situational_awareness_main(sharedrive, datadrive):
    """Situational awareness processing code. Cruise settings are in config.py."""

    datadir = os.path.join(sharedrive, 'For_Science', 'Situational_Awareness_Processing', 'data')

    cruisestart = config.CRUISE_START
    cruise_ID = config.CRUISE_ID
    today = datetime.now(timezone.utc).replace(tzinfo=None, second=0, microsecond=0)
    today -= timedelta(minutes=today.minute % 10)
    cruiseend = today if config.CRUISE_END is None else min(today, config.CRUISE_END)
    print(f"Run time: {today}")

    looptime = [cruisestart + timedelta(minutes=10 * i) for i in range(int((cruiseend - cruisestart).total_seconds() // 600) + 1)]

    for i in range(len(looptime) - 1):
        logstart = looptime[i].strftime('%Y%m%d_%H%M')
        logend = looptime[i + 1].strftime('%Y%m%d_%H%M')

        gps_file = os.path.join(datadir, 'gps', f'GPS_{logstart}.nc')
        if not os.path.isfile(gps_file):
            read_gps(logstart, logend, sharedrive, datadrive, cruise_ID)

        tsg_file = os.path.join(datadir, 'tsg', f'TSG_{logstart}.nc')
        if not os.path.isfile(tsg_file):
            read_tsg(logstart, logend, sharedrive, datadrive, cruise_ID)

        met_file = os.path.join(datadir, 'met', f'MET_{logstart}.nc')
        if not os.path.isfile(met_file):
            read_met(logstart, logend, sharedrive, datadrive, cruise_ID)

        wamos_file = os.path.join(datadir, 'wamos', f'WAMOS_{logstart}.nc')
        if not os.path.isfile(wamos_file):
            read_wamos(logstart, logend, sharedrive, datadrive, cruise_ID)

    for i in range(len(looptime) - 1):
        logstart = looptime[i].strftime('%Y%m%d_%H%M')

        flux_file = os.path.join(datadir, 'flux', f'FLUX_{logstart}.nc')
        met_file = os.path.join(datadir, 'met', f'MET_{logstart}.nc')
        tsg_file = os.path.join(datadir, 'tsg', f'TSG_{logstart}.nc')

        if not os.path.isfile(flux_file) and os.path.isfile(met_file) and os.path.isfile(tsg_file):
            make_flux(logstart, sharedrive)

    subset_adcp_compr(sharedrive, datadrive, cruisestart, cruiseend, cruise_ID)


def compile_main(sharedrive):
    """Compile situational awareness data"""

    compiledir = os.path.join(sharedrive, 'For_Science', 'Situational_Awareness_Shipboard_Data')

    #compile_all(os.path.join(sharedrive, 'For_Science', 'Situational_Awareness_Processing', 'data', 'gps'), compiledir, "GPS")
    #compile_all(os.path.join(sharedrive, 'For_Science', 'Situational_Awareness_Processing', 'data', 'tsg'), compiledir, "TSG")
    #compile_all(os.path.join(sharedrive, 'For_Science', 'Situational_Awareness_Processing', 'data', 'met'), compiledir, "MET")
    #compile_all(os.path.join(sharedrive, 'For_Science', 'Situational_Awareness_Processing', 'data', 'wamos'), compiledir, "WAMOS")
    #compile_all(os.path.join(sharedrive, 'For_Science', 'Situational_Awareness_Processing', 'data', 'flux'), compiledir, "FLUX")
    #compile_all(os.path.join(sharedrive, 'For_Science', 'Situational_Awareness_Processing', 'data', 'adcp'), compiledir, "ADCP")

    compile_incremental(os.path.join(sharedrive, 'For_Science', 'Situational_Awareness_Processing', 'data', 'gps'), compiledir, "GPS")
    compile_incremental(os.path.join(sharedrive, 'For_Science', 'Situational_Awareness_Processing', 'data', 'tsg'), compiledir, "TSG")
    compile_incremental(os.path.join(sharedrive, 'For_Science', 'Situational_Awareness_Processing', 'data', 'met'), compiledir, "MET")
    compile_incremental(os.path.join(sharedrive, 'For_Science', 'Situational_Awareness_Processing', 'data', 'wamos'), compiledir, "WAMOS")
    compile_incremental(os.path.join(sharedrive, 'For_Science', 'Situational_Awareness_Processing', 'data', 'flux'), compiledir, "FLUX")


if __name__ == "__main__":
    # Single run, without the autorun loop
    situational_awareness_main(config.SHAREDRIVE, config.DATADRIVE)
    compile_main(config.SHAREDRIVE)
