function returnSeed = UFlickerObj(varargin)
    % wrapper to call JitteringBackTex_UniformFieldObjText
    %
    % There are 4 different backgrounds. Each can be turned on/off by
    % setting clearing the corresponding bit in backMode array
    % backMode(1):    repeated random jitter, lasts backJitterPeriod
    %           all presentations have the same sequence
    % backMode(2):    random jitter, lasts backJitterPeriod
    %           every presentation has a different random sequence
    % backMode(3):    reversing @backReverseFreq
    % backMode(4):    still
    %
    % There are several obj rectangles (at least 1) passed through objRect
    % (an nx4 array describing the n rectangles).
    % Each rectangle can different contrasts passed through objContrasts,
    % an n x contrastN array. Each presentation will pick the contrasts 
    % randomly for each checker. Alternatively, objContrasts can be
    % 1xcontrastsN, in that case, each presentation picks the contrast
    % randomly but the same contrast is used for all checkers in that
    % presentation.
    %
    % Also, the random sequence in each checker can be repeated if
    % repeatObjSeq is set or they can all be different. Default behaviour
    % is, 'all presentations are different'.
    %
    % Internaly, I will work on backN 'presentations' at a time. I will
    % randomly pick an order for them and after displaying them all, I will
    % start again until presentationsN 'presentations' are done

    global vbl screen backRect backSource objRect pd

    if isempty(vbl)
        vbl=0;
    end
    
    p=ParseInput(varargin{:});

    objContrasts = p.Results.objContrast;
    objMeans = p.Results.objMean;
    objSeed  = p.Results.objSeed;
    objRect = p.Results.rects;

    
    backMode = logical(p.Results.backMode);             %[0 0 1 0] for reversing background.
    backContrast = p.Results.backContrast;
    backReverseFreq = p.Results.backReverseFreq;        % for reversing
    backJitterPeriod = p.Results.backJitterPeriod;
    backAngle = p.Results.angle;
    backSeed = p.Results.backSeed;
    backTex = p.Results.backTexture;
    backPattern = p.Results.backPattern;
    
    stimSize = p.Results.stimSize;
    presentationLength = p.Results.presentationLength;
    movieDurationSecs = p.Results.movieDurationSecs;
    debugging = p.Results.debugging;
    barsWidth = p.Results.barsWidth;
    waitframes = p.Results.waitframes;
    pdStim = p.Results.pdStim;
    
    backN = sum(backMode);
    contrastsN = size(objContrasts,2);

    
    % Redefine exp time to have an even number of jitters
    movieDurationSecs = contrastsN*backN*presentationLength* ...
        floor(movieDurationSecs/(contrastsN*backN*presentationLength));

    % if by any reason backJitterPeriod or objjitterPeriod are bigger than
    % presentationLength is because I forgot to input the right parameters,
    % fix it
    if (presentationLength < backJitterPeriod)
        backJitterPeriod = presentationLength;
    end
    if (size(objMeans,2) < size(objRect,1))
        objMeans = ones(1, size(objRect,1))*objMeans;
    end
    
try
    InitScreen(debugging);
    
    % make the background texture
    if (isempty(backTex))
        clearBackTexFlag = 1;
        if (backPattern)
            backTex = GetCheckersTex(stimSize+barsWidth, barsWidth, backContrast);
        else
            backTex = GetBarsTex(stimSize+barsWidth, barsWidth, backContrast);
        end
    else
        clearBackTexFlag = 0;
    end
    
    % Define the background Destination Rectangle
    backRect = SetRect(0,0,stimSize, stimSize);
    backRect = CenterRect(backRect, screen.rect);
    
    % Define the source rectangles
%    backSource = GetRects(stimSize, [screen.rect(3) screen.rect(4)]/2);
    backSource = SetRect(0, 0, stimSize, stimSize);
    backSourceOri = backSource;
    
    % Define the PD box
    if exist('pd', 'var')==0 || isempty(pd)
        pd = DefinePD();
    end

    framesPerSec = 60/waitframes;
    backJumpsPerPeriod = round(backJitterPeriod*framesPerSec);
    objJumpsPerPeriod = round(presentationLength*framesPerSec);

    % make the Still, the reversing and the random jitter background
    jitterSeq(4,:)=zeros(1, backJumpsPerPeriod);
    forwardJumps = uint32(1:framesPerSec/backReverseFreq:backJumpsPerPeriod);
    backJumps = uint32(framesPerSec/backReverseFreq/2+1:framesPerSec/backReverseFreq:backJumpsPerPeriod);
    jitterSeq(3,forwardJumps)=   barsWidth;
    jitterSeq(3,backJumps)=   -barsWidth;
    S1 = RandStream('mcg16807', 'Seed', backSeed);
    jitterSeq(1,:)=randi(S1, 3, 1, backJumpsPerPeriod)-2;
    backStream = RandStream('mcg16807', 'Seed', backSeed);
    clear S1
    
    % We run at most 'presentationsN' if user doesn't abort via
    % keypress.
    presentationsN = uint32(movieDurationSecs/presentationLength)/backN;
    
    
    framesN = uint32(presentationLength*60);

    % make a random sequence of contrasts. If size(objContrasts,1)==1, then 
    % all checkers use the same contrast at any given point in time,
    % otherwise contrasts are randomly picked.
    S1 = RandStream('mcg16807', 'Seed',objSeed);
    contrastSeq = ones(1, presentationsN);
    blocksN = presentationsN/contrastsN;
    for i=0:blocksN-1
        contrastSeq(i*contrastsN+1:(i+1)*contrastsN) = randperm(S1, contrastsN);
    end
    clear S1;
%SaveBinary(contrastSeq, 'uint8')
    
    % random seeds for the object sequence intensities, one per checker and
    % contrast
%    S{1,contrastsN} = {};
%    for j=1:contrastsN
        S = RandStream('mcg16807', 'Seed',objSeed);
%        S{j} = RandStream('mcg16807', 'Seed',objSeed);
%    end
    
    % for efficiency preallocate objSeq
    objSeq = ones(1, objJumpsPerPeriod);
    
    % Animationloop:
    for presentation = 1:presentationsN

        % get a random order of all possible backgrounds, even the ones
        % that are not displayed. Latter on we might skip some of them
        backOrder = randperm(backStream, 4);
%backOrder
%backOrderArray(presentation, :)=backOrder;
        for back=1:4
            if (back==1)
                contrastIndex = contrastSeq(presentation);
                contrast = objContrasts(contrastIndex);
                % Sets the objSeq that will be used in the next backN presentations
                %                   objSeq(checker,:) = uint8(randn(S{checker}, 1, objJumpsPerPeriod)*screen.gray*checkContrast+screen.gray);
                if (mod(presentation, contrastsN)==1)
                    normDistribution = randn(S, 1, objJumpsPerPeriod);
                end
                
                % convert the normDistribution to intensity values taken
                % the contrast and mean into account.
                if (contrast==1)
                    objSeq = uint8(normDistribution>0)*255;
                else
                    objSeq = uint8(normDistribution*contrast*objMeans + objMeans);
                end
                
            end
            
            background = backMode(backOrder(back));
            % Do we have to skip this background?
            if (background==0)
                continue
            end
            if (backOrder(back)==2)
                % generate the new random jitter out of the backStream
                backSeq = randi(backStream, 3, 1, backJumpsPerPeriod)-2;
            else
                backSeq = jitterSeq(backOrder(back),:);
            end
            
%            [presentation backOrder(back)];
%            [backOrder(back) backSeq(1:10)]
%normDistribution(:,1:10)
%objSeq
%[checkContrast backOrder(back)]
%if (exist('totalbackSeq')==0)
%    clear Screen
%    totalbackSeq = zeros(1, presentationsN*backJumpsPerPeriod);
%end
%totalbackSeq((presentation-1)*backJumpsPerPeriod+1:presentation*backJumpsPerPeriod) = backSeq;
%if (exist('totalObjSeq')==0)
%    clear Screen
%    totalObjSeq = zeros(1, presentationsN*objJumpsPerPeriod);
%end
%totalObjSeq((presentation-1)*objJumpsPerPeriod+1:(presentation)*objJumpsPerPeriod) =  objSeq;
            JitteringBackTex_UniformFieldObj(backSeq, objSeq, ...
                waitframes, framesN, backTex{1}, backAngle, barsWidth, pdStim)
            % Previous function DID modify backSource. Recenter it to prevent
            % too much sliding of the texture.
            % Is not perfect and sliding will still take place but will be
            % slower and hopefully will be ok
            backSource = mod(backSource, 2*barsWidth)+backSourceOri;
            
            if (KbCheck)
                break
            end
        end
        if (KbCheck)
            break
        end
    end
    
    if (clearBackTexFlag)
        % After drawing, we have to discard the noise checkTexture.
        Screen('Close', backTex{1});
    end
    
    returnSeed = S.State;
    
    FinishExperiment();
    
catch exception
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.
    CleanAfterError();
    psychrethrow(psychlasterror);
    rethrow(exception)
end %try..catch..
end

function p =  ParseInput(varargin)
    % Generates a structure with all the parameters
    % Allowed parameters are:
    %
    % objContrast, objSeed, stimSize, objSizeH, objSizeV,
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

    [screenX, screenY] = SCREEN_SIZE;
    rect =  CenterRectOnPoint([0 0 12 12]*PIXELS_PER_100_MICRONS, screenX/2, screenY/2);
    
    % Object related
    p.addParamValue('objSeed', 1, @(x) isnumeric(x));
    p.addParamValue('objContrast', [.03 .06 .12 .24 1], @(x) all(all(x>=0)) && all(all(x<=1)));
    p.addParamValue('objMean', 127, @(x) all(all(x>=0)) && all(all(x<=255)));
    p.addParamValue('rects', rect, @(x) size(x,1)==4 || size(x,2)==4);
    
    % Background related
    p.addParamValue('backSeed', 2, @(x)isnumeric(x));
    p.addParamValue('backMode', [0 0 1 0], @(x) size(x,1)==1 && size(x,2)==4);
    p.addParamValue('backContrast', 1, @(x)x>=0 && x<=1);
    p.addParamValue('backJitterPeriod', 11, @(x)x>0);
    p.addParamValue('backReverseFreq', 1, @(x) x>0);
    p.addParamValue('backTexture', [], @(x) iscell(x));
    p.addParamValue('backRect', GetRects(screenY, [screenX screenY]/2), @(x) isnumeric(x) && size(x,2)==4);
    p.addParamValue('backPattern', 1, @(x) x==0 || x==1);
    p.addParamValue('angle', 0, @(x) isnumeric(x));
    
    % General
    p.addParamValue('stimSize', PIXELS_PER_100_MICRONS*32, @(x)x>0);
    p.addParamValue('presentationLength', 11, @(x)x>0);
    p.addParamValue('movieDurationSecs', 1600, @(x)x>0);
    p.addParamValue('debugging', 0, @(x)x>=0 && x <=1);
    p.addParamValue('barsWidth', PIXELS_PER_100_MICRONS/2, @(x)x>0);
    p.addParamValue('waitframes', 1, @(x)isnumeric(x)); 
    p.addParamValue('pdStim', 3, @(x) isnumeric(x));
        

    % Call the parse method of the object to read and validate each argument in the schema:
    p.parse(varargin{:});
    
end




