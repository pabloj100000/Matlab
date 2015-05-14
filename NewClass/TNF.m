function Mouse_EM(varargin)
% I'll show different combinations of center and peipheries following a
% sequence of eye movements coming from a real mouse. 
% All peripheries are combined with all centers, total number of
% combinations is centersN * peripheriesN (most likely i'll have 4 center
% and 4 peripheries, 2 bits on each, 4 bits total)
% Each combination follows exactly the same eye movement sequence lasting
% in the order of 1 to 10 seconds.
% Every time a spatial stim (a combination of center and peri)
% is shown, it starts from exactly the same phase (same position in the
% screen). The only difference between two given presentations is the
% particular combination of center and periphery.
% The experiment is carried in blocks, each block corresponds to one
% periphery and within each block images are not randomized but shown in
% order. This is so that I can consider a transition between images as just
% another stimulus and I'll have as many transitions from say center_1 to
% center_2 as presentations of center_1 and center_2 (otherwise I'll also
% have transitions from center_1 to center_3/4)
% I will have a mask in between the center and the periphery (could be of
% zero size in which case it will not exist)
% The 4 peripheries will be a gray screen, a checkerboard and two natural
% scenes. There will probably be a large eye movement in the sequence, try
% to make the checkerboard such that it has strong peripheral stimulaiton
% for such an eye movement. Also try to make the checkerboard such that
% when transitioning from center_1 to center_2 it has strong peripheral
% input.

global screen
    
try
    % process Input variables
    p = ParseInput(varargin{:});

    eye_movement_length = p.Results.eye_movement_length;
    eye_movement_file = p.Results.eye_movement_file;
    eye_movement_startT = p.Results.eye_movement_startT;
    
    center_size = p.Results.center_size;
    mask_size = p.Results.mask_size;
    periphery_size = p.Results.periphery_size;
    trials_per_block = p.Results.trials_per_block;
    blocksN = p.Results.blocksN;
    objContrast = p.Results.objContrast;

    % parameters to define center images. First two images will also be
    % used to generate peripheries
    im_centers = p.Results.im_centers;
    
    % not a parameter, load this from the mouse file
    sampling_freq = p.Results.sampling_freq;

    % try to compute checkerSize optimally from the eye movement sequence
    checkersSize = p.Results.checkersSize;

    % start the stimulus
    InitScreen(0)
    Add2StimLogList();

    % get the background texture
    checkersN = floor(stimSize/checkersSize)+2;         % make two checkers bigger than what will be seen
    stimSize = checkersSize * (checkersN);
    [X, Y] = meshgrid(1:checkersN, 1:checkersN);
    Z = mod(X+Y+1,2)*screen.white;
    checkerTexture = Screen('MakeTexture', screen.w, Z);
        
    objRect = SetRect(0, 0, objSize, objSize);
    objRect = CenterRect(objRect, screen.rect);

    backDestOri = SetRect(0,0,stimSize, stimSize);
%    backDestOri = OffsetRect(backDestOri,screen.rect(1)+2*checkersSize,screen.rect(1)+2*checkersSize)  
    backDestOri = CenterRect(backDestOri, screen.rect);
    backDestOri = OffsetRect(backDestOri, -checkersSize, -checkersSize);

    % Define the source rectangle
    peripherySource = SetRect(0,0,checkersN, checkersN);

    peripheryMask = SetRect(0,0,(checkersN-2)*checkersSize, (checkersN-2)*checkersSize);
    peripheryMask = CenterRect(peripheryMask, screen.rect);

    offsetPeriphery = 0;

    framesN = round(presentationLength*screen.rate/waitframes);
    if backReverseFreq==0
        peripheryFrame = framesN;
    else
        peripheryFrame = floor(1/backReverseFreq/2*screen.rate/waitframes);
    end

    % Get a random sequence representing FEM
    S1 = RandStream('mcg16807', 'Seed',seed);

    % Define the PD box
    pd = DefinePD();
    if (pdMode)
        pdFrames = peripheryFrame;
    else
        pdFrames = framesN;
    end
    
%    [pdFrames screen.rate]
    objSeq = GetPinkNoise(1, framesN, objContrast, screen.gray, 0);
    for trial = 0:trialsN-1
        
        for frame=0:framesN-1
            Screen('FillRect', screen.w, screen.gray);
            
            % Offset peripherySource randomly according to back Step
            if (mod(frame, peripheryFrame)==0)
                offsetPeriphery = mod(offsetPeriphery + 1*peripheryStep, 2*peripheryStep);
                peripheryDest = backDestOri + offsetPeriphery*[1 0 1 0];
            end
            
            Screen('DrawTexture', screen.w, checkerTexture, peripherySource, peripheryDest, 0,0);
            
            Screen('FillRect', screen.w, objSeq(frame+1), objRect);
            
            % Draw PD
            if (mod(frame, pdFrames)==0)
                pdColor = 255;
            else
                pdColor = objSeq(frame+1);
            end
            
            Screen('FillOval', screen.w, pdColor, pd);
            % Flip 'waitframes' monitor refresh intervals after last redraw.
            screen.vbl = Screen('Flip', screen.w, screen.vbl + (waitframes - 0.5) * screen.ifi);
            if KbCheck
                break
            end
        end
        if (KbCheck)
            break
        end
    end
        
    seed = S1.State;

    % After drawing, we have to discard the noise checkTexture.
    Screen('Close', checkerTexture);

    FinishExperiment();
        
catch exception
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.
    CleanAfterError();
    rethrow(exception)
end %try..catch..
end



function p = ParseInput(varargin)
    p  = inputParser;   % Create an instance of the inputParser class.

    [~, screenY] = Screen('WindowSize', max(Screen('Screens')));
    rate = Screen('NominalFrameRate', max(Screen('Screens')));
    if (rate==0)
        rate=100;
    end
    
    % Object related
    p.addParamValue('objContrast', .1, @(x) x>=0 && x<=1);
    p.addParamValue('objSize', 12*PIXELS_PER_100_MICRONS, @(x) x>=0);

    % Background related
    p.addParamValue('seed', 1, @(x) isnumeric(x) );
    p.addParamValue('backContrast', 1, @(x)x>=0 && x<=1);
    p.addParamValue('backReverseFreq', 1, @(x) x>=0);
    p.addParamValue('backTexture', [], @(x) iscell(x));
    p.addParamValue('peripheryStep', 1, @(x) x>=0 && x<=PIXELS_PER_100_MICRONS);

    % General
    p.addParamValue('stimSize', screenY, @(x)x>0);
    p.addParamValue('presentationLength', 200, @(x)x>0);
    p.addParamValue('trialsN', 5);
    p.addParamValue('checkersSize', PIXELS_PER_100_MICRONS, @(x)x>0);
    p.addParamValue('waitframes', round(rate/30), @(x)isnumeric(x));         
    p.addParamValue('repeatCenter', 1, @(x) isnumeric(x));         
    p.addParamValue('pdMode', 0, @(x) x==0 || x==1);         

    % Call the parse method of the object to read and validate each argument in the schema:
    p.parse(varargin{:});
    
end
