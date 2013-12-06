
function run102210_b()

global pdStim;

Wait2Start()

% 900 * 9 = 8100

objContrast = [3 6 12 24]/100;
pdStim = 0;

for i=1:4

    pdStim=i;

    NaturalStim2_xSF(...
        'objSeed', 1, ...
        'backSeed', 2, ...
        'objSizeH', 192, ...
        'objSizeV', 192, ...
        'presentationLength', 1, ...
        'barsWidth', 8, ...
        'objContrast', objContrast(i), ...
        'backContrast', 1 ...
        )

end

end

function NaturalStim2_xSF(varargin)

    global vbl screen backRect backSource objRect pd pdStim
    if isempty(vbl)
        vbl=0;
    end
    if isempty(pdStim)
        pdStim=1;
    end

    p=ParseInput(varargin{:});

    debugging = p.Results.debugging;
    presentationLength = p.Results.presentationLength;
    movieDurationSecs = p.Results.movieDurationSecs;
    stimSize = p.Results.stimSize;
    objSeed = p.Results.objSeed;
    objSizeH = p.Results.objSizeH;      % Here obj Size and Center define
    objSizeV = p.Results.objSizeV;      % a rectangle and in each corner of the rectangle
    objCenterXY = p.Results.objCenterXY;    % the 4 flys will be positioned, each one
    objContrast = p.Results.objContrast;
    barsWidth = p.Results.barsWidth;
    backContrast = p.Results.backContrast;
    backSeed = p.Results.backSeed;
    waitframes = p.Results.waitframes;


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
movieDurationSecs = presentationLength* ...
    floor(movieDurationSecs/(presentationLength));

try
    InitScreen(debugging);
    
    % Redefine stimSize to have an integer number of bars
    stimSize = ceil(stimSize/barsWidth)*barsWidth;
    
    % Define the background Destination Rectangle
    backRect = SetRect(0,0,stimSize, stimSize);
    backRect = CenterRect(backRect, screen.rect);
    
    % Define the obj Destination Rectangle
    objRect = SetRect(0, 0, objSizeH, objSizeV);
    objRect = CenterRect(objRect, screen.rect);
    objRect = OffsetRect(objRect, objCenterXY(1), objCenterXY(2));

    % Define the source rectangles
    backSource = SetRect(0, 0, stimSize, stimSize);
    backSource = OffsetRect(backSource, stimSize/2,0);
    backSourceOri = backSource;

    % make background textures
    x= 1:2*stimSize;
    bars = ones(stimSize,1)*ceil(mod(floor(x/barsWidth),2)*2*screen.gray*backContrast...
        + screen.gray*(1-backContrast));
    barsRect = SetRect(0,0,size(bars,1), size(bars,2));
    
    % Grab the images and constrain the size
%    im = LoadIm('rocks.jpeg', 127, objContrast);
    im = LoadIm('image2.JPG', 127, objContrast);
    if (objSizeH ~= size(im,1) || objSizeV ~= size(im,2))
        im = imresize(im, [objSizeH objSizeV]);
    end
        
    imRect = CenterRect(objRect, barsRect);
    backTex=zeros(1,4);
    for i=1:4
        bars(imRect(1):imRect(3)-1, imRect(2):imRect(4)-1)=im;
        im = rot90(im);
        
        backTex(i) = Screen('MakeTexture', screen.w, bars);
    end
    clear bars
    
    
    % Define the PD box
    pd = SetRect(0,0, 100, 100);
    pd = CenterRectOnPoint(pd, screen.rect(3)*.95, screen.rect(4)*.15);
    
    % We run at most 'consPresentationsN' if user doesn't abort via
    % keypress.
    presentationsN = uint32(movieDurationSecs/presentationLength);

    framesN = uint32(presentationLength*60);
    
    % make the jitter sequence
    S1 = RandStream('mcg16807', 'Seed',backSeed);
    jitterSeq = randi(S1, 3, 1, framesN)-2;
    jitterSeq(1, framesN) = barsWidth;

    % make the random sequence of objects to be presented.
    S2 = RandStream('mcg16807', 'Seed', objSeed);
    object = randperm(S2, presentationsN)-1;
    object = mod(object, 4)+1;
    
    % Animationloop:
    for presentation = 0:presentationsN-1
        shift = [0 0 0 0];
        for frame=0:framesN-1
            shift = shift + jitterSeq(frame+1)*[1 0 1 0];
            Screen('DrawTexture', screen.w, backTex(object(presentation+1)), backSource-shift, backRect, 0,0);
            
            DisplayStimInPD2(pdStim, pd, frame, 60, screen)
            
            % Flip 'waitframes' monitor refresh intervals after last redraw.
            vbl = Screen('Flip', screen.w, vbl + (waitframes - 0.5) * screen.ifi);

            
            % Previous function DID modify backSource and objSource.
            % Recenter backSource to prevent too much sliding of the texture.
            % objSource has to be reinitialize so that all 3 sequences will
            % have the same phase.
            backSource = mod(backSource.*[1 0 1 0], 2*barsWidth)+backSourceOri.*[1 1 1 1];
        
            if (KbCheck)
                break
            end
        end
        if (KbCheck)
            break
        end
    end
    

catch ME
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.
    disp(ME)
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

    
        
    % Object related
    p.addParamValue('objContrast', .05, @(x)x>0 && x<=1);
    p.addParamValue('objJitterPeriod', 2, @(x)x>0 );
    p.addParamValue('objSeed', 1, @(x)isnumeric(x));
    p.addParamValue('objSizeH', 16*12, @(x)x>0);
    p.addParamValue('objSizeV', 16*12, @(x)x>0);
    p.addParamValue('objCenterXY', [0 0], @(x)size(x,2)==2);
    
    % Background related
    p.addParamValue('backSeed', 1, @(x)isnumeric(x));
    p.addParamValue('backContrast', 1, @(x)x>0 && x<=1);
    p.addParamValue('backJitterPeriod', 2, @(x)x>0);

        % General
    p.addParamValue('stimSize', 16*32, @(x)x>0);
    p.addParamValue('presentationLength', 22, @(x)x>0);
    p.addParamValue('movieDurationSecs', 1600, @(x)x>0);
    p.addParamValue('pdStim', 1, @(x)x>=0 && x<256);
    p.addParamValue('debugging', 0, @(x)x>0 && x <=1);
    p.addParamValue('barsWidth', 8, @(x)x>0);
    p.addParamValue('waitframes', 1, @(x)isnumeric(x)); 
    p.addParamValue('vbl', 0, @(x)x>0);

    

    % Call the parse method of the object to read and validate each argument in the schema:
    p.parse(varargin{:});
    
end

