function pix=relative2pix_Lukas2(relative)

pixvals=0:10:220;

lumvals=[4.0 5.7 8.2 10.6 13.8 18.4 25.0 33.7 43.9 56.2 67.9 80.0 91.1 103.5 118.0 132.6 149.9 172.8 190.9 204.7 217.9 231.7 238.1];

%calibration done using thorlabs powermeter set to 550nm  on 12/3/24
%maximum contrast at pixel value 100 (relative luminance ~0.3) is 0.94. 
%maximum contrast at pixel value 70 (relative luminance ~0.1515) is 0.88

lum=max(lumvals)*relative; %convert relative values to luminance values

if min(lum(:))<2.4
    display('MINIMUM requested relative value cannot be displayed on the screen (pixel value 0 too bright)!');
    lum(lum<2.4)=2.4;
end

pix=interp1(lumvals,pixvals,lum);