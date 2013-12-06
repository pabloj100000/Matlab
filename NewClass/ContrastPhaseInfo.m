function ContrastPhaseInfo(varargin)
    % THis experiment is designed to have:
    %   1)  4 objects (2 intensities lasting 200ms each, sequence can be 00,
    %       01, 10 or 11)
    %   2)  2 contrasts (by default 3% and 35%)
    %   3)  The two background phases are treated as different
    %   4)  4 different obj-back offsets (The object can change relative 
    %       to the background saccade at either 0, 50, 100 or 150ms offset)
    %   
    %   total number of combinations is 4 objects * 2 contrasts * 4 phases
    %   = 32
    %   if I want 100 repeats per condition I need 3200 total trials each
    %   lasting whatever the background period is.
    global screen

    p=ParseInput(varargin{:});

    % background and general parameters
    stimSize = p.Results.stimSize;
    backPattern = p.Results.backPattern;
    backCheckerSize = p.Results.backCheckerSize;
    backContrast = p.Results.backContrast;
    trials = p.Results.trials;
    
    % object parameters
    objContrasts = p.Results.objContrasts;
    objRect = p.Results.objRect;
    objFreq = p.Results.objFreq;
    objPhaseOffsets = p.Results.objPhaseOffsets;
    
    InitScreen(0);
    Add2StimLogList();

    % background parameters

    if (backPattern)
        backTex = GetCheckersTex(stimSize/backCheckerSize+1, 1, backContrast);
    else
        backTex = GetBarsTex(stimSize/backCheckerSize+1, 1, backContrast);
    end
    

    for i=1:length(objContrasts)
        objTex(i) = GetCheckersTex(2, 1, objContrasts(i));
    end
    
    % general parameters
    
    for backPeriodOverObjSeqPeriod = 1:2
        for repeat=1:2
            for contrastIndex = 1:length(objContrasts)
                % changes objTex
                for offsetIndex = 1:length(objPhaseOffsets);
                    objPhaseOffset = objPhaseOffsets(offsetIndex);
                    for phase=1:4
                        pdStim = 253;
                        pause(.1)
                        ContrastPhaseInformation(objRect, phase, objPhaseOffset, ...
                            objTex(contrastIndex), backTex, backCheckerSize, backPeriodOverObjSeqPeriod, ...
                            trials, objFreq, stimSize, pdStim);
                        if (KbCheck)
                            break
                        end
                    end
                    if (KbCheck)
                        break
                    end
                end
                if (KbCheck)
                    break
                end
            end
            if (KbCheck)
                break
            end
        end
        if (KbCheck)
            break
        end
    end
    Screen('Close', backTex{1});
    for i=length(objContrasts):-1:1
        Screen('Close', objTex{i});
    end
    FinishExperiment();

end

function ContrastPhaseInformation(objRect, phase, objPhaseOffset, objTex, backTex, ...
    checkersSize, backPeriodOverObjSeqPeriod, trials, objFreq, stimSize, pdStim)
%   obj and background will both be either bars or checkers of a given
%   size. The phase and contrast will change over some values.
% 
%   Divide the screen in object and background.
%   Object will be a given texture changing phases every so often.
%   Back will be a grating of a giving contrast and spatial frequency
%   that reverses periodically at backReverseFreq.
%
%   The way the code is written the object intensity changes every
%   0.2s
%   The backPeriod is either 1 or 1.4, this means
%   that one background phase changes at 0 and the other phase changes
%   at 0.5 or 0.7 which is not a multiple of 0.2. Therefore in each
%   call to ContrastPhaseInformation below, the timing between changing
%   the object and the background is 100ms when considering both phases.
%   In other words, when:
%   objOffset(ms)      delay backPhase1 (ms)      delay backPhase2 (ms)
%       0                       0                       100
%       50                      50                      150
%       100                     100                     0
%       150                     150                     50
%
%   So I have to make calls to contrastPhaseInformation with all
%   possible delays.

global vbl screen pd

if isempty(vbl)
    vbl=0;
end

try

    framesPerSec = screen.rate;

    backSourceOri = GetRects(stimSize/checkersSize, stimSize/checkersSize/2*[1 1]);
    backRect=GetRects(stimSize, screen.center);
    objSourceOri = [0 0 1 1];
    objSource = objSourceOri;
            
    % Define the PD box
    if exist('pd', 'var')==0 || isempty(pd)
       pd = DefinePD();
    end
    
    % make a pseudo random sequence of contrasts such that 4 consecutive
    % bits make a # and all 16 numbers between 0 and 15 happen once when
    % sliding the 4 bit coding window by 1.
    phaseSeq = [0 1 1 0];
    phasesN = length(phaseSeq);
    if (phase > phasesN)
        error 'phase is longer than length (phaseSeq)'
    end
    
    % make the saccade sequence
    objFramesPeriod = round(framesPerSec/objFreq);
    backFramesPeriod = objFramesPeriod*phasesN*backPeriodOverObjSeqPeriod;
    framesN = trials*backFramesPeriod;

    
    backIndex = 1;
    for frame=0:framesN-1
        
        % is it time to change the center's phase?
        if (mod(frame-objPhaseOffset, objFramesPeriod)==0)
            objSource = objSourceOri + phaseSeq(phase)*[1 0 1 0];
            phase = mod(phase, phasesN)+1;
        else
        end
        
        % is it time to reverse the background?
        if (mod(frame, backFramesPeriod/2)==0)
            backSource = backSourceOri+backIndex*[1 0 1 0];
            backIndex = mod(backIndex+1,2);
        end
        
        % {
        Screen('FillRect', screen.w, screen.gray);
        
        % Disable alpha-blending, restrict following drawing to alpha channel:
        Screen('Blendfunction', screen.w, GL_ONE, GL_ZERO, [0 0 0 1]);
        
        % Clear 'dstRect' region of framebuffers alpha channel to zero:
        %        Screen('FillRect', screen.w, [0 0 0 0], backRect);
        Screen('FillRect', screen.w, [0 0 0 0]);
        
        % Fill circular 'dstRect' region with an alpha value of 255:
        Screen('FillOval', screen.w, [0 0 0 255], backRect);
        
        % Enable DeSTination alpha blending and reenalbe drawing to all
        % color channels. Following drawing commands will only draw there
        % the alpha value in the framebuffer is greater than zero, ie., in
        % our case, inside the circular 'dst2Rect' aperture where alpha has
        % been set to 255 by our 'FillOval' command:
        Screen('Blendfunction', screen.w, GL_DST_ALPHA, GL_ONE_MINUS_DST_ALPHA, [1 1 1 1]);
        
        % display background texture
        Screen('DrawTexture', screen.w, backTex{1},backSource,backRect, 0, 0);
        
        % Restore alpha blending mode for next draw iteration:
        Screen('Blendfunction', screen.w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        
        
        % Draw object
        Screen('FillRect', screen.w, screen.gray, objRect);
        
        Screen('DrawTexture', screen.w, objTex{1}, objSource, objRect, 0, 0);
        
        % Restore alpha blending mode for next draw iteration:
        Screen('Blendfunction', screen.w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        
        % Photodiode box
        % --------------
        DisplayStimInPD2(pdStim, pd, frame, screen.rate, screen)
        
        Screen('Flip', screen.w);
        %}
        if (KbCheck)
            break
        end
        
    end
    
catch
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.
    CleanAfterError();
    psychrethrow(psychlasterror);
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
    %     @(x)any(strcmpi(x,{'html','ppt','xml','latex'})));
    % p.addParamValue('outputDir', pwd, @ischar);
    % p.addParamValue('maxHeight', [], @(x)x>0 && mod(x,1)==0);

    p  = inputParser;   % Create an instance of the inputParser class.

    [screenX, screenY] = SCREEN_SIZE;
    stimSize = floor(screenY/PIXELS_PER_100_MICRONS)*PIXELS_PER_100_MICRONS;
    
    % General
    p.addParamValue('stimSize', stimSize, @(x)x>0);
    p.addParamValue('presentationLength', 100, @(x) isnumeric(x));
    p.addParamValue('waitframes', 1, @(x)isnumeric(x)); 
    p.addParamValue('vbl', 0, @(x)x>0);
    p.addParamValue('pdStim', 253, @(x) isnumeric(x));
    p.addParamValue('trials', 50, @(x) x>0 );
    
    % Object related
    p.addParamValue('objContrasts', [.03 .35], @(x) all(all(x>=0)) && all(all(x<=1)));
    p.addParamValue('objTexture', [], @(x) iscell(x));
    p.addParamValue('objRect', GetRects(12*PIXELS_PER_100_MICRONS, [screenX screenY]/2), @(x) size(x,2)==4);
    p.addParamValue('objFreq', 5, @(x) x>0);
    p.addParamValue('objPhaseOffsets', [0 3 6 9], @(x) isnumeric(x));    
    p.addParamValue('objCheckerSize', 12*PIXELS_PER_100_MICRONS, @(x) x>0);
    p.addParamValue('phaseSeq', [], @(x) isnumeric(x));

    % Background related
    p.addParamValue('backContrast', 1, @(x)x>=0 && x<=1);
    p.addParamValue('backPeriodOverObjSeqPeriod', 1, @(x) x>0 && isinteger(x));
    p.addParamValue('backTexture', [], @(x) iscell(x));
    p.addParamValue('backRect', GetRects(stimSize, [screenX screenY]/2), @(x) isnumeric(x) && size(x,2)==4);
    p.addParamValue('backCheckerSize', PIXELS_PER_100_MICRONS/2, @(x) x>0);
    p.addParamValue('angle', 0, @(x) x>=0);
    p.addParamValue('backPattern', 1, @(x) x==0 || x==1);   % 0 for bars
                                                            % 1 for
                                                            % checkers
    p.addParamValue('barsWidth', PIXELS_PER_100_MICRONS/2, @(x) x>0);
    
    % Call the parse method of the object to read and validate each argument in the schema:
    p.parse(varargin{:});
    
end




