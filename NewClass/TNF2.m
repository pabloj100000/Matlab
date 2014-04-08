function [seed] = TNF2(varargin)
% Simulate objects undergoing FEM and saccades.
% Screen is divided in two, center and periphery.
% Center follows a pink sequence and at times given by 'backReverseFreq'
% the sequence in the center jumps to another point in the pink noise
% sequence. At those same times the center jumps, the periphery might also
% simulate a saccade or not. 

global screen
    
try
    % process Input variables
    p = ParseInput(varargin{:});
    
    waitframes = p.Results.waitframes;
    seed = p.Results.seed;
    presentationLength = p.Results.presentationLength;
    checkersSize = p.Results.checkersSize;
    saccadeLength = p.Results.saccadeLength;
    stimSize = p.Results.stimSize;
    trialsN = p.Results.trialsN;        
    objSize = p.Results.objSize;
    
    % start the stimulus
    InitScreen(0)
    Add2StimLogList();

    % Get the stimSzie be an integer number of checkers
    stimSize = floor(stimSize/checkersSize)*checkersSize;
    
    % get the background texture
    checkersN = floor(stimSize/checkersSize);         % make two checkers bigger than what will be seen
    checkerTexture = GetCheckersTex(checkersN+2, 1);

    objRect = SetRect(0, 0, objSize, objSize);
    objRect = CenterRect(objRect, screen.rect);

    
    peripheryDest = SetRect(0,0,stimSize, stimSize);
    peripheryDest = CenterRect(peripheryDest, screen.rect);

    peripherySource = SetRect(0,0,checkersN, checkersN);

    % change presentationLength into framesN
    framesN = round(presentationLength*screen.rate/waitframes);

    
    % change saccadeLength into frames and force it to be an even number.
    framesPerSaccade = round(saccadeLength*screen.rate/waitframes/2)*2;
    
    % make framesN an integer number of framesPerSaccade
    saccadesN = round(framesN/framesPerSaccade);
%    framesN = saccadesN*framesPerSaccade;
    
    % make sure that trialsN is even to get equal number of conditions with
    % peripheral phase A and B
    trialsN = 2*ceil(trialsN/2);
    
    % Define the object order sequence. 
    S1 = RandStream('mcg16807', 'Seed',seed);
    meanSeq = 127 + 127*.1*randn(S1, saccadesN, 1);%randperm(S1, saccadesN);
    maxContrast = 1/3*(255./meanSeq - 1);
    contrastSeq = gamrnd(2, maxContrast/10, size(meanSeq));%rand(S1, size(meanSeq)).*maxContrast;%GetPinkNoise(1, framesN, objContrast, screen.gray, 0);

    % Define the PD box
    pd = DefinePD();
    

    Screen('FillRect', screen.w, screen.gray);

    phase1 = 0;        % used to produce saccades
    phase2 = 0;        % used to have consecutive repeats of the same stim with different peripheral phases

    for trial = 0:trialsN-1
        for periMode=0:1
            % The following line guarantees that both periMode will have
            % the same phase2 but different than in the previous trial
            if (periMode==0)
                phase2 = mod(phase2+1,2);
                phase1 = 0;
            end
            
            for saccade=1:saccadesN
                if (periMode)
                    % saccading, change peripheral phase
                    phase1 = mod(phase1+1,2);
                end
                
                if (saccade==1)
                    pdMode=1;
                else
                    pdMode=0;
                end
                
%                [saccade contrastSeq(saccade) meanSeq(saccade)]
                lumSeq = GetPinknoise(framesPerSaccade*saccade+1, framesPerSaccade, contrastSeq(saccade), meanSeq(saccade), 0);
                
                showOneSaccade(phase1+phase2, peripheryDest, peripherySource, objRect, lumSeq, pdMode, pd, checkerTexture{1}, waitframes)
                if KbCheck
                    break
                end
            end
            if KbCheck
                break
            end
        end
        if KbCheck
            break
        end
    end
        
    seed = S1.State;
%}
    % After drawing, we have to discard the noise checkTexture.
    Screen('Close', checkerTexture{1});

    FinishExperiment();
        
catch exception
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.
    CleanAfterError();
    rethrow(exception)
end %try..catch..
end

function showOneSaccade(phase, peripheryDest, peripherySource, objRect, lumSeq, pdMode, pd, tex, waitframes)
    global screen
    
    if (mod(phase,2))
        peripherySource = peripherySource + [1 0 1 0];
    end
    
    for frame=1:length(lumSeq)
    
        Screen('DrawTexture', screen.w, tex, peripherySource, peripheryDest, 0,0);
    
        color = lumSeq(frame);
        Screen('FillRect', screen.w, color , objRect);
    
        % Draw PD
        if (pdMode && frame==1)
            pdColor = 255;
        else
            pdColor = color/2;
        end
    
        Screen('FillOval', screen.w, pdColor, pd);
        % Flip 'waitframes' monitor refresh intervals after last redraw.
        screen.vbl = Screen('Flip', screen.w, screen.vbl + (waitframes - 0.5) * screen.ifi);
        if KbCheck
            break
        end
    end
end

function p = ParseInput(varargin)
    p  = inputParser;   % Create an instance of the inputParser class.

    [~, screenY] = Screen('WindowSize', max(Screen('Screens')));
    rate = Screen('NominalFrameRate', max(Screen('Screens')));
    if (rate==0)
        rate=100;
    end
    
    % Object related
    p.addParamValue('objSize', 12*PIXELS_PER_100_MICRONS, @(x) x>=0);

    % Background related
    p.addParamValue('seed', 1, @(x) isnumeric(x) );
    p.addParamValue('backContrast', 1, @(x)x>=0 && x<=1);
    p.addParamValue('saccadeLength', 1, @(x) x>=0);
    p.addParamValue('backTexture', [], @(x) iscell(x));
    p.addParamValue('peripheryStep', 1, @(x) x>=0 && x<=PIXELS_PER_100_MICRONS);

    % General
    p.addParamValue('stimSize', screenY, @(x)x>0);
    p.addParamValue('presentationLength', 100, @(x)x>0);
    p.addParamValue('trialsN', 50);
    p.addParamValue('checkersSize', PIXELS_PER_100_MICRONS, @(x)x>0);
    p.addParamValue('waitframes', round(rate/30), @(x)isnumeric(x));         

    % Call the parse method of the object to read and validate each argument in the schema:
    p.parse(varargin{:});
    
end
