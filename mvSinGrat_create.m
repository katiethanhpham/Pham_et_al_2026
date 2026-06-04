function stimulus=mvSinGrat_create(ori,tf,sf,duration,screendist)
%function stimulus=mvSinGrat_create_Lee(ori,frq,cpd,duration)
%creates moving sinusoidal grating in relative luminance values (0 to 1)
%ori: grating orientation in degrees; This is actually direction of
%movement so 90 is a horizontal grating moving upward
%tf: temporal frequency in Hz
%sf: spatial frequency in cycles per degree
%duration: duration in seconds
%screendist: distance from mouse to the middle of the screen. 
%Lukas 6/9/24

FR=Screen('NominalFrameRate',0);   %nominal frame rate in Hz
[Winwidth, Winheight]=Screen('WindowSize', 0); %in pixel
[Dispwidth, Dispheight]=Screen('DisplaySize', 0); % in mm


pix_per_mm=Winwidth/Dispwidth;


[X,Y]=meshgrid(1:Winwidth,Winheight:-1:1); % X and Y pixel coordinates. Y is 'reversed' to start at the bottom of the screen 
D=cosd(ori)*X+sind(ori)*Y; %projection of X and Y onto [cosd(ori); sind(ori)], i.e. the distance in pixels along the vector defined by ori

degrees_cycle=1/sf; %degrees per cycle. Easier to work with
mm_cycle=2*tand(degrees_cycle/2)*screendist; %mm per cycle
pix_cycle=mm_cycle*pix_per_mm; %pixels per cycle

TH=2*pi*D/pix_cycle; %starting phase of the sinusoidal grating (THeta);

theta_per_frame=2*pi*tf/FR; %the change is 2*pi*tf degrees per 1s which is FR frames

Nframes=round(duration*FR);

stimulus=zeros(Winheight,Winwidth,Nframes);
for fri=1:Nframes
    stimulus(:,:,fri)=sin(TH-theta_per_frame*fri);
end

stimulus=(stimulus+1)/2; %rescale from [-1 1] to [0 1]
    




