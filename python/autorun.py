import os
import time
import traceback
from main import situational_awareness_main, compile_main
import config

def autorun(period_min, sharedrive, datadrive):
    while True:
        # Keep looping if a run fails (e.g. an SMB share drops), so the Pi
        # recovers on its own once the problem clears
        try:
            if not (os.path.isdir(sharedrive) and os.path.isdir(datadrive)):
                print(f"[WARN] {sharedrive} or {datadrive} not mounted; skipping this run.")
            else:
                situational_awareness_main(sharedrive, datadrive)
                print("Compiling files...")
                compile_main(sharedrive)
        except Exception:
            print("[ERROR] Run failed:")
            traceback.print_exc()
        print(f"Done at {time.strftime('%Y-%m-%d %H:%M:%S')}. Waiting for next run...", flush=True)
        time.sleep(60 * period_min)

if __name__ == "__main__":
    autorun(config.PERIOD_MIN, config.SHAREDRIVE, config.DATADRIVE)
