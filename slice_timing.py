import matplotlib.pyplot as plt
import csv

x = []
y = []
z = []

with open('/media/labrat/830Mount/MTT/slice_mean_intensities.csv', 'r') as csvfile:
    plots = csv.reader(csvfile, delimiter=',')
    for row in plots:
        x.append(float(row[0].strip()))
        y.append(float(row[1].strip()))
        z.append(float(row[2].strip()))
        
fig, (ax1, ax2) = plt.subplots(2)
fig.suptitle('Slice Timeseries')

ax1.plot(x,y)
ax2.plot(x,z)

plt.xlabel('time')
plt.ylabel('mean slice intensity')

plt.show()
