import time
from main import situational_awareness_main, compile_main

def autorun(period_min, sharedrive, datadrive):
    while True:
        situational_awareness_main(sharedrive, datadrive)
        print("Compiling files...")
        compile_main(sharedrive)
        print(f"Done at {time.strftime('%Y-%m-%d %H:%M:%S')}. Waiting for next run...")
        time.sleep(60 * period_min)

if __name__ == "__main__":
    PERIOD_MIN = 10  # Or set as needed
    SHAREDRIVE = "/mnt/cruiseshare/"
    #SHAREDRIVE = "/Volumes/cruiseshare/"
    DATADRIVE = "/mnt/tgt-data/"
    #DATADRIVE = "/Volumes/tgt-data/"
    autorun(PERIOD_MIN, SHAREDRIVE, DATADRIVE)
