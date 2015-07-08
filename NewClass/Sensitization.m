function Sensitization(varargin)
%   obj and background will both be either bars or checkers of a given
%   size. The phase and contrast will change over some values.
% 
% Divide the screen in object and background.
% Object will be a given texture changing phases every so often.
% Back will be a grating of a giving contrast and spatial frequency
% that reverses periodically at backReverseFreq.

global screen pd

if isempty(screen)
    screen.rate = max(Screen('NominalFrameRate', max(Screen('Screens'))),60);
end

    p  = inputParser;   % Create an instance of the inputParser class.

    [screenWidth screenHeight] = SCREEN_SIZE;
    p.addParamValue('lowLength', 16, @(x)x>0);
    p.addParamValue('hiLength', 4, @(x) x>0);
    p.addParamValue('repeats', 25, @(x) x>0);
    p.addParamValue('stimSize', screenHeight, @(x) x>0);
    p.addParamValue('waitframes', round(screen.rate/30), @(x) x>0);
    p.addParamValue('almostBlack', 50, @(x) x>0);
    
    p.parse(varargin{:});
    

    lowLength = p.Results.lowLength;
    hiLength = p.Results.hiLength;
    repeatsN = p.Results.repeats;
    stimSize = p.Results.stimSize;
    waitframes = p.Results.waitframes;
    almostBlack = p.Results.almostBlack;
    
try
    InitScreen(0, 800, 600, 100);
    Add2StimLogList();

    % each presentation will have all possible contrasts.

    % Init all random streams
    stream1 = RandStream('mcg16807', 'Seed', 1);

    rect = GetRects(stimSize, screen.center);
    
    % Define the PD box
    if exist('pd', 'var')==0 || isempty(pd)
        pd = DefinePD();
    end

    framesLo = round(screen.rate*lowLength/waitframes);
    framesHi = round(screen.rate*hiLength/waitframes);
    
    contrastHi = .35;
    contrastLo = .05;
    
    sigmaHi = contrastHi*screen.gray;
    sigmaLo = contrastLo*screen.gray;
    
    updateTime = waitframes/screen.rate - screen.ifi/2;
    
    for repeat=1:repeatsN
        for frame=0:framesHi+framesLo-1
            if (frame<framesHi)
                % Hi contrast
                color = sigmaHi*randn(stream1)+screen.gray;
            else
                color = sigmaLo*randn(stream1)+screen.gray;
            end
            Screen('FillRect', screen.w, screen.gray)
            Screen('FillOval', screen.w, color, rect)
            
            % Photodiode box
            % --------------
            if (frame==0)
                Screen('FillOval', screen.w, screen.white, pd);
            else
                Screen('FillOval', screen.w, color/2+almostBlack, pd);
            end
            
            screen.vbl = Screen('Flip', screen.w, screen.vbl + updateTime , 1);
            if (KbCheck)
                break
            end
        end
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

