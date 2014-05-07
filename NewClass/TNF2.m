function [seed] = TNF2(contrastSeq, lumSeq, varargin)
% Simulate small objects and saccades.
% Screen is divided in two, center and periphery.
% Center follows a gaussian sequence and at times given by 'backReverseFreq'
% the sequence in the center jumps to another point with different luminance
% and/or contrast.
% At those same times the center jumps, the periphery might also
% simulate a saccade. 

global screen
    
try
    % process Input variables
    p = ParseInput(varargin{:});
    
    waitframes = p.Results.waitframes;
    seed = p.Results.seed;
    resetFixationSeed = p.Results.resetFixationSeed;
    resetBlockSeed = p.Results.resetBlockSeed;
    checkersSize = p.Results.checkersSize;
    objSize = p.Results.objSize;
    stimSize = p.Results.stimSize;

    fixationLength = p.Results.fixationLength;
    blocksN = p.Results.blocksN; 
    repeatsPerBlock = p.Results.repeatsPerBlock;
    
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
    peripheryDest = CenterRect(peripheryDest, screen.rect-checkersSize/2*[1 1 1 1]);

    peripherySource = SetRect(0,0,checkersN, checkersN);
    
    % change fixationLength into frames and force it to be an even number.
    framesPerFixation = round(fixationLength*screen.rate/waitframes/2)*2;
    
    % make framesN an integer number of framesPerFixation
    saccadesN = length(lumSeq);
    
    % make sure that blocksN is even to get equal number of conditions with
    % peripheral phase A and B
    blocksN = 2*ceil(blocksN/2);
            
    % make sure that maximum mean and contrast are whithin monitor range
    if (max(lumSeq)*(1+3*max(contrastSeq))>260)
        error('monitor saturate with current max luminance and contrast')
    end
    
    % Define the PD box
    pd = DefinePD();
    

    Screen('FillRect', screen.w, screen.gray);

    phase1 = 0;        % used to produce saccades
    phase2 = 0;        % used to change peripheral phase in between blocks
    
    Screen('TextSize', screen.w, 12);
    
    label{3} = '';  % init the cell array to prevent worning message
    
    % Get a random stream to draw luminances from
    S1 = RandStream('mcg16807', 'Seed',seed);
    S1 = {S1, S1};  % one random stream per periMode (obj/saccading)
    
    for block = 1:blocksN
        label{1} = ['blockN: ',num2str(block), '/', num2str(blocksN)];
        for periMode=0:1
            % The following line guarantees that both periMode will have
            % the same phase2 but different than in the previous block
            if (periMode==0)
                phase2 = mod(phase2+1,2);
                phase1 = 0;
            end
            
            RS = S1{periMode+1}; % RS points to one of the two previously 
                                         % created streams, it is not a
                                         % third one. Any operation on
                                         % RS affects the state of
                                         % the linked S1{periMode} as well
            if resetBlockSeed
                RS.reset
            end
            
            for repeat = 1:repeatsPerBlock
                label{2} = ['repeat: ',num2str(repeat), '/', num2str(repeatsPerBlock)];
                for saccade=1:saccadesN
                    if (resetFixationSeed)
                        RS.reset
                    end
                    label{3} = ['SaccadeN: ',num2str(saccade), '/', num2str(saccadesN)];
                    label{4} = ['mean: ', num2str(lumSeq(saccade))];
                    label{5} = ['contrast: ', num2str(contrastSeq(saccade))];

                    if (periMode)
                        % saccading, change peripheral phase
                        phase1 = mod(phase1+1,2);
                    end
                    
                    if (saccade==1)
                        pdMode=1;
                    else
                        pdMode=0;
                    end
                    
                    lum = lumSeq(saccade);
                    cont = contrastSeq(saccade);
                    
                    luminanceSeq = lum + lum*cont*randn(RS, 1, framesPerFixation);
                    showOneSaccade(phase1+phase2, peripheryDest, peripherySource, objRect, luminanceSeq, pdMode, pd, checkerTexture{1}, waitframes, label)
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
        if KbCheck
            break
        end
    end
        
    seed = RS.State;
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

function showOneSaccade(phase, peripheryDest, peripherySource, objRect, lumSeq, pdMode, pd, tex, waitframes, label)
    global screen
    
    if (mod(phase,2))
        peripherySource = peripherySource + [1 0 1 0];
    end
    
    for frame=1:length(lumSeq)
        % write some numbers onto the screen
        DrawMultiLineComment(screen, label);

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
    p.addParamValue('seed', 1, @(x) isnumeric(x) );
    p.addParamValue('blocksN', 2);
    p.addParamValue('repeatsPerBlock', 25, @(x) x>=0);
    % Background related
    p.addParamValue('fixationLength', 1, @(x) x>=0);
    p.addParamValue('resetFixationSeed', 0, @(x) x==0 || x==1);
    p.addParamValue('resetBlockSeed', 0, @(x) x==0 || x==1);
    
    % General
    p.addParamValue('stimSize', screenY, @(x)x>0);
    p.addParamValue('checkersSize', PIXELS_PER_100_MICRONS/2, @(x)x>0);
    p.addParamValue('waitframes', round(rate/30), @(x)isnumeric(x));         

    % Call the parse method of the object to read and validate each argument in the schema:
    p.parse(varargin{:});
    
end
