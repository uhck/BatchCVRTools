#!/bin/bash

srcdir=$1
dstdir=$2/dcm2nii
dcm_reader=$3

traverse() {
    mkdir $dstdir
    for dir in $(find $srcdir -mindepth 2 -maxdepth 2 -type d)
    do
        echo "Converting $dir"
	cd $dir
        dcm=$(find -name "*0001.dcm")
	filename=`python $dcm_reader $dcm`
	filename=${filename// /_}
        scandir=$dstdir/$filename
        mkdir $scandir
	dcm2nii -i y -p y -d y -v y -o $scandir $dir
    done
    return 0
}


echo "Running image conversion script."
traverse

