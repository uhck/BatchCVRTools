#!/bin/bash
source $BATCH_CONFIG_FILE

#######################################################################
# PROCESS: Gets mean cerebral blood flow values from WM and GM using  #
# either FSL or Freesurfer masks                                      #
# HOW TO USE:                                                         #
# ./GetCerebralBloodFlow.sh [-i /path/to/subject_dir] -o [output_dir] #
#                                                                     #
# Ex. ./GetCerebralBloodFlow.sh -i /home/labrat/SH001 -o /home/labrat #
#######################################################################


get_mean_cbf () {
    # Get T1, ASL, CBF images
    asl=`(find $dir -iname "*$ASL_STR*.nii*") | head -n 1`
    cbf=`(find $dir -iname "*$CBF_STR*.nii*") | head -n 1`
    t1=`(find $dir -iname "*$T1_STR*.nii*") | head -n 1`
    
    # If one of these files are missing, do not continue (exit the function)
    if [ "$asl" == "" ] || [ "$cbf" == "" ] || [ "$t1" == "" ]; then
        echo "[ERROR] Cannot find T1, ASL, or CBF image:" >> $LOG_FILE
        echo "[T1] "$t1 >> $LOG_FILE
        echo "[ASL] "$asl >> $LOG_FILE
        echo "[CBF] "$cbf >> $LOG_FILE
        return 0
    fi

    echo "[ASL] "$asl >> $LOG_FILE
    echo "[CBF] "$cbf >> $LOG_FILE
    echo "[T1] "$t1 >> $LOG_FILE

    # Extract naming convention, SubjectID_Date, and create subject CBF output folder
    sid=${cbf##*/}
    sid=${sid%%_*}
    date=${cbf##*_}
    sid_date=$sid"_"${date:0:8}
    cbf_outdir=$out_dir/$sid_date"_cbf"
    mkdir $cbf_outdir

    echo "[1] Running FSL BET on T1: $t1" >> $LOG_FILE
    bet $t1 $cbf_outdir/bet.t1.nii.gz -f 0.3 -R >> $LOG_FILE

    echo "[2] Getting WM and GM masks from T1" >> $LOG_FILE
    fast -t 1 -n 3 -H 0.1 -I 4 -l 20.0 -g -o $cbf_outdir/bet_t1 $cbf_outdir/bet.t1.nii.gz >> $LOG_FILE

    # Move masks to subject CBF output folder
    mv $cbf_outdir/bet_t1_seg_1.nii.gz $cbf_outdir/gm.mask.nii.gz
    mv $cbf_outdir/bet_t1_seg_2.nii.gz $cbf_outdir/wm.mask.nii.gz
    mv $cbf_outdir/bet_t1_seg_0.nii.gz $cbf_outdir/csf.mask.nii.gz

    echo "[3] Registering ASL to T1, then CBF to T1 using ASL using FSL FLIRT" >> $LOG_FILE
    flirt -in $asl -ref $t1 -out $cbf_outdir/regASL.nii.gz -omat $cbf_outdir/regASL.mat \
        -bins 256 -cost corratio -searchrx -90 90 -searchry -90 90 -searchrz -90 90 -dof 12 -interp trilinear >> $LOG_FILE
    flirt -in $cbf -ref $t1 -out $cbf_outdir/regCBF.nii.gz -applyxfm -init $cbf_outdir/regASL.mat -interp trilinear >> $LOG_FILE

    echo "[4] Getting GM CBF using GM mask" >> $LOG_FILE
    fslmaths $cbf_outdir/regCBF.nii.gz -mas $cbf_outdir/wm.mask.nii.gz $cbf_outdir/wmCBF.nii.gz >> $LOG_FILE
    echo "[4] Getting WM CBF using WM mask" >> $LOG_FILE
    fslmaths $cbf_outdir/regCBF.nii.gz -mas $cbf_outdir/gm.mask.nii.gz $cbf_outdir/gmCBF.nii.gz >> $LOG_FILE
    
    echo "[5] Outputting WM and GM CBF to csv file" >> $LOG_FILE
    cbf_gm=`fslstats $cbf_outdir/gmCBF.nii.gz -M`
    cbf_wm=`fslstats $cbf_outdir/wmCBF.nii.gz -M`
    echo "[GM CBF] "$cbf_gm >> $LOG_FILE
    echo "[WM CBF] "$cbf_wm >> $LOG_FILE
    echo "$sid, $cbf_gm, $cbf_wm" >> $cbf_outfile
}


###########################
####### Main script #######
###########################

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
            echo "Usage: ./GetCerebralBloodFlow.sh [-i /path/to/subj_dir] -o [output_dir]"
            exit 1
            ;;
    esac
done
shift $((OPTIND-1))

# Set up CBF report output file
todaysdate=`date "+20%y%m%d"`
cbf_outfile=$out_dir/"CBF_Report_$todaysdate.txt"
if [ ! -f $out_dir/"CBF_Report_$todaysdate.txt" ]; then
    echo "PID, GM CBF, WM CBF" >> $cbf_outfile
fi

echo "Starting GetCerebralBloodFlow.sh..." >> $LOG_FILE
for dir in ${inputs[@]}; do
    echo "Starting with $dir" >> $LOG_FILE
    
    # For each subject folder, acquire mean CBF in WM and GM
    get_mean_cbf
done
