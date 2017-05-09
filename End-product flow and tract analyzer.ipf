#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#include <Peak AutoFind>

//////////////////////////////////////
     ///// Make Menu called "Macros" /////
//////////////////////////////////////

Menu "Macros"
"Analyse FlowON Data", FlowON()
//"Make Background Thresholds", Threshold()
//"Find Antibody Location", FindAb()
//"Collate Data Into One Text File", CollateData()
End


///////////////////////////////////////////
  ///// Function to analyse data with flow ON /////
///////////////////////////////////////////

Function FlowON()

//Define the Input Variables//
String wave_id = "merge_"
String file_name, file_name_overlay
String image_name_cyan, image_name_magenta, image_name_overlay
String running_img_and_mol_num
String wave_name
String profile_ON_name, profile_OFF_name
String file_identifier
String wave_anchor, wave_starts, wave_ends
String wave_measurementsDNA
String wave_measurementsGAP
String wave_name_thr
String pos_x_lev
String neg_x_lev
Variable image_start = 0
Variable image_end = 15
Variable linewidth = 5
Variable profilepnts = 5
Variable box = 2
Variable/g YES=0, NO=0, MANUAL=0, DONE=0, YES1=0, NO1=0, EDIT1=0, DONE1=0, d=0, c=0
Variable/g CBoxS0=0, CBoxS1=0, CBoxS2=0, CBoxS3=0, CBoxS4=0, CBoxS5=0, CBoxS6=0, CBoxS7=0, CBoxS8=0, CBoxS9=0, CBoxS10=0, CBoxS11=0, CBoxS12=0, CBoxS13=0, CBoxS14=0, CBoxS15=0
Variable/g CBoxE0=0, CBoxE1=0, CBoxE2=0, CBoxE3=0, CBoxE4=0, CBoxE5=0, CBoxE6=0, CBoxE7=0, CBoxE8=0, CBoxE9=0, CBoxE10=0, CBoxE11=0, CBoxE12=0, CBoxE13=0, CBoxE14=0, CBoxE15=0
Variable std_dev = 20
Variable anchor_max_x = 20
Variable anchor_peak_x
Variable deriv_threshold_pos
Variable deriv_threshold_neg
Variable fit_start, fit_end
Variable SD_threshold_number
Variable anchor_fit_start, anchor_fit_end, anchor_x_location
Variable smooth_avg, smooth_avg_OFF, smooth_sd, smooth_SD_OFF, profile_max, profile_avg, profile_sd
Variable Flag
Variable startDelete
Variable imageXdimension, imageYdimension

Variable/g cursorAx = 0
Variable/g cursorAy = 0
Variable/g cursorBx = 0
Variable/g cursorBy = 0

//Make User Prompts in the Dialogue Box//
Prompt wave_id, "Wave identifier (e.g. 'merge_' to load 'merge_#.tif' and 'merge_#_RGB.tif')"
Prompt image_start, "Image Start Number (the start '#' in the file name above)"
Prompt image_end, "Image End Number (the end '#' in the file name above)"
Prompt linewidth, "Width of DNA profiler in pixels"
Prompt profilepnts, "Number of profile analysis regions out of 9, starting at cursor B"
Prompt std_dev, "Standard deviation for DNA length detection"
// Prompt box, "Enter detection box filter length"
DoPrompt "Enter paramaters",  wave_id, image_start, image_end, linewidth, profilepnts, std_dev

//Specify Folder for Analysis in Dialogue Box//
newpath/o data_path

//make waves for analysed data
make/o measurements_temp, measurements_GAP_temp, gap_length, dna_length, starts, ends


make/o analysed_X_Tracks=0, analysed_Y_Tracks=0, imageName=0, moleculeNumber=0, Asigmoid=0, Apeak=0, S0=0, S1=0, S2=0, S3=0, S4=0, S5=0, S6=0, S7=0, S8=0, S9=0, S10=0, E0=0, E1=0, E2=0, E3=0, E4=0, E5=0, E6=0, E7=0, E8=0, E9=0, E10=0, ds1=0, ds2=0, ds3=0, ds4=0, ds5=0, ds6=0, ss1=0, ss2=0, ss3=0, ss4=0, ss5=0, ss6=0, CircleFlag=0

Variable l=0
l=image_start
Variable k=1
Variable p =0

for(l=image_start; l<=(image_end);l+=1)

//create the file names based on the base name and running number to load the images
file_name = (wave_id+(num2str(l))+".tif")
file_name_overlay = (wave_id+(num2str(l))+"_RGB.tif")
file_identifier = (wave_id+(num2str(l))+"_")

//create names for the loaded images in the format 'img_#_cyan', 'img_#_magenta', 'img_#_overlay',  
image_name_cyan = ("img"+(num2str(l))+"_cyan")
image_name_magenta = ("img"+(num2str(l))+"_magenta")
image_name_overlay = ("img"+(num2str(l))+"_overlay")

//load TIFF files into Temporary Waves
ImageLoad/T=tiff/S=0/C=1/O/N=$image_name_cyan /P=data_path file_name
ImageLoad/T=tiff/S=1/C=1/O/N=$image_name_magenta /P=data_path file_name
ImageLoad/T=tiff/O/N=$image_name_overlay /P=data_path file_name_overlay

image_name_cyan = ("img"+(num2str(l))+"_cyan0")
image_name_magenta = ("img"+(num2str(l))+"_magenta1")

imageYdimension = dimsize($image_name_cyan, 0)
imageXdimension = dimsize($image_name_cyan, 1)

//set molecule count to "1"
Variable molcount=1

//reset waves with flags for analysed molecules
Analysed_X_Tracks = nan
Analysed_Y_Tracks = nan

//use cursors to mark region for profile calculation

do

Wave wav = $image_name_overlay
Duplicate/o wav, DisplayWave
NewImage/n=ImageForCursors DisplayWave
ShowInfo
AppendtoGraph/w=ImageForCursors/T Analysed_Y_Tracks vs Analysed_X_Tracks
ModifyGraph mode(Analysed_Y_Tracks)=3,marker(Analysed_Y_Tracks)=2,msize(Analysed_Y_Tracks)=4,rgb(Analysed_Y_Tracks)=(65535,65535,0)
Doupdate/w=ImageForCursors
//RenameWindow $S_name, set_cursors


NewPanel/k=2/n=tmp_PauseforCursor/w=(180,640,480,770) as "Pause for cursors"
Cursor/I/C=(65535,65535,65535)/S=1 A DisplayWave cursorAx, cursorAy
Cursor/I/C=(65535,65535,65535)/S=1 B DisplayWave cursorBx, cursorBy
AutoPositionWindow/E/M=1/R=ImageForCursors	// Put panel near the graph
SetDrawEnv textrgb= (65535,0,0),fstyle= 1;
running_img_and_mol_num = ("Image: "+(num2str(l))+", Molecule: "+(num2str(molcount)))
DrawText 20,20, running_img_and_mol_num
SetDrawEnv textrgb= (0,0,0),fstyle= 0
DrawText 20,40,"Set the A and B cursors at the beginning"
DrawText 20,60,"and end of the fluorescence traces"
DrawText 20,80,"then press Continue."
Button button0,pos={110,90},size={92,20},title="Continue"
Button button0,proc=UserCursorAdjust_ContButtonProc
PauseForUser tmp_PauseforCursor, ImageForCursors

Variable/g cursorApnt = pcsr(A)
Variable/g cursorBpnt = pcsr(B)

cursorAx = 0
cursorAy = 0
cursorBx = 0
cursorBy = 0

cursorAx = hcsr(A)
cursorAy = vcsr(A)
cursorBx = hcsr(B)
cursorBy = vcsr(B)
Variable/g startP, endP, startQ, endQ


//plot line in red through cursors A and B
Make/n=2/o XTrace={cursorAx,cursorBx} ,YTrace={cursorAy,cursorBy}
AppendtoGraph/w=ImageForCursors/T yTrace vs xTrace
ModifyGraph lsize(YTrace)=1

//find slope and offset for line through cursors A and B
Variable/g slope = (cursorBy-cursorAy)/(cursorBx-cursorAx)
Variable/g offset = cursorAy - (slope*cursorAx)

//determine x-distance between cursors A and B
Variable/g distanceX = cursorBx-cursorAx

//determine y coordinates for 9 equally spaced points on the line between cursors A and B
Variable/g multiplier, start
start = (10-profilepnts)
Make/o/n=(profilepnts) xMaxValues=0, yMaxValues=0
Make/o/n=2 fit_yMaxValues=0
Make/o W_ImageLineProfile=0

		//for-loop to determine the y coordinates for 9 equally spaced points on the line between cursors A and B
		multiplier=0
		multiplier=start
		for(multiplier=start; multiplier<=10;multiplier+=1)  //only have 5 search regions for the maximum intensity on this flowON-OFF

		Variable/g point1x = floor(cursorAx + (multiplier*(distanceX/10)))
		Variable/g point1y = floor(slope*point1x+offset)

		startP = point1x-5
		endP = point1x+5
		startQ = point1y-5
		endQ = point1y+5

		Imagestats/G={startP, endP, startQ, endQ} DisplayWave

		xMaxValues[multiplier-start-1]=V_maxRowLoc //contains the x coordinates of 9 points with maximum intensity in the DNA image
		yMaxValues[multiplier-start-1]=V_maxColLoc //contains the y coordinates of 9 points with maximum intensity in the DNA image

		endfor

//plot the 9 points of max intensity as green line
AppendToGraph/w=ImageForCursors/T yMaxValues vs xMaxValues
ModifyGraph lsize(yMaxValues)=1,rgb(yMaxValues)=(0,65535,0)

//fit the 9 points of max intensity with a linear fit and plot as blue line
CurveFit/NTHR=0 line,  yMaxValues /X=xMaxValues /D
ModifyGraph lsize(fit_yMaxValues)=2, rgb(fit_yMaxValues)=(0,43690,65535)

//find slope and offset for fitted trace
Variable/g fit_point1x = xMaxValues[0]
Variable/g fit_point1y = fit_yMaxValues[0]
Variable/g fit_point2x = xMaxValues[8]
Variable/g fit_point2y = fit_yMaxValues[8]
Variable/g fit_slope = (fit_point2y-fit_point1y)/(fit_point2x-fit_point1x)
Variable/g fit_offset = fit_point1y - (fit_slope*fit_point1x)

//find coordinates for line of fit between cursors
Variable/g fit_startX = cursorAx
Variable/g fit_startY = ((fit_slope*fit_startX)+fit_offset)
Variable/g fit_endX = cursorBx
Variable/g fit_endY = ((fit_slope*fit_endX)+fit_offset)

//Make trace for line profile
Make/n=2/o LineProfileXTrace={fit_startX,fit_endX}, LineProfileYTrace={fit_startY,fit_endY}

//Generate line profile along Flow OFF image
ImageLineProfile srcWave=$image_name_cyan, xWave=LineProfileXTrace, yWave=LineProfileYTrace, width=linewidth
Duplicate/o W_ImageLineProfile, temp_OFF_profile
temp_OFF_profile = 0
Duplicate/o W_ImageLineProfile, temp_OFF_profile

//Generate line profile along Flow ON image
ImageLineProfile srcWave=$image_name_magenta, xWave=LineProfileXTrace, yWave=LineProfileYTrace, width=linewidth
Duplicate/o W_ImageLineProfile, temp_ON_profile
temp_ON_profile = 0
Duplicate/o W_ImageLineProfile, temp_ON_profile

//Plot trace for line profile on DNA image in thick yellow
AppendtoGraph/w=ImageForCursors/T LineProfileYTrace vs LineProfileXTrace
ModifyGraph  lsize(LineProfileYTrace)=2, rgb(LineProfileYTrace)=(65535,65535,0)

//Make Graph to display the measured intensity profile
Display/w=(600, 100, 1800, 350)/n=IntensityProfile temp_OFF_profile, temp_ON_profile
ModifyGraph/w=IntensityProfile rgb(temp_OFF_profile)=(0,65535,65535),  rgb(temp_ON_profile)=(65535,0,52428), lsize(temp_ON_profile)=2, lsize(temp_OFF_profile)=2

////////////////////////////////////////////////
////Make User Dialogue, ask whether profile looks ok////
////////////////////////////////////////////////

NewPanel/k=0/n=tmp_PauseforInput/w=(180,640,780,800) as "Next Molecule or Image"
//Dicplay the current Image and Molecule numbers
SetDrawEnv textrgb= (65535,0,0),fstyle= 1;
running_img_and_mol_num = ("Image: "+(num2str(l))+", Molecule: "+(num2str(molcount)))
DrawText 20,20, running_img_and_mol_num
SetDrawEnv textrgb= (0,0,0),fstyle= 0
DrawText 20,40,"YES: accept and store this profile and analyse another molecule in this image."
DrawText 20,60,"NO: to reject this profile and re-analyse this/another molecule in this image."
DrawText 20,80,"MANUAL: to define line for profile calculation manually."
DrawText 20,100,"DONE: to save all data from this image and move to the next in the stack."
Button buttonyes,pos={20,120},size={92,20},title="YES"
Button buttonyes,proc=UserYes_ContButtonProc
Button buttonno,pos={120,120},size={92,20},title="NO"
Button buttonno,proc=UserNo_ContButtonProc
Button buttonmanual,pos={220,120},size={92,20},title="MANUAL"
Button buttonmanual,proc=UserManual_ContButtonProc
Button buttondone,pos={320,120},size={92,20},title="DONE"
Button buttondone,proc=UserDone_ContButtonProc
PauseForUser tmp_PauseforInput, ImageForCursors

//Close the image with the DNA profile track and reopen without the track to reveal the DNA trace itself
Killwindow ImageForCursors
Killwindow IntensityProfile

NewImage/n=ImageForCursors DisplayWave
ShowInfo
Cursor/I/C=(65535,65535,65535)/S=1 A DisplayWave cursorAx, cursorAy
Cursor/I/C=(65535,65535,65535)/S=1 B DisplayWave cursorBx, cursorBy

AppendtoGraph/w=ImageForCursors/T Analysed_Y_Tracks vs Analysed_X_Tracks
ModifyGraph mode(Analysed_Y_Tracks)=3,marker(Analysed_Y_Tracks)=2,msize(Analysed_Y_Tracks)=4,rgb(Analysed_Y_Tracks)=(65535,65535,0)
Doupdate/w=ImageForCursors

///////////////////////
 ////// M A N U A L //////
///////////////////////

if (MANUAL==1)

do

//If user clicks MANUAL, run loop to set cursors manually, then analyse the profile for length
Killwindow ImageForCursors
Wave wav = $image_name_overlay
Duplicate/o wav, DisplayWave
NewImage/n=ImageForCursors DisplayWave
ShowInfo

AppendtoGraph/w=ImageForCursors/T Analysed_Y_Tracks vs Analysed_X_Tracks
ModifyGraph mode(Analysed_Y_Tracks)=3,marker(Analysed_Y_Tracks)=2,msize(Analysed_Y_Tracks)=4,rgb(Analysed_Y_Tracks)=(65535,65535,0)
Doupdate/w=ImageForCursors


NewPanel/k=2/n=tmp_PauseforManualCursor/w=(180,640,480,770) as "Pause for manual cursors"
Cursor/I/C=(65535,65535,65535)/S=1 A DisplayWave cursorAx, cursorAy
Cursor/I/C=(65535,65535,65535)/S=1 B DisplayWave cursorBx, cursorBy
AutoPositionWindow/E/M=1/R=ImageForCursors	// Put panel near the graph
SetDrawEnv textrgb= (65535,0,0),fstyle= 1;
running_img_and_mol_num = ("Image: "+(num2str(l))+", Molecule: "+(num2str(molcount)))
DrawText 20,20, running_img_and_mol_num
SetDrawEnv textrgb= (0,0,0),fstyle= 0
DrawText 20,40,"Set the A and B cursors at the beginning"
DrawText 20,60,"and end of the fluorescence traces"
DrawText 20,80,"then press Continue."
Button button0manual,pos={110,90},size={92,20},title="Continue"
Button button0manual,proc=UserCrsrManAdj_ContBttnProc
PauseForUser tmp_PauseforManualCursor, ImageForCursors

cursorAx = 0
cursorAy = 0
cursorBx = 0
cursorBy = 0
cursorAx = hcsr(A)
cursorAy = vcsr(A)
cursorBx = hcsr(B)
cursorBy = vcsr(B)

//Make trace for line profile
LineProfileXTrace = 0
LineProfileYTrace = 0
LineProfileXTrace={cursorAx,cursorBx}, LineProfileYTrace={cursorAy,cursorBy}

//Generate line profile along Flow OFF image
ImageLineProfile srcWave=$image_name_cyan, xWave=LineProfileXTrace, yWave=LineProfileYTrace, width=linewidth
Duplicate/o W_ImageLineProfile, temp_OFF_profile
temp_OFF_profile = 0
Duplicate/o W_ImageLineProfile, temp_OFF_profile

//Generate line profile along Flow ON image
ImageLineProfile srcWave=$image_name_magenta, xWave=LineProfileXTrace, yWave=LineProfileYTrace, width=linewidth
Duplicate/o W_ImageLineProfile, temp_ON_profile
temp_ON_profile = 0
Duplicate/o W_ImageLineProfile, temp_ON_profile

//Make Graph to display the measured intensity profile
Killwindow IntensityProfile
Display/w=(600, 100, 1800, 350)/n=IntensityProfile temp_OFF_profile, temp_ON_profile
ModifyGraph/w=IntensityProfile rgb(temp_OFF_profile)=(0,65535,65535),  rgb(temp_ON_profile)=(65535,0,52428), lsize(temp_ON_profile)=2, lsize(temp_OFF_profile)=2

Killwindow ImageForCursors
NewImage/n=ImageForCursors DisplayWave

//Add flag for already analysed molecules
AppendtoGraph/w=ImageForCursors/T Analysed_Y_Tracks vs Analysed_X_Tracks
ModifyGraph mode(Analysed_Y_Tracks)=3,marker(Analysed_Y_Tracks)=2,msize(Analysed_Y_Tracks)=4,rgb(Analysed_Y_Tracks)=(65535,65535,0)
Doupdate/w=ImageForCursors

//Plot trace for line profile on DNA image in thick yellow
AppendtoGraph/w=ImageForCursors/T LineProfileYTrace vs LineProfileXTrace
ModifyGraph  lsize(LineProfileYTrace)=2, rgb(LineProfileYTrace)=(65535,65535,0)
Doupdate/w=ImageForCursors

ShowInfo
Cursor/I/C=(65535,65535,65535)/S=1 A DisplayWave cursorAx, cursorAy
Cursor/I/C=(65535,65535,65535)/S=1 B DisplayWave cursorBx, cursorBy
Doupdate/w=ImageForCursors

NewPanel/k=0/n=tmp_PauseforInput/w=(180,640,780,800) as "Do you like your manual profile?"
//Display the current Image and Molecule numbers
SetDrawEnv textrgb= (65535,0,0),fstyle= 1;
running_img_and_mol_num = ("Image: "+(num2str(l))+", Molecule: "+(num2str(molcount)))
DrawText 20,20, running_img_and_mol_num
SetDrawEnv textrgb= (0,0,0),fstyle= 0
DrawText 20,40,"YES: accept your manual profile and continue with analysis."
DrawText 20,60,"NO: to reject your manual profile and manually set cursors again."
DrawText 20,80,"AUTOMATIC: to reject your manual profile and return to the automatic profiler"
Button buttonyes,pos={20,120},size={92,20},title="YES"
Button buttonyes,proc=UserYes_ContButtonProc
Button buttonno,pos={120,120},size={92,20},title="NO"
Button buttonno,proc=UserNo_ContButtonProc
Button buttonno1,pos={220,120},size={92,20},title="AUTOMATIC"
Button buttonno1,proc=UserNo1_ContButtonProc
PauseForUser tmp_PauseforInput, ImageForCursors

while (NO == 1)

endif

/////////////////
////// Y E S //////
/////////////////


//If user clicks YES, analyse the profile for length
if (YES==1)



//save the DNA profile to a unique name (image file name + underscore + "mol" + running number)
//wave_starts = (wave_id+(num2str(l))+"_mol"+(num2str(molcount))+"_DNAStarts")
wave_anchor = ("img"+(num2str(l))+"_mol"+(num2str(molcount))+"_Anchor")
wave_starts = ("img"+(num2str(l))+"_mol"+(num2str(molcount))+"_DNAStarts")
wave_ends =  ("img"+(num2str(l))+"_mol"+(num2str(molcount))+"_DNAEnds")
wave_measurementsDNA =  ("Img_"+(num2str(l))+"mol"+(num2str(molcount))+"_DNAlength")
wave_measurementsGAP =  ("Img_"+(num2str(l))+"mol"+(num2str(molcount))+"_GAPlength")



///////////////////////////////////////
/// Detection using Derivative ///
///////////////////////////////////////

do

Killwindow IntensityProfile

//Make Graph to display the measured intensity profile
Display/w=(600, 100, 1800, 350)/n=IntensityProfile temp_OFF_profile, temp_ON_profile
ModifyGraph/w=IntensityProfile rgb(temp_OFF_profile)=(0,65535,65535), rgb(temp_ON_profile)=(65535,0,52428)
ModifyGraph/w=IntensityProfile lsize(temp_ON_profile)=2, lsize(temp_OFF_profile)=2
Doupdate/w=IntensityProfile

//Confirm SD factor for detection//
Prompt std_dev, "Factor for Flow-ON DNA length detection"
Prompt anchor_max_x, "Maximum x-axis value for anchor detection"
Prompt box, "Value for box filter detection"
DoPrompt "Enter parameters",  std_dev, anchor_max_x, box

//for the OFF profile
findpeak/b=1/q/r=(0,anchor_max_x) temp_OFF_profile
anchor_peak_x = 0
anchor_peak_x = V_PeakLoc
anchor_fit_start = 0
anchor_fit_start = (anchor_peak_x-(anchor_peak_x-2))
anchor_fit_end = 0
anchor_fit_end = (anchor_peak_x+2)

Make/o/n=4 coefficient_wave=0

curvefit /NTHR=0/N=1/Q=1 Sigmoid kwCWave=coefficient_wave,  temp_OFF_profile[anchor_fit_start, anchor_fit_end] /D

anchor_x_location = coefficient_wave[2]

make/o/n=1 anchor_sigmoid_location, anchor_peak_location
anchor_sigmoid_location = 0
anchor_peak_location = 0
anchor_sigmoid_location[0] = anchor_x_location
anchor_peak_location[0] = anchor_peak_x

coefficient_wave = 0

//for the ON profile
wavestats temp_ON_profile
make/o /n=(V_npnts)  derivative_one=0, derivative_two=0, derivative_threshold_pos=0, derivative_threshold_neg=0
duplicate/o temp_ON_profile, profile_smooth
smooth /B=(box), profile_smooth
differentiate profile_smooth /d=derivative_one
differentiate derivative_one /d=derivative_two
duplicate/o derivative_one, derivative_one_smooth
smooth /B box, derivative_one_smooth
duplicate/o derivative_two, derivative_two_smooth
smooth /B box, derivative_two_smooth 
wavestats/r=[1,6] derivative_one_smooth
smooth_avg = V_avg
smooth_sd = V_sdev


/// FLOW ON DNA LENGTH CALCULATION ///


//Calculate the positive DNA Background Threhold //	
derivative_threshold_pos = 0
derivative_threshold_pos = smooth_avg+(std_dev*smooth_sd)
deriv_threshold_pos =  (smooth_avg+(std_dev*smooth_sd))

//Calculate the negative DNA Background Threhold //	
derivative_threshold_neg = 0
derivative_threshold_neg = derivative_threshold_pos *-1
deriv_threshold_neg = (smooth_avg+(std_dev*smooth_sd)*-1)

findlevels /b=1/d=levels_temp/EDGE=1 derivative_one_smooth, deriv_threshold_pos
wavestats levels_temp
make/o /n=(V_npnts) pos_x_levels=0, pos_x_peaks=0
pos_x_levels = 0
pos_x_levels = levels_temp
levels_temp = 0

make/o/n=(numpnts(pos_x_levels)) dna_starts=0

Variable h, g
h=0
for(h=0; h<= (numpnts (pos_x_levels));h+=1)
Variable temp_level
temp_level = (pos_x_levels[h])
findpeak/q/r=(temp_level-3, (temp_level+6)) derivative_one
pos_x_peaks[h] = V_PeakLoc
dna_starts[h] = V_PeakLoc //delete this if activating the sigmoidal fit below again
endfor

findlevels /b=1/d=levels_temp/EDGE=1 derivative_one_smooth, deriv_threshold_neg
wavestats levels_temp
make/o /n=(V_npnts) neg_x_levels=0, neg_x_peaks=0
neg_x_levels = 0
neg_x_levels = levels_temp
levels_temp = 0

make/o/n=(numpnts(neg_x_levels)) dna_ends=0

for(h=0; h<= (numpnts (neg_x_levels));h+=1)
temp_level = 0
temp_level = (neg_x_levels[h])
findpeak/q/n/r=((temp_level-6), temp_level+3) derivative_one
neg_x_peaks[h] = V_PeakLoc
dna_ends[h] = V_PeakLoc //delete this if activating the sigmoidal fit below again
endfor

duplicate pos_x_levels $pos_x_lev
duplicate neg_x_levels $neg_x_lev


//dna_length = 0
//gap_length = 0

//	g = 0
//	h = 0
//	for(h=0; h<= (numpnts (pos_x_levels)-1);h+=1)
//	fit_start = 0
//	fit_end = 0
//	fit_start = pos_x_levels[h] -4
//	fit_end = pos_x_levels[h] +7 
	
//	coefficient_wave=0
	
//	curvefit /NTHR=0/N=1/Q=1 Sigmoid kwCWave=coefficient_wave,  temp_ON_profile[fit_start, fit_end] /D 
	
//	dna_starts[h] = coefficient_wave[2]

	//g = g+1
//	endfor
	
	
	g = 0
	h = 0
	
//	for(h=0; h<= (numpnts (neg_x_levels)-1);h+=1)
//	fit_start = 0
//	fit_end = 0
//	fit_start = neg_x_levels[h] - 7
//	fit_end = neg_x_levels[h] + 4
	
//	Make/o/n=4 coefficient_wave=0
	
//	curvefit /NTHR=0/N=1/Q=1 Sigmoid kwCWave=coefficient_wave,  temp_ON_profile[fit_start, fit_end] /D 
//	
//	dna_ends[h] = coefficient_wave[2]
	
//	dna_length[h] = (dna_ends[h]-dna_starts[h])
	//g = g+1
//	endfor


	//make waves with arbitrary Y-values to plot the x-values from the level crossings against
	wavestats dna_starts
	make/o /n=(V_npnts) Yaxis1_temp=0  	//for the start points
	wavestats dna_ends
	make/o /n=(V_npnts) Yaxis2_temp=0 	//for the end points
	make/o /n=(1) Yaxis3_temp=0			//for the anchor at sigmoid
	make/o /n=(1) Yaxis4_temp=0			//for the anchor at peak
	
	wavestats temp_ON_profile
	profile_max = (1.1*V_max)
	Yaxis1_temp = profile_max
	Yaxis2_temp =  (profile_max+2)
	
	profile_max = 0
	wavestats temp_ON_profile
	profile_max = (1.1*V_max)
	Yaxis3_temp =  (profile_max+3)
	
	profile_max = 0
	wavestats temp_ON_profile
	profile_max = (1.1*V_max)
	Yaxis4_temp =  (profile_max+4)


//Make Graph to display the derivative (dotted), smoothed derivative (thick) and positive and negative threshold (black lines)
Display/w=(600, 400, 1200, 550)/n=IntensityProfileDerivative derivative_one, derivative_one_smooth, derivative_threshold_pos, derivative_threshold_neg
SetAxis/w=IntensityProfileDerivative bottom 1,*
ModifyGraph rgb(derivative_threshold_pos)=(0,0,0),rgb(derivative_threshold_neg)=(0,0,0),rgb(derivative_one)=(65535,0,52428),rgb(derivative_one_smooth)=(65535,0,52428)
ModifyGraph lstyle(derivative_one)=2, lstyle(derivative_one_smooth)=0, lsize(derivative_one_smooth)=3
Legend/C/N=text0/J/F=0/B=1 "\\s(derivative_threshold_pos) Positive Threshold\r\\s(derivative_threshold_pos) Negative Threshold\r\\s(derivative_one) Derivative\r\\s(derivative_one_smooth) Smoothed Derivative"
Legend/C/N=text0/J "\\s(derivative_threshold_pos) Pos Threshold\t\\s(derivative_one) Derivative"
AppendText/N=text0 "\\s(derivative_threshold_pos) Neg Threshold\t\\s(derivative_one_smooth) Smoothed Derivative"
Legend/C/N=text0/J/A=RT/X=-6.94/Y=-8.08

//Set axis to exclude zero in order to omit zero-markers of the level crossings
SetAxis/w=IntensityProfile bottom 1,*

//Add level crossings / DNA start and DNA end points to the profile graph
AppendToGraph/w=IntensityProfile Yaxis1_temp vs dna_starts
AppendToGraph/w=IntensityProfile Yaxis2_temp vs dna_ends
AppendToGraph/w=IntensityProfile Yaxis3_temp vs anchor_sigmoid_location
AppendToGraph/w=IntensityProfile Yaxis4_temp vs anchor_peak_location
ModifyGraph/w=IntensityProfile mode(Yaxis1_temp)=8,marker(Yaxis1_temp)=23,msize(Yaxis1_temp)=3,rgb(Yaxis1_temp)=(16386,65535,16385)
ModifyGraph/w=IntensityProfile mode(Yaxis2_temp)=8,marker(Yaxis2_temp)=23,msize(Yaxis2_temp)=3,rgb(Yaxis2_temp)=(0,0,0)
ModifyGraph/w=IntensityProfile mode(Yaxis3_temp)=8,textMarker(Yaxis3_temp)={"Asi","default",0,0,5,0.00,9.00},msize(Yaxis3_temp)=3,rgb(Yaxis3_temp)=(0,65535,65535)
ModifyGraph/w=IntensityProfile mode(Yaxis4_temp)=8,textMarker(Yaxis4_temp)={"Ape","default",0,0,5,0.00,9.00},msize(Yaxis4_temp)=3,rgb(Yaxis4_temp)=(0,65535,65535)

////////////////////////////////////////////////
////Make User Dialogue, ask whether profile looks ok////
////////////////////////////////////////////////

NewPanel/k=0/w=(600,680,1200,810) as "DNA and Gap Detection"
DoWindow/C tmp_PauseforInput
DrawText 20,20,"YES: accept and store this analysis and continue"
DrawText 20,40,"EDIT: to edit this analysis"
DrawText 20,60,"NO: to reject this analysis and re-analyse this molecule"
DrawText 20,80,"DONE: to reject this analysis and proceed to the next molecule without saving"
Button buttonyes1,pos={20,100},size={92,20},title="YES"
Button buttonyes1,proc=UserYes1_ContButtonProc
Button buttonno1,pos={120,100},size={92,20},title="NO"
Button buttonno1,proc=UserNo1_ContButtonProc
Button buttonedit1,pos={220,100},size={92,20},title="EDIT"
Button buttonedit1,proc=UserEdit1_ContButtonProc
Button buttondone1,pos={320,100},size={92,20},title="DONE"
Button buttondone1,proc=UserDone1_ContButtonProc
PauseForUser tmp_PauseforInput

//Killwindow IntensityProfileDerivative
Killwindow IntensityProfileDerivative
Killwindow IntensityProfile

/////////////////
////// N O ///////
/////////////////

while (NO1==1)	

//////////////////
////// E D I T //////
//////////////////

if (EDIT1==1)

Killwindow IntensityProfile

//display profile again
Display/w=(600, 100, 1800, 350)/n=IntensityProfile temp_OFF_profile, temp_ON_profile
ModifyGraph/w=IntensityProfile rgb(temp_OFF_profile)=(0,65535,65535),  rgb(temp_ON_profile)=(65535,0,52428), lsize(temp_ON_profile)=2, lsize(temp_OFF_profile)=2

String checkbox_name
Variable startpoint_loc, endpoint_loc

Variable count_start_points = (numpnts(dna_starts)-1

make/o/n=((numpnts(dna_starts))) dna_starts_checked=0

c=0
d=0

for(d=0; d<= (count_start_points);d+=1)
startpoint_loc = (PixelFromAxisVal ("IntensityProfile", "bottom", dna_starts[d]))
checkbox_name = ("CheckboxS"+(num2str(d)))
checkbox $checkbox_name, proc=$checkbox_name, win=IntensityProfile, size={10,10},title=("S"+num2str(d)),pos={startpoint_loc,2}
endfor


Variable count_end_points =  (numpnts(dna_ends)-1

make/o/n=((numpnts(dna_ends))) dna_ends_checked=0

d=0

for(d=0; d<= (count_end_points);d+=1)
endpoint_loc = (PixelFromAxisVal ("IntensityProfile", "bottom", dna_ends[d]))
checkbox_name = ("CheckboxE"+(num2str(d)))
checkbox $checkbox_name, proc=$checkbox_name, win=IntensityProfile, size={10,10},title=("E"+num2str(d)),pos={endpoint_loc,22}
endfor

SetAxis/w=IntensityProfile bottom 1,*
AppendToGraph/w=IntensityProfile Yaxis1_temp vs dna_starts
AppendToGraph/w=IntensityProfile Yaxis2_temp vs dna_ends
ModifyGraph/w=IntensityProfile mode(Yaxis1_temp)=8,marker(Yaxis1_temp)=23,msize(Yaxis1_temp)=3,rgb(Yaxis1_temp)=(16386,65535,16385)
ModifyGraph/w=IntensityProfile mode(Yaxis2_temp)=8,marker(Yaxis2_temp)=23,msize(Yaxis2_temp)=3,rgb(Yaxis2_temp)=(0,0,0)

//Generate a panel and button for "Continue" after the checkboxes have been set
NewPanel/k=0/n=tmp_PauseforCheckbox/w=(600,400,900,520) as "Pause for checkboxes"
DrawText 20,20,"Click the checkboxes for"
DrawText 20,40,"start and end points to INCLUDE"
DrawText 20,60,"then press Continue."
Button button1,pos={100,70},size={92,20},title="Continue"
Button button1,proc=UserCheckbox_ContButtonProc
PauseForUser IntensityProfile, tmp_PauseforCheckbox

//Save Anchor, DNA start and DNA end locations into named waves for user inspection later
duplicate/o dna_starts $wave_starts
duplicate/o dna_ends $wave_ends
duplicate/o anchor_sigmoid_location $wave_anchor

//summarise all data in the final output waves
imageName[p] = l
moleculeNumber[p] = molcount

//anchor position
Asigmoid[p] = anchor_sigmoid_location[0]
Apeak[p] = anchor_peak_x

//analysed track position flag
analysed_X_Tracks[(molcount-1)] = (LineProfileXTrace[0]-2)
analysed_Y_Tracks[(molcount-1)] = (LineProfileYTrace[0])

Variable r=0
c=0
for(c=0; c<= ((numpnts(dna_starts)-1));c+=1)
String temp =  ("S"+(num2str(r)))
if ((dna_starts_checked[c]) == 1)
wave temp_start = $temp
temp_start[p] = dna_starts[c]
r=r+1
endif
endfor

c=0
r=0
for(c=0; c<= ((numpnts(dna_ends)-1));c+=1)
temp =  ("E"+(num2str(r)))
if ((dna_ends_checked[c]) == 1)
wave temp_end = $temp
temp_end[p] = dna_ends[c]
r=r+1
endif
endfor

p = p+1
molcount = molcount+1

//Save Flow OFF and Flow ON profiles into named waves for user inspection later
		profile_ON_name = ("Img_"+(num2str(l))+"mol"+(num2str(molcount))+"_ONprofile")
		duplicate temp_ON_profile $profile_ON_name
		wave profile = $profile_ON_name
		
		profile_OFF_name = ("img"+(num2str(l))+"_mol"+(num2str(molcount))+"_OFFprofile")
		duplicate temp_OFF_profile $profile_OFF_name
		wave profile = $profile_OFF_name
		
endif

/////////////////
////// Y E S //////
/////////////////

if (YES1==1)

//Save Anchor, DNA start and DNA end locations into named waves for user inspection later
duplicate/o dna_starts $wave_starts
duplicate/o dna_ends $wave_ends
duplicate/o anchor_sigmoid_location $wave_anchor

//summarise all data in the final output waves
imageName[p] = l
moleculeNumber[p] = molcount

//anchor position
Asigmoid[p] = anchor_sigmoid_location[0]
Apeak[p] = anchor_peak_x

//analysed track position flag
analysed_X_Tracks[(molcount-1)] = (LineProfileXTrace[0]-2)
analysed_Y_Tracks[(molcount-1)] = (LineProfileYTrace[0])


//start points for flow ON
c=0
for(c=0; c<= ((numpnts(dna_starts)-1));c+=1)
temp =  ("S"+(num2str(c)))
wave temp_start = $temp
temp_start[p] = dna_starts[c]
endfor

//end points for flow OFF
c=0
for(c=0; c<= ((numpnts(dna_ends)-1));c+=1)
temp =  ("E"+(num2str(c)))
wave temp_end = $temp
temp_end[p] = dna_ends[c]
endfor

p = p+1
molcount = molcount+1

//Save Flow OFF and Flow ON profiles into named waves for user inspection later
		profile_ON_name = ("Img_"+(num2str(l))+"mol"+(num2str(molcount))+"_ONprofile")
		duplicate temp_ON_profile $profile_ON_name
		wave profile = $profile_ON_name
		
		profile_OFF_name = ("img"+(num2str(l))+"_mol"+(num2str(molcount))+"_OFFprofile")
		duplicate temp_OFF_profile $profile_OFF_name
		wave profile = $profile_OFF_name

endif

///////////////////
////// D O N E  //////
///////////////////

endif

//if user clicks NO, programme closes all windows and runs the cursor procedure again without saving any data
//Kill the windows with the fluorescence image and profile graph 
Killwindow IntensityProfile
KillWindow ImageForCursors

k=k+1

///////////////////
////// D O N E //////
///////////////////

while (DONE==0)				// as long as expression is TRUE
k=1


		
endfor

//Save the Data in a tab delimited text file in the data folder

String list="root:imageName;root:moleculeNumber;root:Asigmoid;root:Apeak;root:S0;root:E0;root:S1;root:E1;root:S2;root:E2;root:S3;root:E3;root:S4;root:E4;root:S5;root:E5;root:S6;root:E6;root:S7;root:E7;root:S8;root:E8;root:S9;root:E9;root:S10;root:E10;"; Save/J/W/P=data_path/B list as "AnalysedData.dat"

End



//////////// Control Button Functions ///////////////

Function UserYes_ContButtonProc(ctrlName) : ButtonControl
	String ctrlName
NVAR YES, NO, MANUAL, DONE
YES=1
MANUAL=0
NO=0
DONE=0
Killwindow tmp_PauseforInput		// Kill self
End

Function UserNo_ContButtonProc(ctrlName) : ButtonControl
	String ctrlName
NVAR YES, NO, MANUAL, DONE
YES=0
NO=1
MANUAL=0
DONE=0
Killwindow tmp_PauseforInput 		// Kill self
End


Function UserManual_ContButtonProc(ctrlName) : ButtonControl
	String ctrlName
NVAR YES, NO, MANUAL, DONE
YES=0
NO=0
MANUAL=1
DONE=0
Killwindow tmp_PauseforInput		// Kill self
End

Function UserDone_ContButtonProc(ctrlName) : ButtonControl
	String ctrlName
NVAR YES, NO, MANUAL, DONE
YES=0
NO=0
MANUAL=0
DONE=1
Killwindow tmp_PauseforInput		// Kill self
End



Function UserYes1_ContButtonProc(ctrlName) : ButtonControl
	String ctrlName
//	NewPanel/k=2/w=(139,341, 422, 522) as "Pause for User"
//DoWindow/C tmp_PauseforCursor		// Set to an unlikely name
NVAR YES1, NO1, EDIT1, MANUAL, DONE1
YES1=1
NO1=0
EDIT1=0
MANUAL = 0
DONE1=0
Killwindow tmp_PauseforInput		// Kill self
End

Function UserNo1_ContButtonProc(ctrlName) : ButtonControl
	String ctrlName
	//NewPanel/k=2/w=(139,341, 422, 522) as "Pause for User"
//DoWindow/C tmp_PauseforCursor		// Set to an unlikely name
NVAR YES1, NO1, EDIT1, MANUAL, DONE1
YES1=0
NO1=1
EDIT1=0
MANUAL = 0
DONE1=0
Killwindow tmp_PauseforInput 		// Kill self
End

Function UserEdit1_ContButtonProc(ctrlName) : ButtonControl
	String ctrlName
	//NewPanel/k=2/w=(139,341, 422, 522) as "Pause for User"
//DoWindow/C tmp_PauseforCursor		// Set to an unlikely name
NVAR YES1, NO1, EDIT1, MANUAL, DONE1
YES1=0
NO1=0
EDIT1=1
MANUAL = 0
DONE1=0
Killwindow tmp_PauseforInput 		// Kill self
End

Function UserDone1_ContButtonProc(ctrlName) : ButtonControl
	String ctrlName
//	NewPanel/k=2/w=(139,341, 422, 522) as "Pause for User"
//DoWindow/C tmp_PauseforCursor		// Set to an unlikely name
NVAR YES1, NO1, EDIT1, MANUAL, DONE1
YES1=0
NO1=0
EDIT1=0
MANUAL = 0
DONE1=1
Killwindow tmp_PauseforInput		// Kill self
End

Function UserCursorAdjust_ContButtonProc(ctrlName) : ButtonControl
	String ctrlName
	Killwindow tmp_PauseforCursor	// Kill self
End

Function UserCrsrManAdj_ContBttnProc(ctrlName) : ButtonControl
	String ctrlName
	Killwindow tmp_PauseforManualCursor	// Kill self
End

Function UserCheckbox_ContButtonProc(ctrlName) : ButtonControl
	String ctrlName
	Killwindow tmp_PauseforCheckbox
	Killwindow IntensityProfile	// Kill self
End

Function CheckboxS0 (ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	NVAR CBoxS0
	WAVE dna_starts_checked = root:dna_starts_checked
	dna_starts_checked[0] = checked			
	CBoxS0 = checked
End

Function CheckboxS1 (ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	NVAR CBoxS1
		WAVE dna_starts_checked = root:dna_starts_checked
	dna_starts_checked[1] = checked				
	CBoxS1 = checked
End

Function CheckboxS2 (ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked			// 1 if selected, 0 if not
	NVAR CBoxS2
		WAVE dna_starts_checked = root:dna_starts_checked
	dna_starts_checked[2] = checked				
	CBoxS2 = checked			
End

Function CheckboxS3 (ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked			// 1 if selected, 0 if not
	NVAR CBoxS3
		WAVE dna_starts_checked = root:dna_starts_checked
	dna_starts_checked[3] = checked				
	CBoxS3 = checked	
End

Function CheckboxS4 (ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked			// 1 if selected, 0 if not
	NVAR CBoxS4
		WAVE dna_starts_checked = root:dna_starts_checked
	dna_starts_checked[4] = checked				
	CBoxS4 = checked	
End

Function CheckboxS5 (ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked			// 1 if selected, 0 if not
	NVAR CBoxS5
		WAVE dna_starts_checked = root:dna_starts_checked
	dna_starts_checked[5] = checked				
	CBoxS5 = checked	
End

Function CheckboxS6 (ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked			// 1 if selected, 0 if not
	NVAR CBoxS6
		WAVE dna_starts_checked = root:dna_starts_checked
	dna_starts_checked[6] = checked				
	CBoxS6 = checked	
End

Function CheckboxS7 (ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked			// 1 if selected, 0 if not
	NVAR CBoxS7
		WAVE dna_starts_checked = root:dna_starts_checked
	dna_starts_checked[7] = checked				
	CBoxS7 = checked	
End

Function CheckboxS8 (ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked			// 1 if selected, 0 if not
	NVAR CBoxS8
		WAVE dna_starts_checked = root:dna_starts_checked
	dna_starts_checked[8] = checked				
	CBoxS8 = checked	
End

Function CheckboxS9 (ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked			// 1 if selected, 0 if not
	NVAR CBoxS9
		WAVE dna_starts_checked = root:dna_starts_checked
	dna_starts_checked[9] = checked				
	CBoxS9 = checked	
End

Function CheckboxS10 (ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked			// 1 if selected, 0 if not
	NVAR CBoxS10
		WAVE dna_starts_checked = root:dna_starts_checked
	dna_starts_checked[10] = checked				
	CBoxS10 = checked	
End

Function CheckboxS11 (ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked			// 1 if selected, 0 if not
	NVAR CBoxS11
		WAVE dna_starts_checked = root:dna_starts_checked
	dna_starts_checked[11] = checked				
	CBoxS11 = checked	
End

Function CheckboxS12 (ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked			// 1 if selected, 0 if not
	NVAR CBoxS12
		WAVE dna_starts_checked = root:dna_starts_checked
	dna_starts_checked[12] = checked				
	CBoxS12 = checked	
End

Function CheckboxS13 (ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked			// 1 if selected, 0 if not
	NVAR CBoxS13
		WAVE dna_starts_checked = root:dna_starts_checked
	dna_starts_checked[13] = checked				
	CBoxS13 = checked	
End

Function CheckboxS14 (ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked			// 1 if selected, 0 if not
	NVAR CBoxS14
		WAVE dna_starts_checked = root:dna_starts_checked
	dna_starts_checked[14] = checked				
	CBoxS14 = checked	
End

Function CheckboxS15 (ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked			// 1 if selected, 0 if not
	NVAR CBoxS15
		WAVE dna_starts_checked = root:dna_starts_checked
	dna_starts_checked[15] = checked				
	CBoxS15 = checked	
End

Function CheckboxS16 (ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked			// 1 if selected, 0 if not
	NVAR CBoxS16
		WAVE dna_starts_checked = root:dna_starts_checked
	dna_starts_checked[16] = checked				
	CBoxS16 = checked	
End

Function CheckboxS17 (ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked			// 1 if selected, 0 if not
	NVAR CBoxS17
		WAVE dna_starts_checked = root:dna_starts_checked
	dna_starts_checked[17] = checked				
	CBoxS17 = checked	
End

Function CheckboxS18 (ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked			// 1 if selected, 0 if not
	NVAR CBoxS18
		WAVE dna_starts_checked = root:dna_starts_checked
	dna_starts_checked[18] = checked				
	CBoxS18 = checked	
End

Function CheckboxS19 (ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked			// 1 if selected, 0 if not
	NVAR CBoxS19
		WAVE dna_starts_checked = root:dna_starts_checked
	dna_starts_checked[19] = checked				
	CBoxS19 = checked	
End

Function CheckboxS20 (ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked			// 1 if selected, 0 if not
	NVAR CBoxS20
		WAVE dna_starts_checked = root:dna_starts_checked
	dna_starts_checked[20] = checked				
	CBoxS20 = checked	
End

Function CheckboxE0 (ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked			// 1 if selected, 0 if not
	NVAR CBoxE0
	WAVE dna_ends_checked = root:dna_ends_checked
	dna_ends_checked[0] = checked				
	CBoxE0 = checked	
End

Function CheckboxE1 (ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked			// 1 if selected, 0 if not
	NVAR CBoxE1
	WAVE dna_ends_checked = root:dna_ends_checked
	dna_ends_checked[1] = checked				
	CBoxE1 = checked	
End

Function CheckboxE2 (ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked			// 1 if selected, 0 if not
	NVAR CBoxE2
	WAVE dna_ends_checked = root:dna_ends_checked
	dna_ends_checked[2] = checked				
	CBoxE2 = checked	
End

Function CheckboxE3 (ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked			// 1 if selected, 0 if not
	NVAR CBoxE3
	WAVE dna_ends_checked = root:dna_ends_checked
	dna_ends_checked[3] = checked				
	CBoxE3 = checked	
End

Function CheckboxE4 (ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked			// 1 if selected, 0 if not
	NVAR CBoxE4
	WAVE dna_ends_checked = root:dna_ends_checked
	dna_ends_checked[4] = checked				
	CBoxE4 = checked	
End

Function CheckboxE5 (ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked			// 1 if selected, 0 if not
	NVAR CBoxE5
	WAVE dna_ends_checked = root:dna_ends_checked
	dna_ends_checked[5] = checked				
	CBoxE5 = checked	
End

Function CheckboxE6 (ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked			// 1 if selected, 0 if not
	NVAR CBoxE6
	WAVE dna_ends_checked = root:dna_ends_checked
	dna_ends_checked[6] = checked				
	CBoxE6 = checked	
End

Function CheckboxE7 (ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked			// 1 if selected, 0 if not
	NVAR CBoxE7
	WAVE dna_ends_checked = root:dna_ends_checked
	dna_ends_checked[7] = checked				
	CBoxE7 = checked	
End

Function CheckboxE8 (ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked			// 1 if selected, 0 if not
	NVAR CBoxE8
	WAVE dna_ends_checked = root:dna_ends_checked
	dna_ends_checked[8] = checked				
	CBoxE8 = checked	
End

Function CheckboxE9 (ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked			// 1 if selected, 0 if not
	NVAR CBoxE9
	WAVE dna_ends_checked = root:dna_ends_checked
	dna_ends_checked[9] = checked				
	CBoxE9 = checked	
End

Function CheckboxE10 (ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked			// 1 if selected, 0 if not
	NVAR CBoxE10
	WAVE dna_ends_checked = root:dna_ends_checked
	dna_ends_checked[10] = checked				
	CBoxE10 = checked	
End

Function CheckboxE11 (ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked			// 1 if selected, 0 if not
	NVAR CBoxE11
	WAVE dna_ends_checked = root:dna_ends_checked
	dna_ends_checked[11] = checked				
	CBoxE11 = checked	
End

Function CheckboxE12 (ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked			// 1 if selected, 0 if not
	NVAR CBoxE12
	WAVE dna_ends_checked = root:dna_ends_checked
	dna_ends_checked[12] = checked				
	CBoxE12 = checked	
End

Function CheckboxE13 (ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked			// 1 if selected, 0 if not
	NVAR CBoxE13
	WAVE dna_ends_checked = root:dna_ends_checked
	dna_ends_checked[13] = checked				
	CBoxE13 = checked	
End

Function CheckboxE14 (ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked			// 1 if selected, 0 if not
	NVAR CBoxE14
	WAVE dna_ends_checked = root:dna_ends_checked
	dna_ends_checked[14] = checked				
	CBoxE14 = checked	
End

Function CheckboxE15 (ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked			// 1 if selected, 0 if not
	NVAR CBoxE15
	WAVE dna_ends_checked = root:dna_ends_checked
	dna_ends_checked[15] = checked				
	CBoxE15 = checked	
End

Function CheckboxE16 (ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked			// 1 if selected, 0 if not
	NVAR CBoxE16
	WAVE dna_ends_checked = root:dna_ends_checked
	dna_ends_checked[16] = checked				
	CBoxE16 = checked	
End

Function CheckboxE17 (ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked			// 1 if selected, 0 if not
	NVAR CBoxE17
	WAVE dna_ends_checked = root:dna_ends_checked
	dna_ends_checked[17] = checked				
	CBoxE17 = checked	
End

Function CheckboxE18 (ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked			// 1 if selected, 0 if not
	NVAR CBoxE18
	WAVE dna_ends_checked = root:dna_ends_checked
	dna_ends_checked[18] = checked				
	CBoxE18 = checked	
End

Function CheckboxE19 (ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked			// 1 if selected, 0 if not
	NVAR CBoxE19
	WAVE dna_ends_checked = root:dna_ends_checked
	dna_ends_checked[19] = checked				
	CBoxE19 = checked	
End

Function CheckboxE20 (ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked			// 1 if selected, 0 if not
	NVAR CBoxE20
	WAVE dna_ends_checked = root:dna_ends_checked
	dna_ends_checked[20] = checked				
	CBoxE20 = checked	
End