function objSeed = TNF_Distance(varargin)
%   
global screen
    
try
    % process Input variables
    p = ParseInput(varargin{:});

    waitframes = p.Results.waitframes;
    objSeed = p.Results.objSeed;
    objContrast = p.Results.objContrast;
    presentationLength = p.Results.presentationLength;
    repeatCenterFlag = p.Results.repeatCenterFlag;
    barsWidth = p.Results.barsWidth;
    backContrast = p.Results.backContrast;
    backReverseFreq = p.Results.backReverseFreq;
    offsets = p.Results.offset;
    trialsN = p.Results.trialsN;
    almostBlack = 30;
    
    % change step size from microns into pixels
    offsets = offsets*PIXELS_PER_100_MICRONS/100;
    positionsN = length(offsets);
    % start the stimulus
%    InitScreen(0)
    Add2StimLogList();

    % get the background texture
    [screenX, screenY] = Screen('WindowSize', max(Screen('Screens')));
    stimSize = 2*barsWidth*floor(screenY/barsWidth/2);
    center = [screenX screenY]/2;
    baseRect{1} = [screenX/2 0 2*screenX screenY];
    baseRect{2} = [0 -screenY/2 screenX screenY/2];
    baseRect{3} = [0 0 screenX/2 screenY];
    baseRect{4} = [0 screenY/2 screenX 2*screenY];
    offsetDirection{1} = [1 0 1 0];
    offsetDirection{2} = -[0 1 0 1];
    offsetDirection{3} = -[1 0 1 0];
    offsetDirection{4} = [0 1 0 1];
    
    
    checkersN = floor(stimSize/barsWidth);
    backTex = GetCheckersTex(checkersN+1, 1, backContrast);
    
    backSource1 = SetRect(0, 0, checkersN, checkersN);
    backSource2 = SetRect(1, 0, checkersN+1, checkersN);
    backDest = SetRect(0,0,stimSize, stimSize);
    backDest = CenterRect(backDest, screen.rect);
    
    % I want framesN to have an even number of background reversals
    % 
    updateRate = screen.rate/waitframes;
    updateTime = 1/updateRate-1/screen.rate/2;
    backFrames = fix(screen.rate/waitframes/backReverseFreq/2);
    framesN = fix(presentationLength*screen.rate/waitframes);
    framesN = backFrames*fix(framesN/backFrames);
    backStream = RandStream('mcg16807', 'Seed',1);

    pd = DefinePD();

    objSeq = GetPinkNoise(0, framesN, objContrast, screen.gray, 0);
    for trial = 0:trialsN-1
        backAngle=90*trial;
        
        %        order = randperm(backStream, positionsN);
        order = 1:positionsN;
        for i=order
            % i=0:  backFreq  = 0, still background
            % i=1:  backFreq != 0, saccading background
            
            offset = offsets(i)*offsetDirection{mod(trial,4)+1};
%            offset = [0 0 0 0];
            for frame=0:framesN-1
                if (mod(frame, 2*backFrames)==0 || backFrames==inf)
                    % reverse background
                    backSource = backSource1;
                elseif (mod(frame, backFrames)==0)
                    backSource = backSource2;
                end
                
                Screen('FillRect', screen.w, screen.gray, screen.rect);
                
                Screen('DrawTexture', screen.w, backTex{1}, backSource, backDest, backAngle,0)
                
                % Object Drawing
                % --------------
                color = objSeq(frame+1);
                
                Screen('FillRect', screen.w, color, baseRect{mod(trial,4)+1} + offset);

                % Photodiode box
                % --------------
                if (frame==0 || mod(frame, backFrames)==0)
                    Screen('FillOval', screen.w, screen.white, pd);
                else
                    Screen('FillOval', screen.w, color/2+almostBlack, pd);
                end
                
                % Flip 'waitframes' monitor refresh intervals after last redraw.
                screen.vbl = Screen('Flip', screen.w, screen.vbl + updateTime , 1);
                
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

    % After drawing, we have to discard the noise checkTexture.
    Screen('Close', backTex{1});

    FinishExperiment();
    
catch exception
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.
    CleanAfterError();
    rethrow(exception)
end %try..catch..
end

function p = ParseInput(varargin)
    p  = inputParser;   % Create an instance of the inputParser class.

    rate = Screen('NominalFrameRate', max(Screen('Screens')));
    if (rate==0)
        rate=100;
    end
    
    % Object related
    p.addParamValue('objSeed', 1, @(x) isnumeric(x) && size(x,1)==1 );
    p.addParamValue('objContrast', .1, @(x) x>=0 && x<=1);
    p.addParamValue('repeatCenterFlag', 0, @(x) isnumeric(x));
%        p.addParamValue('rects', rect, @(x) size(x,1)==4 || size(x,2)==4);

        % Background related
    p.addParamValue('backContrast', 1, @(x)x>=0 && x<=1);
    p.addParamValue('backReverseFreq', 1, @(x) x>=0);
    p.addParamValue('backTexture', [], @(x) iscell(x));
%        p.addParamValue('backDest', GetRects(screenY, [screenX screenY]/2), @(x) isnumeric(x) && size(x,2)==4);
%        p.addParamValue('angle', 0, @(x) isnumeric(x));

        % General
    p.addParamValue('offset', [-7 -5 -3 -2 -1 0 1 2 3]*150, @(x) isnumeric(x));
%    p.addParamValue('offset', [-3 0 3]*150, @(x) isnumeric(x));
    p.addParamValue('presentationLength', 200, @(x)x>0);
    p.addParamValue('trialsN', 4);
%        p.addParamValue('movieDurationSecs', 10000, @(x)x>0);
    p.addParamValue('barsWidth', PIXELS_PER_100_MICRONS/2, @(x)x>0);
    p.addParamValue('waitframes', round(rate/30), @(x)isnumeric(x));

    % Call the parse method of the object to read and validate each argument in the schema:
    p.parse(varargin{:});
    
end
