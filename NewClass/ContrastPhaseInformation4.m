function ContrastPhaseInformation4(repeats, contrast)
%   Object is changing at 10Hz and background is reversing at 1Hz.
%   Object luminance is read from file and adjusted according to 
%   luminance = valueFromFile - base/2
%   luminance = gray + gray*luminance*contrast
global screen
    InitScreen(0);
    Add2StimLogList();

    repeatsPerBlock=10;
    for i=1:repeats/repeatsPerBlock
        period = .1;
        length = 4^3*period*repeatsPerBlock;
        OnePresentation('MSequence_4_3.txt', 'objContrast', contrast,...
            'backReverseFreq', 0, 'movieDurationSecs', length);
        
        period = .5;
        length = 4^3*period*repeatsPerBlock;
        OnePresentation('MSequence_4_3.txt', 'objContrast', contrast,...
            'movieDurationSecs', length);
        
        if (KbCheck)
            break
        end
    end
end

function OnePresentation(file, varargin)
global screen

p=ParseInput(varargin{:});

% object
objContrast = p.Results.objContrast;
objRect = p.Results.objRect;
objFreq = p.Results.objFreq;

% background
backContrast = p.Results.backContrast;
backReverseFreq = p.Results.backReverseFreq;
backCheckerSize = p.Results.backCheckerSize;
backAngle = p.Results.angle;
backPattern = p.Results.backPattern;

% general
stimSize = p.Results.stimSize;
movieDurationSecs = p.Results.movieDurationSecs;

try
            
    % make the background texture, each checker takes only 1 pixel
    backCheckersN = round(stimSize/backCheckerSize);
    backCheckersN = 2*ceil(backCheckersN/2);
    if (backPattern)
        backTex = GetCheckersTex(backCheckersN+1, 1, backContrast);
    else
        backTex = GetBarsTex(backCheckersN+1, 1, backContrast);
    end
    backSource = SetRect(0, 0, backCheckersN, backCheckersN);
    backDest1 = SetRect(0,0,backCheckersN*backCheckerSize, backCheckersN*backCheckerSize);
    backDest1 = CenterRect(backDest1, screen.rect);%-floor(backCheckerSize*[1/2 1/2 1/2 1/2]));
    backDest2 = CenterRect(backDest1, screen.rect+backCheckerSize*[0 1 0 1]);%+floor(backCheckerSize*[1/2 -1/2 1/2 -1/2]));
    objRect = CenterRect(objRect, screen.rect);
    
    % Define the PD box
    if exist('pd', 'var')==0 || isempty(pd)
        pd = DefinePD();
    end
    
    % make the saccade sequence
    framesN = ceil(movieDurationSecs*objFreq);
    backFramesPeriod = round(objFreq/backReverseFreq);
    if isinf(backFramesPeriod)
        backFramesPeriod=framesN+1;
    end
    waitTime = 1/objFreq-1/screen.rate/2;%waitframes/screen.rate;
    
    % Read a pseudo random sequence of luminance levels such that 'codeLength'
    % consecutive bits make a stimulus in base 'base'. The name of the file
    % is of the form 'MSequence_base_codeLength.txt'
    fid = fopen(file, 'r');
    findDash = strfind(file, '_');
    base = str2double(file(findDash(1)+1:findDash(2)-1));
    seqMean = (base-1)/2;

    for frame=0:framesN-1
        if feof(fid)
            frewind(fid)
        end
        luminance = fscanf(fid, '%u', 1)-seqMean;
        color = screen.gray * (1 + luminance*objContrast);

        % is it time to reverse the background?
        if (mod(frame, backFramesPeriod)==0)
            backDest = backDest1;
            backFlag=1;
        elseif (mod(frame, backFramesPeriod/2)==0)
            backDest = backDest2;
            backFlag=1;
        end
        % {
        Screen('FillRect', screen.w, screen.gray);
        
        % Disable alpha-blending, restrict following drawing to alpha channel:
        Screen('Blendfunction', screen.w, GL_ONE, GL_ZERO, [0 0 0 1]);
        
        % Clear 'dstRect' region of framebuffers alpha channel to zero:
        %    Screen('FillRect', screen.w, [0 0 0 0], backRect);
        Screen('FillRect', screen.w, [0 0 0 0]);
        
        % Fill circular 'dstRect' region with an alpha value of 255:
        Screen('FillOval', screen.w, [0 0 0 255], backDest);
        
        % Enable DeSTination alpha blending and reenalbe drawing to all
        % color channels. Following drawing commands will only draw there
        % the alpha value in the framebuffer is greater than zero, ie., in
        % our case, inside the circular 'dst2Rect' aperture where alpha has
        % been set to 255 by our 'FillOval' command:
        Screen('Blendfunction', screen.w, GL_DST_ALPHA, GL_ONE_MINUS_DST_ALPHA, [1 1 1 1]);
        
        % display background texture
        Screen('DrawTexture', screen.w, backTex{1},backSource,backDest, backAngle, 0);
        
        % Restore alpha blending mode for next draw iteration:
        Screen('Blendfunction', screen.w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        
        
        % Draw object
        Screen('FillRect', screen.w, color, objRect);
        
        
        
        % Photodiode box
        % --------------
        if (backFlag)
            color = screen.white;
            backFlag=0;
        else
            color = screen.gray * (1 + 2*luminance*objContrast);
        end
        Screen('FillOval', screen.w, color, pd);
        screen.vbl = Screen('Flip', screen.w, screen.vbl + waitTime, 1);
        %}
        if (KbCheck)
            break
        end
        
    end
    
        
    % After drawing, we have to discard the noise checkTexture.
    Screen('Close', backTex{1});
    
    fclose(fid);
    
    FinishExperiment();
    
catch exception
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.

    if exist('fid', 'var')
        fclose(fid);
    end
    
    CleanAfterError();
    rethrow(exception);
end %try..catch..
end

function p =  ParseInput(varargin)
% Generates a structure with all the parameters
% Allowed parameters are:
%
% objContrast, objJitterPeriod, contrastSeed, stimSize, objSizeH, objSizeV,
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
% @(x)any(strcmpi(x,{'html','ppt','xml','latex'})));
% p.addParamValue('outputDir', pwd, @ischar);
% p.addParamValue('maxHeight', [], @(x)x>0 && mod(x,1)==0);

p  = inputParser;   % Create an instance of the inputParser class.

[screenX, screenY] = SCREEN_SIZE;
rate = Screen('NominalFrameRate', max(Screen('Screens')));

% General
p.addParamValue('stimSize', screenY, @(x)x>0);
p.addParamValue('movieDurationSecs', 16000, @(x)x>0);
p.addParamValue('waitframes', round(rate/30), @(x)isnumeric(x));
p.addParamValue('file', [], @(x)ischar(x));

% Object related
p.addParamValue('objContrast', .12, @(x) all(all(x>=0)) && all(all(x<=1)));
p.addParamValue('objTexture', [], @(x) iscell(x));
p.addParamValue('objRect', GetRects(12*PIXELS_PER_100_MICRONS, [screenX screenY]/2), @(x) size(x,2)==4);
p.addParamValue('objFreq', 10, @(x) x>0);
p.addParamValue('objCheckerSize', PIXELS_PER_100_MICRONS/2, @(x) x>0);
p.addParamValue('luminanceSeq', [], @(x) isnumeric(x));

% Background related
p.addParamValue('backContrast', 1, @(x)x>=0 && x<=1);
p.addParamValue('backReverseFreq', 1, @(x) x>=0);
p.addParamValue('backTexture', [], @(x) iscell(x));
p.addParamValue('backRect', GetRects(screenY, [screenX screenY]/2), @(x) isnumeric(x) && size(x,2)==4);
p.addParamValue('backCheckerSize', PIXELS_PER_100_MICRONS/2, @(x) x>0);
p.addParamValue('angle', 0, @(x) x>=0);
p.addParamValue('backPattern', 1, @(x) x==0 || x==1);

% Call the parse method of the object to read and validate each argument in the schema:
p.parse(varargin{:});

end



