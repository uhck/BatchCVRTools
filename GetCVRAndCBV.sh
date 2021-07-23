#!/bin/bash
source $BATCH_CONFIG_FILE

##################################################################
# PROCESS: Acquires CVR and CBV values using masks in Featquery  #
# HOW TO USE:                                                    #
# ./GetCVRAndCBV.sh [-i /path/to/FEAT/dirs] -o [output dir] [-m  #
# preset masks or /path/to/mask ]                                #
#                                                                #
# Ex. ./GetCVRAndCBV.sh -i /home/labrat/SH059_20181018_bold.feat #
#     -i /home/labrat/WH1701_20181206_bold.feat -o /home/labrat  #
#     -m wm.nii.gz -m gm.nii.gz                                  #
##################################################################

get_cvr_cbv () {
    # Get whole brain CVR and CBV using cluster_mask_zstat1 and _zstat2

    # For each mask preset listed,
    for mask in ${masks[@]}; do
        pid=${dir#$home/}
        sid=`echo $pid | sed 's/[^A-Z]*//g'`

        if [ -f $dir*ftqry_brain_cvr/report.txt ]
        then
            cvrfile=$dir/$featdir/ftqry_brain_cvr/report.txt
            cvrline=$(head -n 1 $cvrfile)
            cvrline=($cvrline)

            cbvfile=$dir/$featdir/ftqry_brain_cbv/report.txt
            cbvline=$(head -n 1 $cbvfile)
            cbvline=($cbvline)

            echo $pid","${cvrline[5]}","${cbvline[5]} >> $home/$sid"_CVR.csv"
        fi
    done
}


################################
########## Main script #########
################################

# Getopts
while getopts ':i:o:' OPTION; do
    case "$OPTION" in
        i)
            inputs+=("$OPTARG")
            ;;
        o)
            out_dir="$OPTARG"
            ;;
        m)
            masks+=("$OPTARG")
            ;;
        ?)
            echo "Usage: "
            exit 1
            ;;
    esac
done
shift $((OPTIND-1))

# For each subject folder brought in as an argument,
for dir in ${inputs[@]}; do
    # Output to log
    echo "Starting GetCVRAndCBV.sh..." >> $LOG_FILE

    # Get Subject Id (unique identifier) from subject folder name
    subj_id=${dir##*/}

    # For each BOLD scan in subject folder, get CVR and CBV using the masks specified
    get_cvr_cbv
done
wait
