#!/bin/bash

# Path to Freesurfer subjects folder
fsdir=/home/labrat/Freesurfer

# Path to output folder for all ventricle masks
output=/home/labrat/WH_vent_masks

# String pattern to match (grabs first arg), so call the script like this:
# ./get-vent-masks.sh WH 
matchstr=$1

for dir in $(find $fsdir -mindepth 1 -maxdepth 1 -type d -name "$matchstr*")
do
    cd $dir/mri
    pid=${dir#$fsdir/}
    echo $pid
    mri_binarize --i aparc+aseg.mgz --match 4 --match 5 --match 14 --match 15 --match 24 --match 43 --match 44 --o $output/$pid.vent.mask.nii.gz
done
