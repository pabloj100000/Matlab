function ShowGaussianNatSceneWrapper(presentationLength, varargin)
global screen
try
    Add2StimLogList();
    Wait2Start()
    
    % process Input variables
    p = ParseInput(varargin{:});
    contrast = p.Results.contrast;
    nextSeed = p.Results.nextSeed;
    cellSize = p.Results.cellSize;
    imIndex = p.Results.imIndex;
    trialsN = p.Results.trialsN;
    path = p.Results.path;
    ctrlFlag = p.Results.ctrlFlag;
    outputSize = p.Results.outputSize;
    resetSeed = p.Results.resetSeed;
    
    % Edit this parameters as needed
    % Experiment runs for length(imIndex)*(PresentationLength1 +
    % PresentationLength2)*trialsN
%{
    contrast = 1;
    cellSize = 1*round(PIXELS_PER_100_MICRONS/2);
    nextSeed = 1;
    imIndex = 2:11;
    trialsN = 10;
    path = '';
    outputSize = min(screen.size);
    %}
    if ctrlFlag
        imIndex = 1;
    end
    
    Screen('FillRect', screen.w, 127);
    DrawMultiLineComment(screen, {'Pre processing images', '    Wait a bit and stim will start'});
    screen.vbl = Screen('Flip', screen.w);
    
    % do all computation upfront to prevent dropping frames in between images.
    [allMeans, allGradientUp, allGradientLeft] = ...
        GaussianizeImageSet(path, imIndex, cellSize, 1, contrast, outputSize);

    if ctrlFlag
        allMeans = ones(size(allMeans))*127;
        allGradientUp = ones(size(allGradientUp))*1;
        allGradientLeft = ones(size(allGradientLeft))*1;
        contrast=.1;
    end
    
    seed = nextSeed;

    framesPerSec = round(screen.rate/screen.waitframes);
    framesN = presentationLength*framesPerSec;

    for trial=1:trialsN
        % show each image for a rather long time, useful for computing
        % models early/late and comparing them
        for i=1:length(imIndex)

            if i==1 && ~resetSeed
                % if resetSeed, we are never executing this line and every
                % time will be using the same seed
                seed = nextSeed;
            end
            nextSeed = ShowCorrelatedGaussianCheckers(framesN, cellSize, ...
                allMeans(i,:, :), allGradientUp(i,:,:), allGradientLeft(i, :, :), ...
                contrast, seed);

            if (KbCheck)
                break
            end
        end

        if (KbCheck)
            break
        end
    end
    
    FinishExperiment();
    
catch exception
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.
    CleanAfterError();
    rethrow(exception)
end %try..catch..

end

function p = ParseInput(varargin)
    global screen
    p  = inputParser;   % Create an instance of the inputParser class.
   
    p.addParamValue('contrast', 1, @(x) x>=0 && x<=1);
    p.addParamValue('nextSeed', 1, @(x) isnumeric(x));
    p.addParamValue('cellSize', PIXELS_PER_100_MICRONS/2, @(x) x>=0 );
    p.addParamValue('imIndex', [2:11], @(x) all(isnumeric(x)) && size(x,1)==1);
    p.addParamValue('trialsN', 10, @(x) x>=0);
    p.addParamValue('path', '', @(x) isstr(x));
    p.addParamValue('ctrlFlag', 0, @(x) x==0 || x==1);
    p.addParamValue('outputSize', min(screen.size), @(x) isnumeric(x));
    p.addParamValue('resetSeed', 0, @(x) x==0 || x==1);

    % Call the parse method of the object to read and validate each argument in the schema:
    p.parse(varargin{:});
    
end

