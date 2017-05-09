/// dsDNA tract finder
/// James Graham, 2015

#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#include <Peak AutoFind>

Menu "DNA tracts"
"DNA tract finder", OFanalyse()
End

Function year()
	return str2num(StringFromList(0, Secs2Date(DateTime, -2), "-"))
End
 
Function month()
	return str2num(StringFromList(1, Secs2Date(DateTime, -2), "-"))
End
 
Function day()
	return str2num(StringFromList(2, Secs2Date(DateTime, -2), "-"))
End
 
Function hour()
	return str2num(StringFromList(0, Secs2Time(DateTime, 3), ":"))
End
 
Function minute()
	return str2num(StringFromList(1, Secs2Time(DateTime, 3), ":"))
End
 
Function second()
	return str2num(StringFromList(2, Secs2Time(DateTime, 3), ":"))
End


Function OFanalyse()

DoWindow/H/HIDE=1 // hide the command window

//Define the Input Variables//
String wave_id = "merge_"
String file_name, file_name_overlay, file_name_projection
String image_name_cyan, image_name_magenta, image_name_overlay, image_name, frame_name, image_name_projection
String wave_name
String profile_ON_name, profile_OFF_name
String file_identifier

//Variable linewidth = 1
Variable min_frxn = 0.2
Variable smooth_avg, smooth_avg_OFF, smooth_sd, smooth_SD_OFF, profile_max, profile_avg, profile_sd, dif_sd

// Initialise waves for filtering
Make/O/D/N=11 coefs

//Make User Prompts in the Dialogue Box//
Prompt wave_id, "Wave identifier (e.g. 'S1')"
DoPrompt "Enter parameters",  wave_id

//Specify Folder for Analysis in Dialogue Box//
newpath/o data_path

////////// Load data using batch file coords.txt in specified data path

String columnInfoStr = ""

make/o molecule,x1,y1,x2,y2

file_name = "coords.txt"
columnInfoStr += "C=1,F=-1,T=2,N=molecule;"
columnInfoStr += "C=1,F=-1,T=2,N=x1;"
columnInfoStr += "C=1,F=-1,T=2,N=y1;"
columnInfoStr += "C=1,F=-1,T=2,N=x2;"
columnInfoStr += "C=1,F=-1,T=2,N=y2;"

loadwave/w/a/o/b=columnInfoStr/j/l={0,0,0,0,0}/p=data_path/n file_name

variable start_mol,end_mol
variable stdev = 3
wavestats molecule
start_mol=V_min
end_mol=V_max

ImageFileInfo/P=data_path wave_id+".tif"
variable n_Images = V_numimages
variable linewidth = 5

Prompt start_mol, "Start molecule:"
Prompt end_mol, "End molecule:"
Prompt stdev, "Standard deviation for detection:"
Prompt linewidth, "Line width:"

DoPrompt "Enter parameters",start_mol,end_mol,stdev,linewidth

// Open new notebook and log events

string logtitle
String dateTimeString = ""
	sprintf dateTimeString, "%.4d-%.2d-%.2d %.2d.%.2d.%.2d", year(), month(), day(), hour(), minute(), second()
logtitle = "logfile_"+dateTimeString+".txt"
newnotebook/K=1/F=0/V=1/N=logfile
notebook logfile text="Peak finding macro initiated "+dateTimeString+".\r"
notebook logfile text="Analysing peaks that are "+num2str(stdev)+" standard deviations from the mean.\r"
notebook logfile text="From molecule "+num2str(start_mol)+" to "+num2str(end_mol)+".\r"
notebook logfile text="Linewidth: "+num2str(linewidth)+".\r\r"


///////////// ********************************************************************

// Make waves for analysed data

Make/o/N=(n_Images) S0,E0,S1,E1,S2,E2,S3,E3,S4,E4,S5,E5,frameNumber

file_name = (wave_id)

Variable l=0
Variable p=0

file_name = (wave_id+".tif")

for (molecule=start_mol; molecule<=end_mol; molecule+=1)

p=0
l=0

S0=nan
E0=nan
S1=nan
E1=nan
S2=nan
E2=nan
S3=nan
E3=nan
S4=nan
E4=nan
S5=nan
E5=nan

notebook logfile text="Analysing molecule "+num2str(molecule)+".\r"

// Get line coordinates

make/o/N=2 xTrace,yTrace
xTrace={x1[molecule-1],x2[molecule-1]}
yTrace={y1[molecule-1],y2[molecule-1]}

//// Display graph of profiles for debugging

//make/o temp_ON_profile, temp_ON_profile_DIF
//display temp_ON_profile
//appendtograph temp_ON_profile_DIF

// Load images

for (l=0; l<=(n_Images-1); l+=1) ///////////////

frameNumber[p] = l
frame_name = ("frame_"+(num2str(l)))

ImageLoad/T=tiff/O/S=(l)/C=1/N=frame_ /P=data_path file_name
p+=1

endfor

p=0
for (l=0; l<=(n_Images-1); l+=1) ///////////////

frame_name = "frame_"+num2str(l)

// Generate line profile along Flow ON image

wave source_wave = $frame_name
ImageLineProfile srcWave=source_wave, xWave=xTrace, yWave=yTrace, width=linewidth
wave W_ImageLineProfile
duplicate/o W_ImageLineProfile, temp_ON_profile

///////////////////////////////////////
/// Detection using Derivative      ///
///////////////////////////////////////

// Low-pass filter

FilterFIR/E=2/DIM=0/LO={0.08,0.08,11}/COEF coefs, temp_ON_profile

// Differentiate, then boxcar smooth differential 
wavestats temp_ON_profile
make/o/n=(V_npnts) temp_ON_profile_DIF
differentiate/EP=1 temp_ON_profile /D=temp_ON_profile_DIF // End-point handling will delete the first and last points of the differential

// Smooth using Gaussian (binomial) function
//smooth 3, temp_ON_profile_DIF

//doupdate

Variable max_peak_dif, max_peak_profile, min_peak_profile, min_peak_dif, crossing

// Next aim is to determine inherent noise in data
// Find start and end of molecule; first and last crossing point is a fairly good guide

wavestats temp_ON_profile
max_peak_dif = V_max
crossing = 0.5*V_max

findlevels/Q/D=derivative_crossing_points temp_ON_profile, crossing // Returns levels to derivative_crossing_points

Variable h, g, num_crossings, temp_level, end_of_molecule

// We want only the first crossing point here

// Error model

wavestats derivative_crossing_points
num_crossings = V_npnts

temp_level = derivative_crossing_points[0]
end_of_molecule = derivative_crossing_points[num_crossings-1]

duplicate/o temp_ON_profile_dif, temp_ON_profile_dif_baseline
wavestats temp_ON_profile_dif_baseline

variable points_to_delete = end_of_molecule - temp_level

deletepoints temp_level-5, points_to_delete+10, temp_ON_profile_dif_baseline

wavestats temp_ON_profile_dif_baseline //
dif_sd = V_sdev // This is the inherent noise in the profile

Variable threshold

threshold = V_avg + dif_sd*stdev

// Then find all crossing-points above

findlevels/Q/EDGE=1/D=pos_crossing_points temp_ON_profile_dif, threshold
if (V_flag<2)
duplicate/o pos_crossing_points, dna_starts
wavestats pos_crossing_points
num_crossings = V_npnts

h=0
for(h=0; h<num_crossings; h+=1)
temp_level = pos_crossing_points[h]
findpeak/Q/R=((temp_level-1), (temp_level+6)) temp_ON_profile_dif
if(V_PeakLoc>0)
dna_starts[h] = V_PeakLoc
endif
endfor
endif

// and below

findlevels/Q/EDGE=2/D=neg_crossing_points temp_ON_profile_dif, threshold*-1
if (V_flag<2)
duplicate/o neg_crossing_points, dna_ends
wavestats neg_crossing_points
num_crossings = V_npnts

h=0
for(h=0; h<num_crossings; h+=1)
temp_level = neg_crossing_points[h]
findpeak/Q/N/R=((temp_level-1), (temp_level+6)) temp_ON_profile_dif
if(V_PeakLoc>0)
dna_ends[h] = V_PeakLoc
endif
endfor
endif
	
	g = 0
	h = 0


//Store values in "Sx" and "Ex" waves

String temp
Variable c=0
wavestats dna_starts
for(c=0; c<=(V_npnts-1); c+=1)
temp = "S"+(num2str(c))
wave temp_start = $temp
temp_start[l] = dna_starts[c]
endfor

wavestats dna_ends
for(c=0; c<=(V_npnts-1); c+=1)
temp = ("E"+(num2str(c)))
wave temp_start = $temp
temp_start[l] = dna_ends[c]
endfor


p+=1

endfor // end of image loop
h=0
g=0
num_crossings=0
temp_level=0
dif_sd=0
max_peak_dif=0
min_peak_profile=0
min_peak_dif=0
crossing=0


// Save the data before they are sorted! (For diagnostic purposes.)

String molnumber=num2str(molecule)
String list="root:frameNumber;root:S0;E0;S1;E1;S2;E2;S3;E3;S4;E4;S5;E5"; Save/O/J/W/P=data_path/B list as "Molecule_"+molnumber+"_presort.txt"
// Save a copy of the graph

display/N=trace S0,E0,S1,E1,S2,E2,S3,E3,S4,E4,S5,E5
movewindow 0,600,600,1000
ModifyGraph mode=3,marker=19,msize=1,mrkThick=0.5,rgb=(0,0,0)
ModifyGraph rgb(S0)=(65535,0,0),rgb(E0)=(52428,1,1),rgb(S1)=(65535,43690,0)
ModifyGraph rgb(E1)=(65535,43688,32768),rgb(S2)=(0,65535,0),rgb(E2)=(3,52428,1)
ModifyGraph rgb(S3)=(16385,49025,65535),rgb(E3)=(0,43690,65535)
ModifyGraph rgb(S4)=(1,16019,65535),rgb(E4)=(32768,40777,65535)
ModifyGraph rgb(S5)=(65535,0,52428),rgb(E5)=(65535,49151,62258)
ModifyGraph msize=1.5
Label bottom "frame number"
Label left "position along profile (px)"
SavePICT/win=trace/O/E=-2/P=data_path as "Molecule_"+molnumber+"_presort.pdf"
killwindow trace

// Declare variables used in algorithms

variable sliding_avg, sliding_sd
variable d, e, f, fore_avg, fore_sd, fore_test, back_avg, back_sd, back_test, temp_value
variable counter = 0
string temp_next, tempx, tempx_next

// 1. GET RID OF DUPLICATES
// e.g., if S1 = S0, keep only S0

f=0
do

e=0
do


// Define waves to look at
temp = "S"+num2str(e)
temp_next = "S"+num2str(e+1)
wave tempS = $temp
wave tempS_next = $temp_next
temp = "E"+num2str(e)
temp_next = "E"+num2str(e+1)
wave tempE = $temp
wave tempE_next = $temp_next

// Logic
// Pretty simple: if e.g. S0[f] = S1[f] then S1[f] should be deleted.
// Don't shift, as the next algorithm does this.

if (tempS[f] == tempS_next[f])
tempS_next[f] = NaN
counter+=1
endif

if (tempE[f] == tempE_next[f])
tempE_next[f] = NaN
counter+=1
endif


e+=1
while (e <= 4)

f+=1
while (f < n_Images)

notebook logfile text=num2str(counter)+" duplicate peaks were deleted.\r"


// 2. RE-SORT MISPLACED PEAKS
// Did the detection simply fail to find a peak?
// Step 1: is point f of S0 significantly greater than the mean+sd of points (f-1:f-4) and (f+1:f+4)?
// Step 2: is point f of S0 similar to the mean+sd of points (f-1:f-4) and (f+1:f+4) of S1?
// Step 3: shift everything right: S0 becomes S1, S1 becomes S2, etc.

counter=0
f=4 // makes sense only to start at frame 4.
do
e=0
do

// Define waves to look at
temp = "S"+num2str(e)
temp_next = "S"+num2str(e+1)
wave tempS = $temp
wave tempS_next = $temp_next
temp = "E"+num2str(e)
temp_next = "E"+num2str(e+1)
wave tempE = $temp
wave tempE_next = $temp_next

wavestats/R=[(f-4),(f-1)] tempE
back_avg = V_avg
back_sd = V_sdev
back_test = back_avg + back_sd
wavestats/R=[(f+1),(f+4)] tempE
fore_avg = V_avg
fore_sd = V_sdev
fore_test = fore_avg + fore_sd

if ((abs(tempE[f]-back_test)>3) & (abs(tempE[f]-fore_test)>3))
// If a point is more than 3 px different to what came before and what comes next
// Check the next wave (e.g. not E0 but E1)
wavestats/R=[(f-4),(f-1)] tempE_next
back_avg = V_avg
back_sd = V_sdev
back_test = back_avg + back_sd
wavestats/R=[(f+1),(f+4)] tempE_next
fore_avg = V_avg
fore_sd = V_sdev
fore_test = fore_avg + fore_sd
if ((abs(tempE[f]-back_test)<10) & (abs(tempE[f]-fore_test)<10))
// ... i.e., if we are looking at S0, and it's within 10 px of the
// value of S1 three frames either side:
counter+=1
for (d=5; d>=(e+1); d-=1)
tempx = "E"+num2str(d)
tempx_next = "E"+num2str(d-1)
wave tempxE = $tempx
wave tempxE_next = $tempx_next

tempxE[f] = tempxE_next[f]

endfor
// Because everything shifted by one, the last peak must be NaN
// Hence:
tempxE_next[f] = NaN

endif
endif

wavestats/R=[(f-4),(f-1)] tempS
back_avg = V_avg
back_sd = V_sdev
back_test = back_avg + back_sd
wavestats/R=[(f+1),(f+4)] tempS
fore_avg = V_avg
fore_sd = V_sdev
fore_test = fore_avg + fore_sd

if ((abs(tempS[f]-back_test)>3) & (abs(tempS[f]-fore_test)>3))
// If a point is more than 3 px different to what came before and what comes next
// Check the next wave (e.g. not E0 but E1)
wavestats/R=[(f-4),(f-1)] tempS_next
back_avg = V_avg
back_sd = V_sdev
back_test = back_avg + back_sd
wavestats/R=[(f+1),(f+4)] tempS_next
fore_avg = V_avg
fore_sd = V_sdev
fore_test = fore_avg + fore_sd
if ((abs(tempS[f]-back_test)<10) & (abs(tempS[f]-fore_test)<10))
// ... i.e., if we are looking at S0, and it's within 10 px of the
// value of S1 three frames either side:
counter+=1
for (d=5; d>=(e+1); d-=1)
tempx = "S"+num2str(d)
tempx_next = "S"+num2str(d-1)
wave tempxS = $tempx
wave tempxS_next = $tempx_next

tempxS[f] = tempxS_next[f]

endfor
// Because everything shifted by one, the last peak must be NaN
// Hence:
tempxS_next[f] = NaN

endif
endif

e+=1
while (e<=5)

f+=1
while (f<n_Images)

notebook logfile text=num2str(counter)+" unidentified peaks were 'shifted'.\r"


// 3. REMOVE LOCAL OUTLIERS

counter=0
for (c=0; c<=5; c+=1)

temp = "S"+(num2str(c))
wave temp_start = $temp
variable window_size = 20 ////////////////////////

for (f=window_size+2; f<=n_images-window_size; f+=1)

wavestats/R=[f-window_size,f+window_size] temp_start // Calculates a sliding window
sliding_avg = V_avg
sliding_sd = V_sdev
if ((temp_start[f] > (sliding_avg + sliding_sd*2)) | (temp_start[f] < (sliding_avg - sliding_sd*2)))
counter+=1
temp_start[f] = NaN  // Replaces outlier with NaN value

endif

endfor

endfor

for (c=0; c<=5; c+=1)

temp = "E"+(num2str(c))
wave temp_start = $temp

for (f=window_size+2; f<=n_images-window_size; f+=1)

wavestats/R=[f-window_size,f+window_size] temp_start // Calculates a sliding window
sliding_avg = V_avg
sliding_sd = V_sdev
if ((temp_start[f] > (sliding_avg + sliding_sd*2)) | (temp_start[f] < (sliding_avg - sliding_sd*2)))
counter+=1
temp_start[f] = NaN
endif

endfor

endfor

notebook logfile text=num2str(counter)+" local outliers were removed.\r"

//// End of sorting algorithms

// Display graph

display/N=trace S0,E0,S1,E1,S2,E2,S3,E3,S4,E4,S5,E5
movewindow 0,600,600,1000
ModifyGraph mode=3,marker=19,msize=1,mrkThick=0.5,rgb=(0,0,0)
ModifyGraph rgb(S0)=(65535,0,0),rgb(E0)=(52428,1,1),rgb(S1)=(65535,43690,0)
ModifyGraph rgb(E1)=(65535,43688,32768),rgb(S2)=(0,65535,0),rgb(E2)=(3,52428,1)
ModifyGraph rgb(S3)=(16385,49025,65535),rgb(E3)=(0,43690,65535)
ModifyGraph rgb(S4)=(1,16019,65535),rgb(E4)=(32768,40777,65535)
ModifyGraph rgb(S5)=(65535,0,52428),rgb(E5)=(65535,49151,62258)
ModifyGraph msize=1.5
Label bottom "frame number"
Label left "position along profile (px)"

// Save the Data in a tab delimited text file in the data folder
molnumber=num2str(molecule)
list="root:frameNumber;root:S0;E0;S1;E1;S2;E2;S3;E3;S4;E4;S5;E5"; Save/O/J/W/M="\r\n"/P=data_path/B list as "Molecule_"+molnumber+".txt"
				/// Unix line terminators have been causing issues with the Python script, so follow Windows convention

// Save a copy of the graph, kill graph.
SavePICT/win=trace/O/E=-2/P=data_path as "Molecule_"+molnumber+".pdf"
notebook logfile text="\r"
killwindow trace
endfor // end of molecule loop

// Output log file

savenotebook/S=1/O/P=data_path logfile as logtitle
killwindow logfile


End
