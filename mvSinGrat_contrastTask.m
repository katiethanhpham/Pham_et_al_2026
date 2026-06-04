function stimulus=mvSinGrat_contrastTask(tf,sf,contrast,meanrel,duration,screendist)
%function stimulus=mvSinGrat_contrastTask(tf,sf,contrast,meanrel,duration,screendist)
%creates moving sinusoidal grating in relative luminance values (0 to 1)
%ori: grating orientation in degrees; This is actually direction of
%movement so 90 is a horizontal grating moving upward
%tf: temporal frequency in Hz
%sf: spatial frequency in cycles per degree
%duration: duration in seconds
%screendist: distance from mouse to the middle of the screen (in mm). 
%Lukas 6/9/24

stim=mvSinGrat_create(270,tf,sf,duration,screendist);
stim=(stim-0.5)*2; %sinusoidal moving grating scaled from -1 to 1
    %now it needs to be converted to pixel values at correct contrast


%I want the relative luminance of the stimulus to be scaled from meanrel-d
%to meanrel+d. The contrast is d/meanrel so d=contrast*meanrel
d=contrast*meanrel;

stim_relativeLuminance=meanrel+d*stim;

stim_pix=relative2pix_Lukas(stim_relativeLuminance);
%This is the stimulus in the pixel values. For high contrast stimuli this
%would work reasonably well. However, for low contrast stimuli the entire
%range of the pixel values might be very small- for instance at 0.15
%meanrel 0.04 contrast I get values ranging from ~68 to ~71. If you convert
%these to uint8 the stimulus becomes very blocky, using only 4 pixel values

%To make it closer to a properly sinusoidal even for low contrasts (and low
%luminances), I downsample the stimulus by 3 along both dimensions, and
%then convert each pixel into a 3x3 pixel within which these fractional pixel
%values (that would otherwise get rounded) can be more accurately represented through a mixter of uint8 values. 


DS=stim_pix(1:3:end,1:3:end,:); %downsampled stimulus

stim=[];
for fri=1:size(DS,3) %10 frames take about 1.25s-pretty inefficient code- so it's going to be best to premake all stimuli 
    stim(:,:,fri)=my9xim(DS(:,:,fri));
end

stimulus=stim;






