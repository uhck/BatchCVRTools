from os import listdir
from os.path import isfile, join
import xlwt

path='/home/labrat/SH/4_T1_intensity/'
#path='/home/labrat/SH/5_test/'

files = [ f for f in listdir(path) if isfile(join(path, f)) ]

book = xlwt.Workbook(encoding="utf-8")
mean_sheet = book.add_sheet("Mean")
stdev_sheet = book.add_sheet("Stdev")

means = {}
stdevs = {}
titles = ['Subject-ID']
for f in listdir(path):
    if isfile(join(path, f)):
        fileo = open(join(path,f), 'r')
        lines = fileo.readlines()
        if len(lines[54:]) > 41:
            print(lines[54+34])
            print(lines[54+18])
            del lines[54+34]
            del lines[54+18]
        means[f[0:5]] = []
        stdevs[f[0:5]] = []
        for i in range(54,len(lines)):
            lines[i] = lines[i].lstrip()
            word = lines[i].split()
            if f[0:5] == 'SH001':
                titles.append(word[4])
            means[f[0:5]].append(word[5])
            stdevs[f[0:5]].append(word[6])

for j in range(0,len(titles)):
    mean_sheet.write(0,j,titles[j])
    stdev_sheet.write(0,j,titles[j])

i = 1
for key in means:
    print('Printing', key, len(means[key]), len(stdevs[key]))
    mean_sheet.write(i,0,key)
    stdev_sheet.write(i,0,key)
    for j in range(1,len(titles)):
        print(j, means[key][j-1])
        mean_sheet.write(i,j,means[key][j-1])
        stdev_sheet.write(i,j,stdevs[key][j-1])
    i += 1

book.save(path+"SH_T1_intensities.xls")
