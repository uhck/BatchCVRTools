#!/bin/bash
source $BATCH_CONFIG_FILE 

#####################################################################################
# PROCESS: Compile brain volumes and cortical thickness from Freesurfer             # 
# for multiple subjects                                                             #
# HOW TO USE:                                                                       #
# ./GetBrainVolsAndCortThick.sh [-i subject folder] -o [output directory]           #
#                                                                                   #
# EX: ./GetBrainVolsAndCortThick.sh -i /home/labrat/SH003 -i /home/labrat/BR022     #
#      -o /home/labrat/folder                                                       #
#####################################################################################



get_inputs() {
    # For each input subject directory,
    for input in ${inputs[@]}; do
        # Removes path to get just Subject ID from directory name
        subj_id=${input##*/}
        subj_id=${subj_id%%_*}

        # Finds Freesurfer folder that matches Subject ID
        for subjdir in $(find $SUBJECTS_DIR -mindepth 1 -maxdepth 1 -name "*$subj_id*"); do
            echo "[1] Found $subjdir" >> $LOG_FILE
            # Gets SubjectID_Date and append it to the Subject List
            subjdir=${subjdir##*/}
            subj_list="$subj_list $subjdir"
        done
    done

    # Outputs list of subject directories in Freesurfer subjects folder
    echo "[1] Subject List: $subj_list" >> $LOG_FILE
}



get_brain_vols_cortical_thickness() {
    # If subject list isn't empty,
    if [[ subj_list != "" ]]; then
        # Get brain volumes and cortical thickness for all subjects and output into date_time
        # Skips any subjects in which we cannot find the .stats file. Default behavior is to exit program.
        echo "[2] Writing volume stats to table" >> $LOG_FILE
        python2 $FREESURFER_HOME/bin/asegstats2table --subjects $subj_list --meas volume --skip --tablefile $out_dir/Seg_BrainVol.txt
        python2 $FREESURFER_HOME/bin/aparcstats2table --subjects $subj_list --meas volume --skip --hemi lh --tablefile $out_dir/Parc_LH_BrainVol.txt
        python2 $FREESURFER_HOME/bin/aparcstats2table --subjects $subj_list --meas volume --skip --hemi rh --tablefile $out_dir/Parc_RH_BrainVol.txt
        python2 $FREESURFER_HOME/bin/aparcstats2table --subjects $subj_list --meas thickness --skip --hemi lh --tablefile $out_dir/Parc_LH_CortThick.txt
        python2 $FREESURFER_HOME/bin/aparcstats2table --subjects $subj_list --meas thickness --skip --hemi rh --tablefile $out_dir/Parc_LH_CortThick.txt
    else
        echo "[2] No subjects found" >> $LOG_FILE
    fi
}



########################
#####  Main script #####
########################

subj_list=""

# Getopts
while getopts ':i:o:' OPTION; do
    case "$OPTION" in
        i)
            inputs+=("$OPTARG")
            ;;
        o)
            out_dir="$OPTARG"
            ;;
        ?)
            echo "Usage: ./GetBrainVolsAndCortThick.sh [-i subject folder] -o [output directory]"
            exit 1
            ;;
    esac
done
shift $((OPTIND-1))

# Make directory in output folder with Date_Time
date_time=`date "+20%y%m%d_%H%M%S"`
out_dir=$out_dir"/BrainVolsAndCortThick_"$date_time
mkdir $out_dir

echo "Starting GetBrainVolsAndCortThick.sh..." >> $LOG_FILE
get_inputs
get_brain_vols_cortical_thickness
