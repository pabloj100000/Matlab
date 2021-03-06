function  ExpandingGrating(center, varargin)
    % stepSize is in microns
    global screen

    p=ParseInput(varargin{:});

    objectsN = p.Results.objectsN;
    stepSize = p.Results.stepSize;
    checkersSize = p.Results.checkersSize;
    contrast = p.Results.contrast;
    freq = p.Results.freq;
    waitframes = p.Results.waitframes;
    trialsN = p.Results.trialsN;
    trials2 = p.Results.trials2;
    objAngle = p.Results.objAngle;
try
    InitScreen(0);
    Add2StimLogList();

    backTex = GetCheckersTex(objectsN*stepSize/checkersSize+2, 1, contrast);
    
    d = objectsN*checkersSize/2;
    objRect = SetRect(center(1)-d, center(2)-d, center(1)+d, center(2)+d);
    
    % Define the background Destination Rectangle
        
    destMask{objectsN} = SetRect(0, 0, 1, 1);
    for i=1:objectsN
        destMask{i} = SetRect(0, 0, i*stepSize, i*stepSize);
        destMask{i} = CenterRect(destMask{i}, objRect);
    end
    
    % Define the PD box
    pd = DefinePD();

    updateRate = screen.rate/waitframes;
    updateTime = 1/updateRate;
    shiftFrames = fix(updateRate/freq/2);
    framesN = shiftFrames*trialsN;
    
    backStream = RandStream('mcg16807', 'Seed',1);
    RandStream.setDefaultStream(backStream);
    phaseX = 0;
%{    
sizes = ones(1, 2*objectsN);
sizes(1:objectsN) = randperm(objectsN);
sizes(objectsN+1:2*objectsN) = randperm(objectsN);
%}
    for trial=1:trials2
        order = 1:objectsN;
        for size = order
            for frame=0:framesN-1
                if (mod(frame, shiftFrames)==0 || shiftFrames==inf)
                    % reverse background
                    phaseX = mod(phaseX + .5+rand(), 2);
                    objSource = SetRect(phaseX, 0, size*stepSize/checkersSize+phaseX, size*stepSize/checkersSize);
                end

                Screen('FillRect', screen.w, screen.gray, screen.rect);


                % Draw 2nd grating texture, but only inside alpha == 255 circular
                % aperture, and at an angle of 90 degrees:
                Screen('DrawTexture', screen.w, backTex{1}, objSource, destMask{size}, objAngle,0)

                % Photodiode box
                % --------------
                if (frame==0 || mod(frame, shiftFrames)==0)
                    Screen('FillOval', screen.w, screen.white, pd);
                else
                    Screen('FillOval', screen.w, screen.gray, pd);
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

function p =  ParseInput(varargin)
    p  = inputParser;   % Create an instance of the inputParser class.

%    [screenX, screenY] = Screen('WindowSize', max(Screen('Screens')));

    % Background related
    p.addParamValue('contrast', .1, @(x)x>=0 && x<=1);
    p.addParamValue('freq', 1, @(x) x>=0);
    rate = Screen('NominalFrameRate', max(Screen('Screens')));
    if (rate==0)
        rate=60;
    end
    p.addParamValue('waitframes', round(rate/30), @(x)isnumeric(x));         
    p.addParamValue('trialsN', 60, @(x) x>0);
    p.addParamValue('trials2', 2, @(x) x>0);
    p.addParamValue('objAngle', 0, @(x) isnumeric(x));
    p.addParamValue('center', [15.5 15.5], @(x) size(x)==[1 2]);
    % General
    p.addParamValue('checkersSize', round(PIXELS_PER_100_MICRONS/4), @(x)x>0);
    p.addParamValue('objectsN', 20, @(x) x>0);
    p.addParamValue('stepSize', round(PIXELS_PER_100_MICRONS/2), @(x) x>0);
    
    % Call the parse method of the object to read and validate each argument in the schema:
    p.parse(varargin{:});
    
end

