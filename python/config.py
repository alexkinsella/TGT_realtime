"""Cruise-specific settings. Edit this file before each cruise."""
from datetime import datetime

# Cruise ID, as used in the ship's data directory (e.g. /mnt/tgt-data/TN444)
CRUISE_ID = 'TN444'

# When the ship's instruments began logging for this cruise (UTC).
# Must fall on a 10-minute boundary (e.g. 19:30, not 19:35).
CRUISE_START = datetime(2025, 5, 27, 19, 30, 0)

# Stop processing at this time (UTC), e.g. when entering an EEZ.
# None means process up to the present.
CRUISE_END = None

# Mount points of the ship's SMB shares (see README)
SHAREDRIVE = '/mnt/cruiseshare/'  # macOS: '/Volumes/cruiseshare/'
DATADRIVE = '/mnt/tgt-data/'      # macOS: '/Volumes/tgt-data/'

# How often autorun.py runs the processing, in minutes
PERIOD_MIN = 10
