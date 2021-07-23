############################################################################
# HOW TO USE:
# python mlr.py [bold] [etco2] [eto2] [output_dir]
#
# Ex. python mlr.py /media/labrat/830Mount/SH001_BOLD.nii.gz /media/labrat
#     /830Mount/ET/SH001_ETCO2.txt /media/labrat/830Mount/ET/SH001_ETO2.txt
#     /home/labrat/BatchHMRI/output
############################################################################

import numpy as np
import pandas as pd
from sklearn import linear_model
import matplotlib.pylab as plt
from scipy.optimize import curve_fit
from scipy.signal import savgol_filter
from matplotlib import pyplot
import sys

def read_file(filename):
    with open(filename) as f:
        lines = f.readlines()
        data = [line.split()[0] for line in lines]
        data = [float(n) for n in data[3:]] #in data[3:]
    return data

def norm(data):
    mx, mn = get_max_min(data)
    return [(n-mn)/(mx-mn) for n in data]

def get_max_min(data):
    return max(data), min(data)

def write_file(filename, data):
    f = open(filename, 'w')
    for n in data:
        f.write("%f\n" % n)

#------------------------------------- Multiple linear regression using sklearn
def sklearn_mlr(df,target):
    x = df
    y = target['bold']

    lm = linear_model.LinearRegression()
    model = lm.fit(x,y)

    predictions = lm.predict(x)

    print('SUMMARY FOR SUBJECT_ID:')
    print('R-squared:', lm.score(x,y))      # R-squared
    print('B0:', lm.intercept_)             # constant (b0)
    print('pe:', lm.coef_)                  # RM coefficient
    print()

    etco2_bold_model = [i * float(lm.coef_.item(0)) for i in df['etco2']]
    eto2_bold_model = [i * float(lm.coef_.item(1)) for i in df['eto2']]

    target['percent_bold'] = (target['bold']-min(target['bold']))/(max(target['bold'])-min(target['bold']))

    plt.subplot(111)
    plt.plot(target['percent_bold'], label='Percent BOLD', c='b')
    plt.plot(target['bold'], label='BOLD', c='b')
#   plt.plot(predictions, label='Model')
    plt.plot(df['etco2']*lm.coef_[0], label='CO2', c='r')
    plt.plot(df['eto2']*lm.coef_[1], label='O2', c='g')
#   plt.plot((mn*(feat_pe1*df['etco2']+feat_pe2*df['eto2'])/(100*(mx-mn))), label='FEAT')
    plt.legend()
    plt.show()

    return lm.coef_
    #return ((mx-mn)*lm.coef_/mn) * 100  #work in ET range

#--------------------------------------- Find optimal shift for best pe results
def get_best_shift(bold,etco2,eto2):
    max_pe = [-30.0,-30.0]

    norm_bold = norm(bold)
    norm_etco2 = norm(etco2)
    norm_eto2 = norm(eto2)

    j = 0
    l = len(bold)
    # Shift ET left/right 3x (max time shift is 5*TR = +/- 7.5 seconds)
    for i in range(l+1,l-5,-1):
        print("Shift ETs left",j)
        df = pd.DataFrame(zip(norm_etco2[j:],norm_eto2[j:]),columns=['etco2', 'eto2'])
        target = pd.DataFrame(norm_bold[:i-1],columns=['bold'])
        # Get max and min of BOLD signal
        mx,mn = get_max_min(bold[:i-1])
        # Get pe values after shifting left
        pe = sklearn_mlr(df,target)
        # If new pe value is greater than the highest pe, replace it
        if pe[0] > max_pe[0]:
            max_pe = pe
            shift = 'left'+str(j)
        print("Shift ETs right",j)
        df = pd.DataFrame(zip(norm_etco2[:i-1],norm_eto2[:i-1]),columns=['etco2', 'eto2'])
        target = pd.DataFrame(norm_bold[j:],columns=['bold'])
	# Get max and min of BOLD signal
        mx,mn = get_max_min(bold[j:])
	# Get pe values after shifting right
        pe = sklearn_mlr(df,target)
	# If new pe value is greater than the highest pe, replace it
        if pe[0] > max_pe[0]:
            max_pe = pe
            shift = 'right'+str(j)
        j=j+1
    return max_pe, shift

#-------------------------------------------------------- Smooth the timeseries
def smooth(data):
    return savgol_filter(data,51,3)

def get_min(ts):
    print(ts.index(min(ts[150:225])))


def main():
    if (len(sys.argv) != 5):
        print("[ERROR] Incorrect number of arguments.")
        print("[ERROR] python mlr.py [bold] [etco2] [eto2] [output_dir]")
        return

    # Prepare output ET folder (will specify SID in file name so can output all ETs to same dir)
    output_dir = sys.argv[4]

    # TODO: Get BOLD mean timeseries from BOLD file 
    # bold_mts = fslmeants sys.argv[1]

    # Get data from input files
    bold = read_file(sys.argv[1]) # bold_mts
    etco2 = read_file(sys.argv[2])
    eto2 = read_file(sys.argv[3])
    # Make ET data the same length as the BOLD data
    etco2 = etco2[:len(bold)]
    eto2 = eto2[:len(bold)]

    df = pd.DataFrame({'etco2':etco2})
    df['eto2'] = eto2
    target = pd.DataFrame({'bold':bold})

    # TEST: CHECK READ_FILE (data[3:]) AND GET_BEST_SHIFT (for loop) has been changed back beforehand
    print('Optimal %pe + time shift:', get_best_shift(bold,etco2,eto2),'\n')

    # TEST: OUTPUT SHIFTED ETCO2 AND ETO2 FILES TO OUTPUT DIR
    #write_file('/home/labrat/SH/'+pid+'/etco2_norm.txt',etco2)
    #write_file('/home/labrat/SH/'+pid+'/eto2_norm.txt',eto2)

    # TEST: FOR REGRESSION
    #sklearn_mlr(pid,df,target)


if __name__ == "__main__":
    main()
