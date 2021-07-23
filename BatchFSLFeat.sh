#!/bin/bash
source $BATCH_CONFIG_FILE 

#################################################################
# PROCESS: Runs FEAT analysis, FEATquery, and gets mean whole   #
#          brain CVR and CBV                                    #
# HOW TO USE:                                                   #
# ./BatchFSLFeat.sh [-i /path/to/subject_dir] -o [output dir]   #
#                                                               #
# Ex. ./BatchFSLFeat.sh -i /home/labrat/SH001 -o /home/labrat   #
#################################################################

function feat_analysis () {
    # Makes variables local to only this function
    local dir=$1
    local bold=$2

#    echo "[1] Prepping files for $dir" >> $LOG_FILE

    # Get SubjectID_Date and paths to BOLD, T1, ETCO2, ETO2 files
    local sid=${dir##*/}
    sid=${sid%%_*}
    local date=${bold##*_}
    local date=${date:0:8}
    local featdir=$out_dir/$sid"_"$date"_bold"

    # Use brainmask.mgz as T1 (if FS recon-all was successful)
#    mri_convert $SUBJECTS_DIR/$sid*$date/mri/brainmask.mgz $dir/fs.t1.nii.gz
    local t1=$dir/fs.t1.nii.gz
    # Otherwise BET original T1 for registration in FEAT analysis
    if [ ! -f $t1 ]; then
        t1=`(find $dir -iname $T1_STR".nii.gz" -o -iname $T1_STR".nii") | head -n 1`

        # If original T1 is found, run BET on it
        if [ $t1 != "" ]; then
            echo "[1] Running FSL BET: $t1" >> $LOG_FILE
#            bet $t1 $dir/t1_brain.nii.gz -f 0.5 -R
            t1=$dir/t1_brain.nii.gz
        fi
        # Otherwise FEAT will run without T1 registration
    fi

    # ET_DIR set by bash environment variable set with BatchConfig.cfg file
    local co2=`find $ET_DIR -iname "*$sid*$date*$ETCO2_STR*.txt"` 
    local o2=`find $ET_DIR -iname "*$sid*$date*$ETO2_STR*.txt"` 
    local numvol=`fslval $bold dim4`
    local tr=`fslval $bold pixdim4`

    # Output variables to pipeline_log.txt
    echo "[SID_DATE]" $sid"_"$date >> $LOG_FILE
    echo "[INDIR]" $dir >> $LOG_FILE
    echo "[OUTDIR] $featdir" >> $LOG_FILE
    echo "[2] Files for FSL FEAT analysis" >> $LOG_FILE
    echo "[BOLD] $bold" >> $LOG_FILE
    echo "[T1] $t1" >> $LOG_FILE
    echo "[ETCO2] $co2" >> $LOG_FILE
    echo "[ETO2] $o2" >> $LOG_FILE
    echo "[NUMVOL] $numvol" >> $LOG_FILE
    echo "[TR] $tr" >> $LOG_FILE
    
    # Match strings for design.fsf file
    bold_str="BOLD_FILE"
    t1_str="T1_FILE"
    co2_str="ETCO2_FILE"
    o2_str="ETO2_FILE"
    out_str="OUT_DIR"
    vol_str="NUM_VOL"
    tr_str="TR_VALUE"

    # Run FEAT analysis if all necessary files are there
    # T1s are only for registration and FEAT can run without it so not a requirement here
    if [[ $bold != "" ]] || [[ $co2 != "" ]] || [[ $o2 != "" ]]; then
        echo "[3] Running FEAT analysis" >> $LOG_FILE
        sed "s!$bold_str!$bold!g; s!$t1_str!$t1!g; s!$co2_str!$co2!g; s!$o2_str!$o2!g; \
            s!$tr_str!$tr!g; s!$out_str!$featdir!g; s!$vol_str!$numvol!g" \
            $BATCH_HOME/design_template.fsf > $dir/design.fsf
        feat $dir/design.fsf >> $LOG_FILE
    else
        echo "[ERROR] Missing input files. Cannot run FEAT analysis" >> $LOG_FILE
    fi

    # Output values to summary file
    featdir=$featdir".feat"
    echo "[4] Performing featquery to get whole-brain CVR and CBV in $featdir" >> $LOG_FILE
    featquery 1 $featdir 1 stats/cope1 ftqry_wb_cvr -p -s -w $featdir/cluster_mask_zstat1.nii.gz
    featquery 1 $featdir 1 stats/cope2 ftqry_wb_cbv -p -s -w $featdir/cluster_mask_zstat2.nii.gz
            
    if [ -f $featdir/ftqry_wb_cvr/report.txt ]; then
        cvrfile=$featdir/ftqry_wb_cvr/report.txt
        cvrline=$(head -n 1 $cvrfile)
        cvrline=($cvrline)

        cbvfile=$featdir/ftqry_wb_cbv/report.txt
        cbvline=$(head -n 1 $cbvfile)
        cbvline=($cbvline)
        
        echo "[5] Outputting $sid whole-brain CVR and CBV values to $wbcvr_outfile" >> $LOG_FILE
        echo $sid", "$date", "${cvrline[5]}","${cbvline[5]} >> $wbcvr_outfile 
    else
        echo "[ERROR] Cannot find featquery folder in $featdir" >> $LOG_FILE
    fi
}


#function get_wb_cvr () {
#    for featdir in $(find $out_dir -mindepth 1 -maxdepth 1 -type d -name "*.feat"); do
#        echo "[4] Performing featquery to get whole-brain CVR and CBV in $featdir" >> $LOG_FILE
#        featquery 1 $featdir 1 stats/cope1 ftqry_wb_cvr -p -s -w $featdir/cluster_mask_zstat1.nii.gz
#        featquery 1 $featdir 1 stats/cope2 ftqry_wb_cbv -p -s -w $featdir/cluster_mask_zstat2.nii.gz
#        if [ -f $featdir/ftqry_wb_cvr/report.txt ]; then
#            pid=${featdir##*/}
#            date=${pid%_*}
#            date=${date#*_}
#            pid=${pid%%_*}
#
#            cvrfile=$featdir/ftqry_wb_cvr/report.txt
#            cvrline=$(head -n 1 $cvrfile)
#            cvrline=($cvrline)
#
#            cbvfile=$featdir/ftqry_wb_cbv/report.txt
#            cbvline=$(head -n 1 $cbvfile)
#            cbvline=($cbvline)
#
#            echo "[5] Outputting $pid whole-brain CVR and CBV values to $wbcvr_outfile" >> $LOG_FILE
#            echo $pid", "$date", "${cvrline[5]}", "${cbvline[5]} >> $wbcvr_outfile 
#        else
#            echo "[ERROR] Cannot find featquery folder in $featdir" >> $LOG_FILE
#        fi
#    done
#}


#############################
######## Main script ########
#############################

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
            echo "Usage: ./BatchFSLFeat.sh [-i /path/to/subject_dir] -o [output dir]"
            exit 1
            ;;
    esac
done
shift $((OPTIND-1))

# Set up CVR Summary Report file to output CVR values
todaysdate=`date "+20%y%m%d"`
if [ ! -f $out_dir/"CVR_Report_$todaysdate.txt" ]; then
    wbcvr_outfile=$out_dir/"CVR_Report_$todaysdate.txt"
    echo "PID, Date, CVR, CBV" >> $wbcvr_outfile
fi

# For each subject folder brought in as an argument,
for sdir in ${inputs[@]}; do
    # Output to log
    echo "Starting BatchFSLFeat.sh..." >> $LOG_FILE
    
    # For each BOLD scan in subject folder, perform a FEAT analysis
    for sbold in $(find $sdir -iname $BOLD_STR".nii.gz" -o -iname $BOLD_STR".nii"); do
        feat_analysis "$sdir" "$sbold" "$wbcvr_outfile" &
    done
done
