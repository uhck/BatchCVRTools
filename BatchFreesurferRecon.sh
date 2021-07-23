#!/bin/bash
source $BATCH_CONFIG_FILE

########################################################################
# PROCESS: Runs Freesurfer recon-all on subjects listed                #
# HOW TO USE:                                                          #
# ./BatchFreesurferRecon.sh [/path/to/subject_dir]                     #
#                                                                      #
# Ex. ./BatchFreesurferRecon.sh /home/labrat/SH001 /home/labrat/WH1296 #
########################################################################



recon_all () {
    local dir=$1

    # Get SubjectID_Date and paths to T1, T2, FLAIR images (looks for both .nii and .nii.gz)
    local t1=$2
    local t2=`(find $dir -iname $T2_STR".nii.gz" -o -iname $T2_STR".nii") | head -n 1`
    local flair=`(find $dir -iname $T2_FLAIR_STR".nii.gz" -o -iname $T2_FLAIR_STR".nii") | head -n 1`
    local sid_date=$3

    # Output variables to pipeline_log.txt
    echo "[SID]" $sid_date >> $LOG_FILE
    echo "[DIR]" $dir >> $LOG_FILE
    echo "[1] Files for Freesurfer recon-all" >> $LOG_FILE
    echo "[T1] $t1" >> $LOG_FILE
    echo "[T2] $t2" >> $LOG_FILE
    echo "[FLAIR] $flair" >> $LOG_FILE

    # Run the appropriate recon-all based on which images were acquired
    if [[ $t2 != "" ]]; then
        echo "[2] Run recon-all w/ T1 and T2" >> $LOG_FILE
        /usr/local/freesurfer/bin/recon-all -s $sid_date -i $t1 -T2 $t2 -T2pial -all -openmp 12 -parallel >> $LOG_FILE
    elif [[ $flair != "" ]]; then
        echo "[2] Run recon-all w/ T1 and FLAIR" >> $LOG_FILE
        /usr/local/freesurfer/bin/recon-all -s $sid_date -i $t1 -FLAIR $flair -FLAIRpial -all -openmp 12 -parallel >> $LOG_FILE
    else
        echo "[2] Run recon-all w/ T1 only" >> $LOG_FILE
        /usr/local/freesurfer/bin/recon-all -s $sid_date -i $t1 -all -openmp 12 -parallel >> $LOG_FILE
    fi
    return 0
}



#########################
##### Main function #####
#########################

echo "Starting BatchFreesurferRecon.sh..." >> $LOG_FILE
for dir in $@; do
    # Call recon-all only if T1 can be found in the directory
    t1=`(find $dir -iname $T1_STR".nii.gz" -o -iname $T1_STR".nii") | head -n 1`
    echo $t1

    # If T1 image exists in folder,
    if [[ -f $t1 ]]; then

        # Get SubjectID_Date for each patient
        sid_date=${t1##*_}
        sid_date=${dir##*/}"_"${sid_date:0:8}

        # Runs recon-all for each subject in parallel
        recon_all "$dir" "$t1" $sid_date >> $LOG_FILE &
    else
        echo "[ERROR] No T1 to run recon-all in $dir" >> $LOG_FILE
    fi

    echo >> $LOG_FILE
done

# Waits until all processes generated from this script is completed
wait
