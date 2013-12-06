function FixedObjPhases_SSx(varargin)
%   Stimulus is divided in object and background. Each one with its own
%   contrast. Spatialy, both are going to be gratings of a given barsWidth.
%   Temporally, background can either be still or reversing at
%   backReverseFreq. The object will be changing between 4 different phases
%   at backReverseFreq. All possible combinations of 4 phases are
%   considering giving a total of 16 different jumps. There is nothing
%   random in this experiment.

   global vbl screen backRect backSource objRect objSource pd
 


    p=ParseInput(varargin{:});

    objContrast = p.Results.objContrast;
    debugging = p.Results.debugging;
    objSizeH = p.Results.objSizeH;
    objSizeV = p.Results.objSizeV;
    objCenterXY = p.Results.objCenterXY;
    backReverseFreq = p.Results.backReverseFreq;
    stimSize = p.Results.stimSize;
    barsWidth = p.Results.barsWidth;
    backContrast = p.Results.backContrast;
    waitframes = p.Results.waitframes;
    
    CreateStimuliLogStart()
    if isempty(vbl)
        vbl=0;
    end

    phasesN = 4;
    oneSecStimN = (phasesN^2)/2;
    presentationLength = 1/backReverseFreq;
    repeats = 11;
    globalRepeats = 4;
    movieDurationSecs = globalRepeats*repeats*presentationLength*oneSecStimN;
try
    InitScreen(debugging);
    
    % Redefine stimSize to have an integer number of bars
    stimSize = ceil(stimSize/barsWidth)*barsWidth;

    % make the background texture
    x= 1:2*stimSize;
    bars = ceil(mod(floor(x/barsWidth),2)*2*screen.gray*backContrast...
        + screen.gray*(1-backContrast));
    backTex = Screen('MakeTexture', screen.w, bars);
    
    % make the object texture
    x= 1:2*objSizeH;
    bars = ceil(mod(floor(x/barsWidth),2)*2*screen.gray*objContrast...
        + screen.gray*(1-objContrast));
    objTex = Screen('MakeTexture', screen.w, bars);

    % Define the background Destination Rectangle
    backRect = SetRect(0,0,stimSize, stimSize);
    backRect = CenterRect(backRect, screen.rect);
    
    % Define the obj Destination Rectangle
    objRect = SetRect(0, 0, objSizeH, objSizeV);
    objRect = CenterRect(objRect, screen.rect);
    objRect = OffsetRect(objRect, objCenterXY(1), objCenterXY(2));

    % Define the source rectangles
    backSource = SetRect(stimSize/2,0,3/2*stimSize,1);
    objSource = SetRect(objSizeH/2, 0,3/2*objSizeH,1);
    backSourceOri = backSource;
    objSourceOri = objSource;

    % Define the PD box
    pd = SetRect(0,0, 100, 100);
    pd = CenterRectOnPoint(pd, screen.rect(3)*.95, screen.rect(4)*.15);
    
    framesPerSec = 60/waitframes;
    objSeqFramesN = presentationLength*framesPerSec;
    
    % make the back sequences (one still, one saccade like)
    backSeq(1,:) = zeros(1, objSeqFramesN);
    jumpingFrames = 1:objSeqFramesN/2:objSeqFramesN;
    backSeq(2,jumpingFrames) = barsWidth/2;

    % make the object sequence of jumps. Jumps are separeted every
    % saccadeFrames.
    %phaseSequence = [0 1 1 2 3 0 0 2 1 0 3 3 1 3 2 2];
    allObjSeq = zeros(8, objSeqFramesN);
    allObjSeq(:,jumpingFrames) = [2 1; 0 1; 1 1; 0 2; -1 -1; -1 0; 2 2; -1 0]*barsWidth/2;
%    objJumpsSeq=[2 1 0 1 1 1 0 2 -1 -1 -1 0 2 2 -1 0]*barsWidth/2;

    % We run at most 'consPresentationsN' if user doesn't abort via
    % keypress.
    presentationsN = movieDurationSecs/presentationLength;

    % Define some needed variables
    

    framesN = presentationLength*60;
    
    % Animationloop:
    for presentation = 0:presentationsN-1
        background = mod(floor(presentation/oneSecStimN/repeats), 2)+1;
        objSeq = allObjSeq(mod(presentation, oneSecStimN)+1, :);
        
        JitterBackTex_JitterObjTex(backSeq(background,:), objSeq, ...
            waitframes, framesN, backTex, objTex);

        % Previous function DID modify backSource. Recenter it to prevent
        % too much sliding of the texture.
        % Is not perfect and sliding will still take place but will be
        % slower and hopefully will be ok
        backSource = mod(backSource, 2*barsWidth)+backSourceOri.*[1 0 1 0];
        objSource = mod(objSource, 2*barsWidth)+objSourceOri.*[1 0 1 0];

        if (KbCheck)
            break
        end
    end
    
    if (~debugging)
        CreateStimuliLogWrite(p);
    end

catch
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.
    FinishExperiment();
    psychrethrow(psychlasterror);
end %try..catch..
end

