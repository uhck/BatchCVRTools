#!/usr/bin/env python3

import sys
import os
import subprocess
import PySimpleGUI as SG
import re

def PipeWindow():    
    pipeframe = [
        # Checkbox for Freesurfer reconstruction
        [SG.Checkbox(' Freesurfer reconstruction and segmentation', key='_RECON_', default=False)],
        [SG.Text('\tRequirements: T1, (opt) T2 or T2 FLAIR for pial correction\n' \
                 '\tOutput: '+os.environ['SUBJECTS_DIR'], font='Arial 8')],

        # Checkbox for brain volumes acquired from Freesurfer
        [SG.Checkbox(' Freesurfer brain volumes and cortical thickness', key='_BVOL_AND_COT_', default=False)],
        [SG.Text('\tRequirements: Freesurfer reconstruction', font='Arial 8')],

        # Checkbox for brain volumes acquired from Freesurfer
        [SG.Checkbox(' Freesurfer masks', key='_FS_MASKS_', default=False)],
        [SG.Text('\tRequirements: Freesurfer reconstruction\n' \
                 '\tProcess: In progress...', font='Arial 8')],

        # Get segmentation masks from FSL or Freesurfer (FSL/Freesurfer + table list of options)
        # Lists all the mask presets that match the string, enable adding/removing presets
        #[SG.Listbox(values=['Subject folders'], size=(70,5), select_mode='multiple', key='_LISTSRCS_')],

        # Checkbox for FSL FEAT analysis for CVR
        [SG.Checkbox(' FSL FEAT analysis for CVR', key='_FEAT_', default=False)],
        [SG.Text('\tRequirements: BOLD, Orig T1 or (for masking) Freesurfer T1, ETCO2, ETO2\n' \
                 '\tProcess: Runs FSL FEAT analysis and outputs whole brain CVR and CBV report', font='Arial 8')],

        # Checkbox for CVR/CBV in ROIs from FSL using masks from Freesurfer or FSL
        # Options: cluster_mask_zstat*.nii.gz, Freesurfer masks
        [SG.Checkbox(' CVR/CBV from Featquery', key='_FQUERY_', default=False)],
        [SG.Text('\tRequirements: FSL FEAT analysis folders entered as subject folders below\n' \
                 '\tProcess: In progress...', font='Arial 8')],

        # Checkbox for CBF from FSL (stats/maths)
        [SG.Checkbox(' Mean cerebral blood flow', key='_CBF_', default=False)], 
        [SG.Text('\tRequirements: ASL, CBF, Freesurfer T1 or Orig T1\n' \
                 '\tProcess: Gets mean WM and GM CBF maps and outputs CBF report', font='Arial 8')],
    ]

    ioframe = [
        # Get source folder from browser
        [SG.Text('Subject Folders', size=(15,1), auto_size_text=False), \
        SG.InputText('', key='_SRC_'), \
        SG.FolderBrowse()],

        # Lists all the folders that match the string
        [SG.Listbox(values=['Subject folders'], size=(70,5), select_mode='multiple', key='_LISTSRCS_')],

        # Load, Add, Delete buttons for source listbox
        [SG.Button('Load', font='Arial 8'), \
        SG.Button('Add', font='Arial 8'), \
        SG.Button('Delete', font='Arial 8'), \

        # Enter string for matching file/folder names
        SG.Text('Match string: ', font='Arial 8'), \
        SG.InputText('', size=(20,1), font='Arial 8', key='_MATCH_')],

        # Get destination folder from browser
        [SG.Text('Output Folder', size=(15,1), auto_size_text=False), \
        SG.InputText('', key='_DST_'), \
        SG.FolderBrowse()],
    ] 

    layout = [
        [SG.Frame('Pipeline Options', pipeframe, font='Arial 12')],
        [SG.Frame('Choose Subject Folders', ioframe, font='Arial 12')],
        [SG.Button('Run')]
    ]

    window = SG.Window('HMRI Imaging Pipelines').Layout(layout)

    src_dirs = []
    while True:
        event, values = window.Read()
        print(event, values)

        if event == 'Load':
            src_dirs = load_srcs(window, values['_SRC_'], values['_MATCH_'])
        elif event == 'Add':
            src_dirs = add_srcs(window, values['_SRC_'], values['_MATCH_'], src_dirs)
        elif event == 'Delete':
            src_dirs = delete_srcs(window, values['_LISTSRCS_'], src_dirs)
        elif event == 'Run':
            run_process(values, src_dirs)
        else:
            break
    window.Close()
    

# ------------------------------------- Get first child folders from source directory
def get_srcs(src, match_str):
    dirs = []
    # If input source is a dir, get all subfolders as subject input
    if os.path.isdir(src):
        # Saves paths to all folders in directory that match string (default match_str='')
        dirs = [ src+'/'+d for d in next(os.walk(src))[1] if match_str in d ]
    # Otherwise, output error message
    else:
        print("No folders were loaded.")

    return dirs


# ------------------------------------- Load source folders to window source list
def load_srcs(window, src, match_str):
    dirs = []
    if src == "":
        return dirs
    dirs = get_srcs(src, match_str)
    # Sort directories alphabetically/numerically
    dirs.sort()
    # Update GUI source listbox with folders
    window.FindElement('_LISTSRCS_').Update(values=[ d for d in (dirs) ])

    return dirs


# ------------------------------------- Add source folders to window source list
def add_srcs(window, src, match_str, loaded_dirs):
    dirs = get_srcs(src, match_str)
    # Save folders if they are not already loaded
    dirs = [ d for d in dirs if d not in loaded_dirs ] + loaded_dirs
    # Sort directories alphabetically/numerically
    dirs.sort()
    # Update GUI source listbox with folders
    window.FindElement('_LISTSRCS_').Update(values=[ d for d in (dirs) ])

    return dirs


# ------------------------------------- Delete source folders to window source list
def delete_srcs(window, src, loaded_dirs):
    for s in src:
        loaded_dirs.remove(s)
    #loaded_dirs.sort()
    # Update GUI source listbox with folders
    window.FindElement('_LISTSRCS_').Update(values=[ d for d in (loaded_dirs) ])

    return loaded_dirs

def add_output_dir(args, values):
    if values['_DST_'] != "":
        args = args + ["-o " + values['_DST_']]
    else:
        args = args + ["-o " + os.environ['DEFAULT_BATCH_OUTPUT_DIR']]
    return args

# ------------------------------------- Run through user-specified pipelines
def run_process(values, src_dirs):
    # Set path to directory containing all scripts for this pipeline
    scriptpath = os.environ['BATCH_HOME']+"/"

    if src_dirs == []:
        print("ERROR: No source directories")
        return

    if values['_RECON_']:
        subprocess.run([scriptpath+"BatchFreesurferRecon.sh"] + src_dirs)

    if values['_BVOL_AND_COT_']:
        args = ["-i " + re.search(r'(.*)/(.*)',src).group(2) for src in src_dirs]
        args = add_output_dir(args, values)
        subprocess.run([scriptpath+"GetBrainVolsAndCortThickness.sh"] + args)

    # if values['_MASKS_']:
    #   subprocess.run([scriptpath+"GetFreesurferMasks.sh"] + src_dirs)

    if values['_FEAT_']:
        args = ["-i " + src for src in src_dirs]
        args = add_output_dir(args, values)
        subprocess.run([scriptpath+"BatchFSLFeat.sh"] + args)

    if values['_FQUERY_']:
        subprocess.run([scriptpath+"GetCVRAndCBV.sh"] + src_dirs)

    if values['_CBF_']:
        args = ["-i " + src for src in src_dirs]
        args = add_output_dir(args, values)
        print("Arguments", args)  #debug
        subprocess.run([scriptpath+"GetCerebralBloodFlow.sh"] + args)

    return

# MAIN WINDOW: responds to button events
PipeWindow()
