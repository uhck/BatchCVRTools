# HOW TO USE (written for Python 2):
# python EndTidal_CO2_O2.py [filename]
# ----------------------------------------
# File should be in defined in_dir = "/home/labrat/Dropbox/Physiologic_Recordings/"

import sys
import numpy as np
import pandas as pd
import matplotlib.pylab as plt
from scipy.signal import savgol_filter
from scipy.interpolate import interp1d
import peakutils as pkutils
from scipy.signal import find_peaks

def read_file(filename):
    print '[1] Reading data file ', filename, '...'
    in_dir = '/media/labrat/395Mount/replicate_attempt1/SH_GAS/'
    with open(in_dir+filename) as f:
	lines = f.readlines()
	time = [float(line.split()[0]) for line in lines]
    	o2 = [float(line.split()[1]) for line in lines]
    	co2 = [float(line.split()[2]) for line in lines]
        if (co2[0] < 1):
            co2 = [ co2[i] * 100 for i in range(0, len(co2)) ]
    return time, o2, co2

def get_outdir(filename):
    print '[2] Getting output filename...'
    parts = filename.split('_')
    out_dir = '/home/labrat/'+parts[0]+'/'+parts[0]+parts[1]+'/'
    return out_dir

def get_scantime(time):
    print '[3] Converting time from minutes to seconds...'
    tr = float(raw_input('    Enter TR value: '))
    if time[-1] < 10:
    	time = [t * 60 for t in time]
    scantime = np.arange(0,8*60, tr)	
    print "scantime\n", scantime #debug
    return time, scantime

def get_peaks(time, co2, o2, scantime):
    print '[4] Getting peak values of CO2 and O2 data...'
    time, co2, o2 = np.asarray(time), np.asarray(co2), np.asarray(o2)
    p, w = 1,1

    p = float(raw_input('    Enter prominence (default=1): '))
    w = float(raw_input('    Enter width (default=1): '))
    co2_indices,_ = find_peaks(co2, prominence=p, width=w);
    co2_peaks = co2[co2_indices]
    co2_time = time[co2_indices]
    co2_f = interp1d(co2_time, co2_peaks, fill_value="extrapolate")
    etco2 = co2_f(scantime)

    p, w = 1, 1
    p = float(raw_input('    Enter prominence (default=1): '))
    w = float(raw_input('    Enter width (default=1): '))
    o2_indices,_ = find_peaks(o2, prominence=p, width=w);
    o2_peaks = o2[o2_indices]
    o2_time = time[o2_indices]
    o2_f = interp1d(o2_time, o2_peaks, fill_value="extrapolate")
    eto2 = o2_f(scantime)

    plot_peaks(time, co2, o2, scantime, etco2, scantime, eto2)
    return etco2, eto2

def plot_peaks(time,co2,o2,scantime1,etco2,scantime2,eto2):
    print '[5] Plotting endtidal CO2 and O2 peaks...'
    fig = plt.figure()

    ax1 = fig.add_subplot(211)
    ax1.set_xlabel('time (s)')
    ax1.set_ylabel('etco2')
    ax1.plot(time,co2,'b')
    ax1.plot(scantime1,etco2,'ro')

    ax2 = fig.add_subplot(212)
    ax2.set_xlabel('time (s)')
    ax2.set_ylabel('eto2')
    ax2.plot(time,o2,'b')
    ax2.plot(scantime2,eto2,'ro')

    plt.show()

def smooth(data):
    return savgol_filter(data,51,3)

def write_files(time, co2, o2, filename):
    np.savetxt(filename[0:-4]+'_O2.contrast', o2)
    np.savetxt(filename[0:-4]+'_CO2.contrast', co2)



def __main__():
    filename = sys.argv[1]
    time, o2, co2 = read_file(filename)
    outdir = get_outdir(filename)
    time, scantime = get_scantime(time)
    satisfied = 0
    while satisfied == 0:
	etco2, eto2 = get_peaks(time, co2, o2, scantime)
	satisfied = int(raw_input('    Are you satisfied (0 or 1)? '))
    print "Length of ETCO2, ETO2 (should be 320): ", len(etco2), len(eto2)
    write_files(scantime, co2, o2, filename)



__main__()
