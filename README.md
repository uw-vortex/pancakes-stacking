# Pancakes Stacking Program
Pancakes is an application to extract end-diastolic frames from ultrasound images for the purpose of ECG-gated arterial diameter analysis. Pancakes searches for peaks of the QRS complex, pulls frames from the video, and recomplies them into one 'stacked' DICOM file for import into automated edge-tracking software.

Pancakes is currently compatible with GE B-Mode and Duplex mode images (.avi or .dcm) with a visible ECG trace on the screen, but is easily modifiable to suit different types of images. 

## How to download and run
1. You will need to download the MATLAB Runtime application to make this program work. Navigate to the [MATLAB Download website](http://www.mathworks.com/products/compiler/mcr/index.html) and download the 32-bit R2015b version and install on your computer. If you are running the Macintosh version, you will need the Mac-specific 2015b version. Please note that the Catalina OS has quite a number of download restrictions and you may need to by-pass the 'identified developers' firewall in order to download the MCR installer. Please see [this guide](https://www.geekrar.com/how-to-allow-third-party-apps-install-on-macos-catalina/) for assistance.
2. Copy the contents of this folder to your computer.
3. Run pancakes.exe (or pancakes.app) and you should see the splash icon cross your screen, and the first file selection option coded into the program (i.e., 'Are you analyzing one or multiple files?').

## Feedback
Feedback, additions, and improvements are always welcome! If you are not equipped to contribute to this project via Issues or Pull Requests, feel free to reach out to me at jason.au@uwaterloo.ca and we can help you get this set up for your individual needs.

This is intended to be an open source program under a GNU General Purpose License, and therefore you are free to use source code with appropriate reference to the creator and original license.
