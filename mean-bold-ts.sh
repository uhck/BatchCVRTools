#!/bin/bash

home=~/SH

for dir in $(find $home -mindepth 1 -maxdepth 1 -type d -name "$1*")
do
	pid=${dir#$home/}
	echo "Getting mean time series for $pid"

	if [ -e $dir/raw/bold.txt ]
	then
		rm -r $dir/raw/bold.txt
	fi

	if [ -e $dir/raw/bold.nii.gz ]
	then
		echo "[1] BETing the BOLD image"
		fsl5.0-bet $dir/raw/bold.nii.gz $dir/raw/bold.bet.nii.gz -F
		echo "[2] Getting mean time series from BET'd BOLD image"
		fsl5.0-fslmeants -i $dir/raw/bold.bet.nii.gz -o $dir/raw/bold.txt
		echo "[3] Removing the BET'd BOLD image"
		rm -r $dir/raw/bold.bet.nii.gz
	fi
done
