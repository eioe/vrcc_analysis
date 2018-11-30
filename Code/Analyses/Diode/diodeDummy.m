

sca;
close all;
clearvars;

pport = parallel_port_setup();

PsychDefaultSetup(2);

screens = Screen('Screens');
screenNumber = max(screens);

white = WhiteIndex(screenNumber);
black = BlackIndex(screenNumber);

grey = white / 2;

[window, windowRect] = PsychImaging('OpenWindow', screenNumber, grey);
[screenXpixels, screenYpixels] = Screen('WindowSize', window);

ifi = Screen('GetFlipInterval', window);
hertz = FrameRate(window);

baseRect = [screenXpixels-100 screenYpixels-100 screenXpixels screenYpixels];

rectColor = black;
Screen('FillRect', window, rectColor, baseRect);

Screen('Flip', window);

mrkr.col.white = white;
mrkr.col.black = black;
mrkr.window = window;
mrkr.rect = baseRect;
mrkr.name = 10;
mrkr.portadr = pport;
mrkr.hertz = hertz;
mrkr.ifi = ifi;

% create vector of delays (in s):
% 30 x 0
% 30 x 0.1
% 30 x -0.1
% 30 x 0.02
% 30 x -0.02
% 30 x random from intervall [-0.2; 0.2]
% 30 x random from intervall [-0.02; 0.02]

delays = [zeros(1,30); repmat(0.1,1,30); repmat(-0.1,1,30); ... 
          repmat(0.02,1,30); repmat(-0.02,1,30); 0.400*rand(1,30)-0.2; ... 
          0.040*rand(1,30)-0.02];
% to loop by row:
delays = delays.';
      
WaitSecs(1)

for run =1:numel(delays)
    WaitSecs(1);   
    mrkr.screendelay = delays(run);
    mrkr.name = ceil(run/(numel(delays)/size(delays,2)));
    send_dbl_mrkr_fuckup(mrkr);
end


sca