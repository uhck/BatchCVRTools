#!/bin/bash

fsdir=/home/labrat/Freesurfer
matchstr=$1
dstdir=$2


for dir in $(find $fs -maxdepth 1 -mindepth 1 -type d -name "*$matchstr*")
do
    echo $dir
    pid=${dir#$fs}
    (cd $dir/mri &&

    if [ ! -d "$dstdir/$pid/masks" ]
    then
        mkdir /home/labrat/$dstdir/$pid/masks
    fi

    mri_binarize --i aparc+aseg.mgz --wm --o $dstdir/$pid/masks/wm.mask.mgz --erode 1 &&
    mri_binarize --i ribbon.mgz --match 3,42 --o $dstdir/$pid/masks/gm.mask.mgz &&
    mri_binarize --i aparc+aseg.mgz --match 1026,2026 --o $dstdir/$pid/masks/fgm.mask.mgz &&
    mri_binarize --i wmparc.mgz --match 3003,4003,3012,4012,3014,4014,3018,4018,3019,4019,3020,4020,3027,4027,3028,4028,3032,4032 --o $dstdir/$pid/masks/fwm.mask.mgz &&
    mri_binarize --i aparc+aseg.mgz --match 1025,2025,1023,2023,1010,2010 --o $dstdir/$pid/masks/bgm.mask.mgz &&
    mri_binarize --i wmparc.mgz --match 3025,4025,3029,4029,3008,4008 --o $dstdir/$pid/masks/bwm.mask.mgz &&
    mri_binarize --i aseg.mgz --match 11,50,12,51,13,52 --o $dstdir/$pid/masks/bg.mask.mgz &&
done
