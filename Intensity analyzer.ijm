// Determine intensities of spots in primase dropout experiments from coordinates
// ImageJ 1.4 macro
// James Graham, 2015

// Intensity measurement of tracked spots in leading-strand-only experiments

run("Close All");
run("Clear Results");
run("Set Measurements...", "integrated redirect=None decimal=3");
print("\\Clear");

// Dialog box to establish where the text file is that describes which frames to extract
// Must have a batch file called ~/intensity.txt with the following parameters:
// path_of_image
// working_directory
// radius
// start_track
// end_track

catch=File.exists("/Users/jeggy/intensities.txt");
if (catch == false) {
	exit();
}
// Parse batch file
batch=File.openAsString("/Users/jeggy/intensities.txt"); 
rows=split(batch, "\n");
columns=split(rows[0],"\t");
movieFile=columns[1];
columns=split(rows[1],"\t");
path=columns[1];
columns=split(rows[2],"\t");
radius=columns[1];
columns=split(rows[3],"\t");
start=parseInt(columns[1]);
columns=split(rows[4],"\t");
end=parseInt(columns[1]);

File.makeDirectory(path+"/intensities");
fileName = File.getName(movieFile);
saveNameExtension=path+fileName;
saveName=substring(saveNameExtension,0,lengthOf(saveNameExtension)-4);

//movieFile = File.openDialog("Where is the movie located?");
//path = getDirectory("Please set the working directory.");
trackPath = path + "coords/";
//print("Track path is "+trackPath);

open(movieFile);
rename("Movie");
numberOfFramesTotal=nSlices();
numberOfTracks=end-start+1;

/// Prompt user to choose three background locations

run("Clear Results");
//while (nResults < 3) {
//waitForUser("Select multi-point tool and click three background points.\nWhen finished click OK.");
//run("Measure");
//}
//			xB = newArray(3);
//			yB = newArray(3);
//
//				for (i=0; i<3; i++) {
//					xB[i]=getResult("X", i);
//					yB[i]=getResult("Y", i);
//								}
//run("Clear Results");



///////////////////////////////
// This first loop just obtains the measurements

for (i=start; i<(end+1); i++) {

print("\\Clear");
run("Clear Results");
trackFile=trackPath+i+".txt";
//print("Track file "+trackFile);
filestring=File.openAsString(trackFile); 

rows=split(filestring, "\n");
frameNumber=newArray((rows.length)+1);
xCoord=newArray((rows.length)+1); 
yCoord=newArray((rows.length)+1);
xStartingLoc=newArray(numberOfTracks);
yStartingLoc=newArray(numberOfTracks);
numberOfLines=(rows.length);
intensity=newArray(nSlices+1);
bg1=newArray(nSlices+1);
bg2=newArray(nSlices+1);
bg3=newArray(nSlices+1);
background=newArray(nSlices+1);

// Parse the text file

//print ("Number of frames with tracks:"+(numberOfLines-1));
for(j=1; j<(numberOfLines); j++){
	columns=split(rows[j],"\t");	/// starts at row 1, as row 0 is a header
	frameNumber[j]=parseInt(columns[0]);
	xCoord[j]=parseInt(columns[1]);
	yCoord[j]=parseInt(columns[2]);
}



// Go through ALL frames one by one and record intensity
// Line in array that we are currently pointing to is held by variable 'arrayPointer'.

firstFrame=frameNumber[1];
arrayPointer=1;

j=1;
while (j<nSlices) {
	
	// Start from the first recorded frame, which is position 1 of the array.
	
	// Should fill in where a point wasn't recorded by taking the coordinates of the last known good frame
	// yet should record that the position info was missing.
	
		setSlice(j);

  // As long as the end of the array hasn't been reached...
		if (frameNumber[arrayPointer]+1==j && j<numberOfLines) {
			makeOval(xCoord[arrayPointer]-radius,yCoord[arrayPointer]-radius,radius*2,radius*2);
			run("Measure");
			// Get background values
			//for (m=0; m<3; m++) {
			//	makeOval(xB[m]-radius,yB[m]-radius,radius*2,radius*2);
			//	run("Measure");
			//}
			//bg3[j]=getResult("Mean",nResults-1);
			//bg2[j]=getResult("Mean",nResults-2);
			//bg1[j]=getResult("Mean",nResults-3);
			//background[j]=(bg1[j]+bg2[j]+bg3[j])/3;
			intensity[j]=getResult("IntDen");

			arrayPointer++; // increment arrayPointer if a point was recorded
			
		} else {
			
			makeOval(xCoord[arrayPointer-1]-radius,yCoord[arrayPointer-1]-radius,radius*2,radius*2);
			run("Measure");
			// Get background values
			//for (m=0; m<3; m++) {
			//	makeOval(xB[m]-radius,yB[m]-radius,radius*2,radius*2);
			//	run("Measure");
			//}
			//bg3[j]=getResult("Mean",nResults-1);
			//bg2[j]=getResult("Mean",nResults-2);
			//bg1[j]=getResult("Mean",nResults-3);
			//background[j]=(bg1[j]+bg2[j]+bg3[j])/3;
			intensity[j]=getResult("IntDen");			
		}
	j++;}	

	// Should keep circle at the last position for all the remaining frames
	// i.e., keep drawing circles but don't increment the pointer.

	makeOval(xCoord[arrayPointer-1]-radius,yCoord[arrayPointer-1]-radius,radius*2,radius*2);
	run("Measure");
	// Get background values
			//for (m=0; m<3; m++) {
			//	makeOval(xB[m]-radius,yB[m]-radius,radius*2,radius*2);
			//	run("Measure");
			//}
			//bg3[j]=getResult("Mean",nResults-1);
			//bg2[j]=getResult("Mean",nResults-2);
			//bg1[j]=getResult("Mean",nResults-3);
			//background[j]=(bg1[j]+bg2[j]+bg3[j])/3;
			intensity[j]=getResult("IntDen");
	
	j++;

// Output to text file

print ("Frame\tintensity");
for (k=1; k<nSlices+1; k++) {
	print(k+"\t"+intensity[k]);
	//Clear the array
	intensity[k]=NaN;
}
selectWindow("Log");
saveAs("text", path+"intensities/"+i+".txt");

}

///////////////////////////////////////////////////
///////////////////////////////////////////////////
// Generate max projection  ///////////////////////
// This is for analysis of track length ///////////
///////////////////////////////////////////////////
///////////////////////////////////////////////////
///////////////////////////////////////////////////
///////////////////////////////////////////////////

run("Specify...", "width=512 height=512 x=0 y=0 slice=1");
run("Duplicate...", "title=FirstSlice ");
selectWindow("Movie");
run("Z Project...", "projection=[Max Intensity]");
rename("Max");
run("Merge Channels...", "c5=FirstSlice c6=Max create keep");
saveAs(saveName+"_proj.tif");
run("Stack to RGB");

for (i=start; i<(end+1); i++) {

trackFile=trackPath+i+".txt";
filestring=File.openAsString(trackFile); 

rows=split(filestring, "\n");
frameNumber=newArray((rows.length)+1);
xCoord=newArray((rows.length)+1); 
yCoord=newArray((rows.length)+1);
xStartingLoc=newArray(numberOfTracks);
yStartingLoc=newArray(numberOfTracks);
numberOfLines=(rows.length);

// Parse the text file

//print ("Number of frames with tracks:"+(numberOfLines-1));
for (j=1; j<(numberOfLines); j++){
columns=split(rows[j],"\t");	/// starts at row 1, as row 0 is a header
frameNumber[j]=parseInt(columns[0]);
xCoord[j]=parseInt(columns[1]);
yCoord[j]=parseInt(columns[2]);
}
wait(100);
setColor(255,255,255);
setFont("SansSerif",12,"antialiased");
drawString(i,xCoord[1]-10,yCoord[1]+5);
}
saveAs(saveName+"_proj_RGB.tif");




///////////////////////////////////////////////////
///////////////////////////////////////////////////
// Now, generate a key ////////////////////////////
///////////////////////////////////////////////////
///////////////////////////////////////////////////
///////////////////////////////////////////////////
///////////////////////////////////////////////////

selectWindow("Movie");
for (i=start; i<(end+1); i++) {

trackFile=trackPath+i+".txt";
filestring=File.openAsString(trackFile); 

rows=split(filestring, "\n");
frameNumber=newArray((rows.length)+1);
xCoord=newArray((rows.length)+1); 
yCoord=newArray((rows.length)+1);
xStartingLoc=newArray(numberOfTracks);
yStartingLoc=newArray(numberOfTracks);
numberOfLines=(rows.length);

// Parse the text file

//print ("Number of frames with tracks:"+(numberOfLines-1));
for(j=1; j<(numberOfLines); j++){
	columns=split(rows[j],"\t");	/// starts at row 1, as row 0 is a header
	frameNumber[j]=parseInt(columns[0]);
	xCoord[j]=parseInt(columns[1]);
	yCoord[j]=parseInt(columns[2]);
	//print (frameNumber[j],xCoord[j],yCoord[j]);
}

firstFrame=frameNumber[1];
//print ("First frame:"+firstFrame);
arrayPointer=1;

j=1;
run("RGB Color");
setFont("SansSerif",12,"antialiased");

while (j<nSlices()+1) {
	
	// Start from the first recorded frame, which is position 1 of the array.
	
	// Should fill in where a point wasn't recorded by taking the coordinates of the last known good frame
	// yet should record that the position info was missing.
	
		setSlice(j);
		//print("Array pointer="+arrayPointer,"j="+j,"Current frame="+getSliceNumber(),"Frame in array="+frameNumber[arrayPointer]);

  // As long as the end of the array hasn't been reached...
		if (frameNumber[arrayPointer]+1==j && j<numberOfLines) {
			setColor("cyan"); // make the oval cyan
			drawOval(xCoord[arrayPointer]-radius,yCoord[arrayPointer]-radius,radius*2,radius*2);
			arrayPointer++; // increment arrayPointer if a point was recorded
			//print((intensityValue-referenceValue)/backgroundValue);
			setColor(255,255,255);
			drawString(i,xCoord[arrayPointer]-radius*2,yCoord[arrayPointer]);
			
		} else {
			
			setColor("magenta"); // make the oval magenta
			drawOval(xCoord[arrayPointer-1]-radius,yCoord[arrayPointer-1]-radius,radius*2,radius*2);
			setColor(255,255,255);
			drawString(i,xCoord[arrayPointer-1]-radius*2,yCoord[arrayPointer-1]);
			//print((intensityValue-referenceValue)/backgroundValue);
		}
	j++;}	

	// Should keep circle at the last position for all the remaining frames
	// i.e., keep drawing circles but don't increment the pointer.

	setColor("magenta");
	drawOval(xCoord[arrayPointer-1]-radius,yCoord[arrayPointer-1]-radius,radius*2,radius*2);
	setColor(255,255,255);
	drawString(i,xCoord[arrayPointer-1]-radius*2,yCoord[arrayPointer-1]);
	//print((intensityValue-referenceValue)/backgroundValue);
	j++;


}

selectWindow("Movie");
saveAs(saveName+"_movie_key.tif");
//run("AVI... ", "frame=24 save="+saveName+"_key.avi");

run("Close All");

// Ouptut log file

print("\\Clear");
MonthNames = newArray("Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec");
     DayNames = newArray("Sun", "Mon","Tue","Wed","Thu","Fri","Sat");
     getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
     TimeString ="Date: "+DayNames[dayOfWeek]+" ";
     if (dayOfMonth<10) {TimeString = TimeString+"0";}
     TimeString = TimeString+dayOfMonth+"-"+MonthNames[month]+"-"+year+"\nTime: ";
     if (hour<10) {TimeString = TimeString+"0";}
     TimeString = TimeString+hour+":";
     if (minute<10) {TimeString = TimeString+"0";}
     TimeString = TimeString+minute+":";
     if (second<10) {TimeString = TimeString+"0";}
     TimeString = TimeString+second;

f=File.open(path+"Log.txt");
print(f,""+TimeString);
print(f,"Movie file: "+movieFile);
print(f,"Number of tracks analyzed: "+numberOfTracks+" ("+start+" to "+end);
print(f,"Working path: "+path);
print(f,"Radius: "+radius);
File.close(f);

run("Quit");

