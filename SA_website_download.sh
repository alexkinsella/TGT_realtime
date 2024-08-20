#!/bin/bash
while true; do
	cd /mnt/ekamsat24_share/For_Science/Situational_Awareness_Website
	lftp -e "set ssl:verify-certificate no ; mirror ; quit" https://iop.apl.washington.edu/ekamsat2024
	echo "Done SA website sync at: "
	date
	sleep 600
done