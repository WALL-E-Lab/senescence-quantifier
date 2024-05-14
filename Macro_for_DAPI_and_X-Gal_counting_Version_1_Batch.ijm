/*
 note: images of X-Gal and DAPI should be acquired with the same 10x objective and the same color camera.
 The contrast from X-Gal images should originate from X-Gal color alone; any other contrast (phase contrast or similar) should be avoided.
 The macro supports RGB image type with single slice and 8 or 12 (16)-bit image types with 3 slices (color cam channels).
 Activate Windowless import in Plugins - Bio-Formats, set it to Hyperstack with Default color mode and run the macro. 
*/

dir = getDirectory("Choose an Input Directory for DAPI");
dir2 = getDirectory("_Choose an Input Directory for X Gal");
list = getFileList(dir);
list2 = getFileList(dir2);

	  Dialog.create("Please define:");
	  	Dialog.addMessage("DAPI segmentation:");
	  	Dialog.addNumber("Gaussian Blur sigma (radius) for DAPI segmentation (larger radius -> less objects):", 4);
   	  	Dialog.addNumber("Define the minimum threshold for DAPI (higher threshold  -> less objects):", 25); 	  	
	 	Dialog.addNumber("Find Maxima prominence for DAPI segmentation (more prominence  -> less objects):", 30);
		Dialog.addMessage(" ");

	  	Dialog.addMessage("X-Gal segmentation:");
	  	Dialog.addNumber("Gaussian Blur sigma (radius) for X-Gal segmentation (larger radius -> less objects):", 1);	  		
   	  	Dialog.addNumber("Define the minimum threshold for X-Gal (higher threshold  -> less objects):", 35); 
	 	Dialog.addNumber("Find Maxima prominence for X-Gal segmentation (more prominence  -> less objects):", 40);
	 	Dialog.addNumber("Define the minimum X-Gal positive cell AREA in pxl2 (larger area -> less objects):", 150);
		Dialog.show();

	    gaussRadius = Dialog.getNumber();
	    minThresholdDAPI = Dialog.getNumber(); 
	    findMaxprominence = Dialog.getNumber();
	    
	    gaussRadiusX = Dialog.getNumber();
	    minThreshold = Dialog.getNumber(); 
	    findMaxprominenceX = Dialog.getNumber(); 
	    minArea = Dialog.getNumber();

for (i=0; i<list.length; i++) {

showProgress(i, list.length);
    open(dir+list[i]);
	titleOri=getTitle();
	roiManager("Reset");
//_________________________________________________DAPI______________________________________________________________________________________________________________________________________________________________
	getBit=bitDepth();	
	if (nSlices>1) {	
		if (getBit == 16) setSlice(2);//for original DAPI images with more channels acquired with 12-bit color camera
		if (getBit == 8) setSlice(3);//for original DAPI images acquired with 8-bit color camera
		}
	if (getBit == 24) {//for RGB images 
		run("Split Channels");
		run("Images to Stack", "name=Stack title=[] use");
		setSlice(3);
		}
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
setThreshold(minThresholdDAPI, 255);
//waitForUser("Please check the Thr.");
run("Options...", "iterations=1 count=1 black edm=Overwrite do=Nothing");
run("Find Maxima...", "prominence="+findMaxprominence+" output=[Segmented Particles] above");//check min noise (prominence)
setAutoThreshold("Default dark");
//analyze DAPI
rename(titleOri+" DAPI total cell count");
run("Analyze Particles...", "size=50-Infinity pixel circularity=0.00-1.00 show=Nothing summarize add");
close();
close();
roiManager("Show None");
roiManager("Show All");
roiManager("Combine");
roiManager("Reset");
roiManager("Add");
titleTemp=getTitle();
//waitForUser("Please check the DAPI count and open x-gal image");
selectWindow(title);//close original DAPI image
close();

showProgress(i, list2.length);
    open(dir2+list2[i]);
    titleOri=getTitle();
//_______________________________________________X-Gal_________________________________________________________________________________________________________________________________________________
//segment X-Gal positive cells
//prepare for X-Gal segmentation
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
//segment X-Gal images
run("8-bit");
run("Invert");
run("Subtract Background...", "rolling=50");
run("Gaussian Blur...", "sigma="+gaussRadiusX);
run("Threshold...");
setAutoThreshold("Default dark");
setThreshold(minThreshold, 255);
//waitForUser("Please check the threshold for X-Gal");//If necessary, activate this line (delete //) to stop the macro for each image (slow).
run("Find Maxima...", "noise="+findMaxprominenceX+" output=[Segmented Particles] above");
roiManager("Select", 0);
run("Enlarge...", "enlarge=20 pixel");
setBackgroundColor(0, 0, 0);
run("Clear Outside");
run("Select None");
setAutoThreshold("Default dark");
rename(titleOri+" X-Gal positive cell count");
//analyze X-Gal images
run("Analyze Particles...", "size="+minArea+"-Infinity pixel circularity=0.00-1.00 show=Nothing summarize add");
close();
close();

//display
roiManager("Show None");
roiManager("Show All");
roiManager("Select", 0);
run("Close All");
}

//__________________________________________________Report______________________________________________________________________________________________________________________________________________________________________________________
//_______________________________________________________________________________________________________________________________________________________________________________________________________________________________________________
							
print("\\Clear");
print("");
print("DAPI segmentation and analysis:");
print("The background was subtracted from DAPI images using the Rolling Ball Background Subtraction with radius 30 pxl.");
print("DAPI images were filtered using the Gaussian Blur with the radius set to "+gaussRadius+".");
print("Images were segmented using the Find Maxima tool with the prominence set to "+findMaxprominence+" above threshold "+minThresholdDAPI+".");
print("Minimum analyzed DAPI particle area was set to 50 pxl.");
print("");
print("X-Gal segmentation and analysis:");
print("The background was subtracted from X-Gal images using the Rolling Ball Background Subtraction with radius 50 pxl.");
print("X-Gal images were filtered using the Gaussian Blur with the radius set to "+gaussRadiusX+" pxl.");
print("Images were segmented using the Find Maxima tool with the prominence set to "+findMaxprominenceX+" above threshold "+minThreshold+".");
print("Minimum analyzed X-Gal particle area was set to "+minArea+" pxl.");
print("____________________________________________________________________________________________________________________________________________________________________________________________________"); 														
print("The 'GNU General Public License' applies; http://www.gnu.org/licenses/gpl.html - in short - free to use and modify, no warranty provided.");
															