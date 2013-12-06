function run050511()
global pdStim screen

% Record for 400 + 1000 + 100 + 500 + 500 * 2 secs = 3000
% Record for 3 hours
try

    Wait2Start()
    
    % Define the rectangles
    objRect = GetRects(192, screen.center);



    %%%%%%%%%%%%%%%%%%%%%%% information experiment %%%%%%%%%%%%%%%%%%%%%%%%
    pause(.2)
    pdStim = 1;
    ContrastPhaseInformation(...
        'backContrast', 1, ...
        'objContrasts', [.03 .06 .12 .24 .35], ...
        'objCheckerSize', 192, ...
        'objFreq', 10, ...                 
        'stimSize', 512, ...
        'presentationLength', 11, ...
        'movieDurationSecs', 3600*3, ...
        'objRect', objRect ...
        );

    FinishExperiment();

catch 
    FinishExperiment();
    psychrethrow(psychlasterror);
end %try..catch..
end

function objSeed = ContrastPhaseInformation(varargin)
%   obj and background will both be either bars or checkers of a given
%   size. The phase and contrast will change over some values.
% 
% Divide the screen in object and background.
% Object will be a given texture changing phases every so often.
% Back will be a grating of a giving contrast and spatial frequency
% that reverses periodically at backReverseFreq.
global vbl screen pd pdStim

if isempty(vbl)
    vbl=0;
end
if isempty(pdStim)
    pdStim=0;
end

p=ParseInput(varargin{:});

% object
objSeed = p.Results.objSeed;
objContrasts = p.Results.objContrasts;
objRect = p.Results.objRect;
objCheckerSize = p.Results.objCheckerSize;
objFreq = p.Results.objFreq;

% background
backContrast = p.Results.backContrast;
backReverseFreq = p.Results.backReverseFreq;
backCheckerSize = p.Results.backCheckerSize;

% general
stimSize = p.Results.stimSize;
debugging = p.Results.debugging;
movieDurationSecs = p.Results.movieDurationSecs;
presentationLength = p.Results.presentationLength;

try
    InitScreen(debugging);

    % each presentation will have all possible contrasts.
    framesPerSec = 60;
    contrastsN = length(objContrasts);
    presentationsN = movieDurationSecs/presentationLength/contrastsN;

    % Init all random streams
    randomPhaseStream = RandStream('mcg16807', 'Seed', objSeed);
    randomContrastStream = RandStream('mcg16807', 'Seed', objSeed);
        
    % make the background texture, each checker takes only 1 pixel
    backCheckersN = round(stimSize/backCheckerSize);
    backTex = GetCheckersTex(backCheckersN+1, 1, screen, backContrast);
    backSourceOri = [0 0 backCheckersN backCheckersN];
    backRect=GetRects(stimSize, screen.center);
    
    % make the object texture, each checker is one pixel
    objCheckersN = (objRect(3)-objRect(1))/objCheckerSize;
    objTex = GetCheckersTex(objCheckersN+1, 1, screen, 1);
    objSourceOri = [0 0 objCheckersN objCheckersN];
        
    % Define the PD box
    pd = SetRect(0,0, 100, 100);
    pd = CenterRectOnPoint(pd, screen.rect(3)*.95, screen.rect(4)*.15);
    
    % make the saccade sequence
    framesN = presentationLength*framesPerSec;
    backFramesPeriod = round(framesPerSec/backReverseFreq/2);
    objFramePeriod = round(framesPerSec/objFreq);

    for presentation=1:presentationsN

        contrastSeq = randperm(randomContrastStream, contrastsN);
        phaseSeq = randi(randomPhaseStream, 2, 1, framesN/objFramePeriod)-1;

if (~exist('allContrastSeq'))
    Screen 'CloseAll';
    allContrastSeq = zeros(1,contrastsN*presentationsN);
    allPhaseSeq = zeros(1, framesN/objFramePeriod);
end
allContrastSeq(1,(presentation-1)*contrastsN+1: presentation*contrastsN) = contrastSeq;
allPhaseSeq((presentation-1)*framesN/objFramePeriod+1: presentation*framesN/objFramePeriod)=phaseSeq;
%}
%{
        for i = 1:contrastsN
            phaseIndex = 1;
            backIndex = 0;
            for frame=0:framesN-1
                % is it time to reverse the background?
                if (mod(frame, backFramesPeriod)==0)
                    backSource = backSourceOri+backIndex*[1 0 1 0];
                    backIndex = mod(backIndex+1,2);
                end
                
                % is it time to change the phase of the center?
                if (mod(frame, objFramePeriod)==0)
                    objSource = objSourceOri + phaseSeq(phaseIndex)*[1 0 1 0];
                    phaseIndex = phaseIndex+1;
                end
 
                Screen('FillRect', screen.w, screen.gray);
                
                % display background texture
                Screen('DrawTexture', screen.w, backTex{1},backSource,backRect, 0, 0);
                
                % Draw object
                Screen('FillRect', screen.w, screen.gray, objRect);
                Screen('DrawTexture', screen.w, objTex{1}, objSource, objRect, [], 0, objContrasts(contrastSeq(i)));
                
                % Restore alpha blending mode for next draw iteration:
                Screen('Blendfunction', screen.w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
                
                % Photodiode box
                % --------------
                DisplayStimInPD2(pdStim, pd, frame, 60, screen)
                
                Screen('Flip', screen.w);
                if (KbCheck)
                    break
                end
            end

            if (KbCheck)
                break
            end
        end
%}
        if (KbCheck)
            break
        end

    end
    
    % After drawing, we have to discard the noise checkTexture.
    Screen('Close', backTex{1});
    Screen('Close', objTex{1});

    
catch
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.
    FinishExperiment();
    psychrethrow(psychlasterror);
end %try..catch..
end

function p =  ParseInput(varargin)
    % Generates a structure with all the parameters
    % Allowed parameters are:
    %
    % objContrast, objJitterPeriod, objSeed, stimSize, objSizeH, objSizeV,
    % objCenterXY, backContrast, backJitterPeriod, presentationLength,
    % movieDurationSecs, pdStim, debugging, barsWidth, waitframes, vbl

    % In order to get a parameter back just use
    %   p.Resulst.parameter
    % In order to display all the parameters use
    %   disp 'List of all arguments:'
    %   disp(p.Results)
    %
    % General format to add inputs is...
    % p.addRequired('script', @ischar);
    % p.addOptional('format', 'html', ...
    %     @(x)any(strcmpi(x,{'html','ppt','xml','latex'})));
    % p.addParamValue('outputDir', pwd, @ischar);
    % p.addParamValue('maxHeight', [], @(x)x>0 && mod(x,1)==0);

    p  = inputParser;   % Create an instance of the inputParser class.

    
    % General
    p.addParamValue('stimSize', 16*32, @(x)x>0);
    p.addParamValue('presentationLength', 10, @(x)x>0);
    p.addParamValue('movieDurationSecs', 1600, @(x)x>0);
    p.addParamValue('debugging', 0, @(x)x>=0 && x <=1);
    p.addParamValue('waitframes', 1, @(x)isnumeric(x)); 
    p.addParamValue('vbl', 0, @(x)x>0);

    % Object related
    p.addParamValue('objSeed', 1, @(x) isnumeric(x));
    p.addParamValue('objContrasts', [.12 1], @(x) all(all(x>=0)) && all(all(x<=1)));
    p.addParamValue('objTexture', [], @(x) iscell(x));
    p.addParamValue('objRect', [0 0 192 192], @(x) size(x,2)==4);
    p.addParamValue('objFreq', 10, @(x) x>0);
    p.addParamValue('objCheckerSize', 8, @(x) x>0);
    p.addParamValue('phaseSeq', [], @(x) isnumeric(x));
    
    % Background related
    p.addParamValue('backContrast', 1, @(x)x>=0 && x<=1);
    p.addParamValue('backReverseFreq', 1, @(x) x>0);
    p.addParamValue('backTexture', [], @(x) iscell(x));
    [screenX, screenY] = Screen('WindowSize', max(Screen('Screens')));
    p.addParamValue('backRect', GetRects(768, [screenX screenY]/2), @(x) isnumeric(x) && size(x,2)==4);
    p.addParamValue('backCheckerSize', 16, @(x) x>0);
    
    
    % Call the parse method of the object to read and validate each argument in the schema:
    p.parse(varargin{:});
    
end
