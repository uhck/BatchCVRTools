import nipype.interfaces.spm as spm
import nipype.interfaces.fsl as fsl

t1 = '/home/labrat/BatchHMRI/output/SH057_SPM/t1.nii'
asl = '/home/labrat/BatchHMRI/output/SH057_SPM/asl.nii'
cbf = '/home/labrat/BatchHMRI/output/SH057_SPM/cbf.nii'

#coreg = spm.Coregister()
#coreg.inputs.target = t1
#coreg.inputs.source = asl
#coreg.inputs.apply_to_files = [cbf]
#coreg.run()

#bet = fsl.BET()
#bet.inputs.in_file = t1
#bet.inputs.out_file = '/home/labrat/BatchHMRI/output/SH057_SPM/bet_t1.nii'
#bet.inputs.frac = 0.4
#bet.run()
bet_t1 = '/home/labrat/BatchHMRI/output/SH057_SPM/bet_t1.nii'

seg = spm.Segment()
seg.inputs.data = bet_t1
seg.run()
