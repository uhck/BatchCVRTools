#!/bin/bash

home=/media/labrat/830Mount/MTT
slicedir=$home/slices

#mkdir $home/$bold
#fslsplit $home/$bold $home/$bold/vol -t
# Break volumes into slices
#for vol in $(find $home -maxdepth 1 -mindepth 1 -name '*vol*.nii*')
#do
#    voldir=${vol%%.nii.gz}
#    mkdir $voldir
#    fslslice $vol $voldir/
#done

# Iterate through slice timing to get mean slice intensity values
tlist=(0 0.78 0.06 0.84 0.12 0.9 0.18 0.96 0.24 1.02 0.3 1.08 0.36 1.14 0.42 1.2 0.48 1.26 0.54 1.32 0.6 1.38 0.66 1.44 0.72)

for i in $(seq -f "%04g" 0 319); do
    c=0
    voldir=`find $slicedir -maxdepth 1 -mindepth 1 -type d -name "*vol$i*"`
    echo $voldir
    for j in $(seq -f "%04g" 0 2 24); do
        t=$(bc <<< "$i*1.5+${tlist[c]}")
        slice=`find $voldir -maxdepth 1 -mindepth 1 -type f -name "*slice*$j*.nii.gz"`
        intensity=`fslstats $slice -m`
        echo "$t, $intensity" >> $home/slice_mean_intensities.txt
        ((c=c+2))
    done
    c=1
    for j in $(seq -f "%04g" 1 2 23); do
        t=$(bc <<< "$i*1.5+${tlist[c]}")
        slice=`find $voldir -maxdepth 1 -mindepth 1 -type f -name "*slice*$j*.nii.gz"`
        intensity=`fslstats $slice -m`
        echo "$t, $intensity" >> $home/slice_mean_intensities.txt
        ((c=c+2))
    done
done
