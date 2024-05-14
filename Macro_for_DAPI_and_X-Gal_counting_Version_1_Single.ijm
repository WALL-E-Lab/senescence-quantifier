/*
 note: images of X-Gal and DAPI should be acquired with the same 10x objective and the same color camera.
 The contrast from X-Gal images should originate from X-Gal color alone; any other contrast (phase contrast or similar) should be avoided.
 The macro supports RGB image type with single slice and 8 or 12 (16)-bit image types with 3 slices (color cam channels). 
*/
//_________________________________________________DAPI______________________________________________________________________________________________________________________________________________________________

waitForUser("Please close other images and open one original DAPI image");//the image should be acquired with the same color camera as for X-Gal images
	
ansSegmentation=0;
while (ansSegmentation==0) {
	
	  Dialog.create("Please define:");
	  	Dialog.addMessage("DAPI segmentation:");
	  	Dialog.addNumber("Gaussian Blur sigma (radius) for DAPI segmentation (larger radius -> less objects):", 4);
   	  	Dialog.addNumber("Define the minimum threshold for DAPI (higher threshold  -> less objects):", 25); 	  	
	 	Dialog.addNumber("Find Maxima prominence for DAPI segmentation (more prominence  -> less objects):", 30);
		Dialog.show();
	
	    gaussRadius = Dialog.getNumber();
	    minThresholdDAPI = Dialog.getNumber(); 
	    findMaxprominence = Dialog.getNumber();
	    	    
	//prepare for analysis
	roiManager("Reset");

	if (bitDepth() == 24) {//for RGB images 
		run("Split Channels");
		run("Images to Stack", "name=Stack title=[] use");
		setSlice(3);
		}	
	else setSlice(2);//for original images with more channels acquired with color camera
	title=getTitle();
	run("Duplicate...", "title=Snap-2.czi");
	rename(title+" DAPI");
	run("Duplicate...", "title=dupl");
	
	//segment DAPI
	run("Subtract Background...", "rolling=30");
	run("Gaussian Blur...", "sigma="+gaussRadius);//to segment..
	run("Brightness/Contrast...");
	run("Threshold...");
	setAutoThreshold("Default dark");
	getThreshold(lower, upper);
	setThreshold(minThresholdDAPI, upper);
	waitForUser("Please check the threshold for DAPI segmentation.");
	getThreshold(lower, upper);
	run("Options...", "iterations=1 count=1 black edm=Overwrite do=Nothing");
	run("Find Maxima...", "prominence="+findMaxprominence+" output=[Segmented Particles] above");//check min prominence (prominence)
	setAutoThreshold("Default dark");
	
	//analyze DAPI particles
	rename(title+" DAPI");
	run("Analyze Particles...", "size=50-Infinity pixel circularity=0.00-1.00 show=Nothing summarize add");
	close();
	close();
	
	//display results and visually inspect DAPI segmentation
	roiManager("Show None");
	roiManager("Show All");
	waitForUser("Please check the DAPI segmentation");
	roiManager("deselect");
	roiManager("Combine");
	roiManager("Reset");
	roiManager("Add");
	run("Brightness/Contrast...");
	titleTemp=getTitle();
ansSegmentation=getBoolean("Are you satisfied with DAPI segmentation? If not the macro will restart.");	
if (ansSegmentation==0)	close(); 
}

selectWindow(title);//close original DAPI image
close();
//_______________________________________________X-Gal_________________________________________________________________________________________________________________________________________________
//segment X-Gal positive cells
waitForUser("Please open the corresponding X-Gal image");

ansSegmentation=0;
while (ansSegmentation==0) {

	  Dialog.create("Please define:");
	  	Dialog.addMessage("X-Gal segmentation:");
	  	Dialog.addNumber("Gaussian Blur sigma (radius) for X-Gal segmentation (larger radius -> less objects):", 1);	  		
   	  	Dialog.addNumber("Define the minimum threshold for X-Gal (higher threshold  -> less objects):", 35); 
	 	Dialog.addNumber("Find maxima prominence for X-Gal segmentation (more prominence  -> less objects):", 40);
	 	Dialog.addNumber("Define the minimum X-Gal positive cell AREA in pxl2 (larger area -> less objects):", 150);
		Dialog.show();

		gaussRadiusX = Dialog.getNumber();
	    minThreshold = Dialog.getNumber(); 
	    findMaxprominenceX = Dialog.getNumber(); 
	    minArea = Dialog.getNumber();
	    
titleX=getTitle();
getBit=bitDepth();
if (nSlices>1) {
	if (getBit == 16) {//for original X-Gal images with more channels acquired with 12-bit color camera
	run("Brightness/Contrast...");
	setSlice(1);
	setMinAndMax(1000, 3700);//please choose B&C, but set the same for all 3 slices 
	setSlice(2);
	setMinAndMax(1000, 3700);
	setSlice(3);
	setMinAndMax(1000, 3700);
	run("RGB Color");
	titleX=getTitle();
	}
	if (getBit == 8) {//for original X-Gal images acquired with 8-bit color cam 
	setSlice(1);
	setMinAndMax(30, 230);//please choose B&C, but set the same for all 3 slices 
	setSlice(2);
	setMinAndMax(30, 230);
	setSlice(3);
	setMinAndMax(30, 230);
	run("RGB Color");
	titleX=getTitle();
	}
}

selectWindow(titleX);
if (getBit == 24) run("Duplicate...", " ");
run("8-bit");
run("Invert");
run("Subtract Background...", "rolling=50");
run("Gaussian Blur...", "sigma="+gaussRadiusX);
run("Threshold...");
setAutoThreshold("Default dark");
setThreshold(minThreshold, 255);
waitForUser("Please check the threshold for X-Gal.");
getThreshold(minThreshold, upper);
run("Find Maxima...", "prominence="+findMaxprominenceX+" output=[Segmented Particles] above");
roiManager("Select", 0);
run("Enlarge...", "enlarge=20 pixel");//only X-Gal in the proximity of 20 pxl from DAPI will be analyzed 
setBackgroundColor(0, 0, 0);
run("Clear Outside");
run("Select None");

//count X-Gal cells
setAutoThreshold("Default dark");
rename(title+" X-Gal");
run("Analyze Particles...", "size="+minArea+"-Infinity pixel circularity=0.00-1.00 show=Nothing summarize add");
close();
close();

//display results
roiManager("Show None");
roiManager("Show All");
roiManager("Select", 0);
ansSegmentation=getBoolean("Are you satisfied with X-Gal segmentation? If not the macro will loop back.");	
if (ansSegmentation==0)	{
	roiManager("Select", 0);
	roiManager("Reset");	
	roiManager("Add");
	run("Select None");	 
}
}

//__________________________________________________Report______________________________________________________________________________________________________________________________________________________________________________________
//_______________________________________________________________________________________________________________________________________________________________________________________________________________________________________________
							
print("\\Clear");
print("");
print("DAPI segmentation and analysis:");
print("The background was subtracted from DAPI images using the Rolling Ball Background Subtraction with radius 30 pxl.");
print("DAPI images were filtered using the Gaussian Blur with the radius set to "+gaussRadius+".");
print("Images were segmented using the Find Maxima tool with the prominence set to "+findMaxprominence+" above threshold "+lower+".");
print("Minimum analyzed DAPI particle area was set to 50 pxl.");
print("");
print("X-Gal segmentation and analysis:");
print("The background was subtracted from X-Gal images using the Rolling Ball Background Subtraction with radius 50 pxl.");
print("X-Gal images were filtered using the Gaussian Blur with the radius set to "+gaussRadiusX+" pxl.");
print("Images were segmented using the Find Maxima tool with the prominence set to "+findMaxprominenceX+" above threshold "+minThreshold+".");
print("Minimum analyzed X-Gal particle area was set to "+minArea+" pxl.");
print("____________________________________________________________________________________________________________________________________________________________________________________________________"); 														
print("The 'GNU General Public License' applies; http://www.gnu.org/licenses/gpl.html - in short - free to use and modify, no warranty provided.");
															