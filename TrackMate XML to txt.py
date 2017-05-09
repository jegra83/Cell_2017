import xml.etree.ElementTree as ET
import os

tree = ET.parse('tracks.xml') # replace with name of TrackMate file
root = tree.getroot()
nTracks = 0
nTimepoints = 0
t = []
x = []
y = []
d = []

ss_conv_factor = float(raw_input("Single-strand DNA conversion factor?: "))
time_int = float(raw_input("Time interval between frames: "))

for i in root.iter('particle'):
	
	for track in i:
		tstr=(track.get('t'))
		t.append(float(tstr)*time_int) # replace with frame interval
		x.append(track.get('x'))
		y.append(track.get('y'))
				
		# convert t, x and y data to floats...
		
		xstr0 = float(x[0])
		ystr0 = float(y[0])
		tstr = float(t[nTimepoints])
		xstr = float(x[nTimepoints])
		ystr = float(y[nTimepoints])
		
		
	
		# calculate displacement:
		
		displacement = ss_conv_factor*((xstr-xstr0)**2+(ystr-ystr0)**2)**0.5
		d.append(displacement)
		
		print nTracks,nTimepoints,t[nTimepoints],x[nTimepoints],y[nTimepoints],d[nTimepoints]
		nTimepoints += 1
		
	text_file = open(str(nTracks)+".txt", "w")
	text_file.write("t\tx\ty\td\n")
	for k in xrange(0,nTimepoints):		
		text_file.write("%s\t%s\t%s\t%s\n" %(t[k],x[k],y[k],d[k]))
	text_file.close()
	nTimepoints = 0
	nTracks += 1
	t = []
	x = []
	y = []
	d = []