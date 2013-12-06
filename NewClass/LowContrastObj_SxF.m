function LowContrastObj_SxF(varargin)
   global vbl screen backRect backSource objRect objSource pd
 


    p=ParseInput(varargin{:});

    objContrast = p.Results.objContrast;
    objSeed  = p.Results.objSeed;
    debugging = p.Results.debugging;
    objJitterPeriod = p.Results.objJitterPeriod;
    objSizeH = p.Results.objSizeH;
    objSizeV = p.Results.objSizeV;
    objCenterXY = p.Results.objCenterXY;
    presentationLength = p.Results.presentationLength;
    movieDurationSecs = p.Results.movieDurationSecs;
    stimSize = p.Results.stimSize;
    barsWidth = p.Results.barsWidth;
    backContrast = p.Results.backContrast;
    waitframes = p.Results.waitframes;
    pdStim = p.Results.pdStim;

    if isempty(vbl)
        vbl=0;
    end

    backSeqN = 2;       % there are only two backgrounds, the random one and a still one.

% 
% Wrapper to call JitteringBackTex_UniformFieldObj
%
% Divide the screen in object and background.
% Both object and back will be a grating of a given spatial frequency.
% obj will have a low contrast and back will have a higer one.
% Either back and object follow the same random jitter
% or object alone jitters and back stays still.
% The 'randomly' jittering sequences are compossed of -1, 0, 1 pixel jumps
% per frame with equal probability
% The experiment is divided in presentations. Each presentation is defined
% by the length of the presentation, the background sequence and the object
% sequence. Background and object sequences have independent durations.
% If the presentation lasts longer than either background or object sequence
% then they start over.
% In this way I can:
%   1) make repeats of a given object and background.
%   2) make repeats of a given background with several different objects.
%   3) make repeats of a given object with several different background.
%   4) make repeats where the object and background get out of phase.


% Redefine exp time to have an even number of jitters
movieDurationSecs = backSeqN*presentationLength* ...
    floor(movieDurationSecs/(backSeqN*presentationLength));

try
    InitScreen(0);
    Add2StimLogList();
    
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
    if exist('pd', 'var')==0 || isempty(pd)
        pd = DefinePD();
    end
    
    framesPerSec = screen.rate;
    objJumpsPerPeriod = round(objJitterPeriod*framesPerSec);

    
    % make the backSeqN random sequences
    stillSeq = zeros(1, objJumpsPerPeriod);
    
    % We run at most 'consPresentationsN' if user doesn't abort via
    % keypress.
    presentationsN = uint32(movieDurationSecs/presentationLength);

    % Define some needed variables
    framesN = uint32(presentationLength*screen.rate);
    rand('seed', objSeed);
    
    % Animationloop:
    for presentation = 1:presentationsN
        % get the random sequence of jumps for the object
        objSeq = floor(rand(1, objJumpsPerPeriod)*3)-1;

        if (mod(presentation, 2))
            % Global Motion
            backSeq = objSeq;
            rand('seed', objSeed);
        else            
            % Differential Motion
            backSeq = stillSeq;
           objSeed = rand('seed');
        end

        JitterBackTex_JitterObjTex(backSeq, objSeq, ...
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
    
        FinishExperiment();
    
catch
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.
    CleanAfterError();
    psychrethrow(psychlasterror);
end %try..catch..
end

