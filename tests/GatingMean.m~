function GatingMean(varargin)
% Wrapper to call JitterBackTex_JitterObjTex
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


p  = inputParser;   % Create an instance of the inputParser class.

p.addParamValue('backContrast', 1, @(x)x>0);
p.addParamValue('barsWidth', 8, @(x) x>0);
p.addParamValue('presentationLength', 50, @(x) x>0);
p.addParamValue('movieDurationSecs', 400, @(x) x>0);
p.addParamValue('stimSize', 768, @(x) x>0);
p.addParamValue('waitframes', 1, @(x) x>0);
p.addParamValue('backReverseFreq', 1, @(x) x>0);
p.addParamValue('objContrasts', [.03 .03 .03 .03], @(x) isnumeric(x));
p.addParamValue('objMeans', [32 64 128 256], @(x) isnumeric(x));
p.addParamValue('objSeed', 1, @(x) isnumeric(x));
p.addParamValue('backTexture', {}, @(x) iscell(x));
p.addParamValue('backAngle', 0, @(x) isnumeric(x));
p.addParamValue('backPattern', 0, @(x) x==1 || x==0);   % 0 for bars
                                                        % 1 for checkers
                                                        
p.parse(varargin{:});

backContrast = p.Results.backContrast;
barsWidth = p.Results.barsWidth;
backReverseFreq = p.Results.backReverseFreq;
presentationLength = p.Results.presentationLength;
movieDurationSecs = p.Results.movieDurationSecs;
stimSize = p.Results.stimSize;
waitframes = p.Results.waitframes;
objContrasts = p.Results.objContrasts;
objMeans = p.Results.objMeans;
objSeed = p.Results.objSeed;
backTex = p.Results.backTexture;
backPattern = p.Results.backPattern;
backAngle = p.Results.backAngle;

try
    InitScreen(0);
    
    % make the background texture
    if isempty(backTex)
        if (backPattern)
            backTex = GetCheckersTex(stimSize+barsWidth, barsWidth, screen, backContrast);
        else
            backTex = GetBarsTex(stimSize+barsWidth, barsWidth, screen, backContrast);
        end
        killTexFlag = 1;
    else
        killTexFlag = 0;
    end
    
    % Define the background Destination Rectangle
    backRect = GetRects(stimSize, screen.center);
    
    % Define the back source rectangle
    backSource = SetRect(0,0,stimSize,1);
    backSourceOri = backSource;
    
    % define the obj rect. 
    objRect = GetRects(192, screen.center);
    
    % Define the PD box
    if exist('pd', 'var')==0 || isempty(pd)
       pd = DefinePD();
    end

    % make the jitterSeq corresponding to saccades
    framesPerSec = 60;
    framesN = uint32(presentationLength*60);

    backSeq = zeros(1, framesN);
    ForJumps = 1:framesPerSec/backReverseFreq/waitframes:framesN;
    BackJumps = framesPerSec/backReverseFreq/waitframes/2+1:framesPerSec/backReverseFreq/waitframes:framesN;
    backSeq(ForJumps) = barsWidth;
    backSeq(BackJumps) = -barsWidth;
            
    % We run at most 'consPresentationsN' if user doesn't abort via
    % keypress.
    presentationsN = movieDurationSecs/presentationLength;
    
    objStream = RandStream('mcg16807', 'Seed',objSeed);

    % Animationloop:
    for i=0:presentationsN-1
        objContrast = objContrasts(mod(i, length(objContrasts))+1);
        objMean = objMeans(mod(i, length(objMeans))+1);
        frame = 0;
        while (frame < framesN) & ~KbCheck %#ok<AND2>
            % Background Drawing
            % ---------- -------
            backSource = backSource + backSeq(frame+1)*[1 0 1 0];
            
            Screen('FillRect', screen.w, screen.gray)
            
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
                
                
            Screen('DrawTexture', screen.w, backTex{1}, backSource, backRect, backAngle,0);

            % Restore alpha blending mode for next draw iteration:
            Screen('Blendfunction', screen.w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

           
            % Object Drawing
            % --------------
            objColor = round(randn(objStream)*objContrast*objMean + objMean);
            Screen('FillRect', screen.w, objColor, objRect);
            
            % Photodiode box
            % --------------
            DisplayStimInPD2(pdStim, pd, frame, 60, screen)
            
            % Flip 'waitframes' monitor refresh intervals after last redraw.
            vbl = Screen('Flip', screen.w, vbl + (waitframes - 0.5) * screen.ifi);
            frame = frame + waitframes;
        end
        backSource = backSourceOri;
        
        
        if KbCheck
            break
        end
    end
    
    % After drawing, we have to discard the noise checkTexture.
    if (killTexFlag)
        Screen('Close', backTex{1});
    end
    
    
catch
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.
    FinishExperiment();
    psychrethrow(psychlasterror);
end %try..catch..
end