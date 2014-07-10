function CheckerPhases(varargin)

global screen
try
    Add2StimLogList();
    
    % process Input variables
    p = ParseInput(varargin{:});
    trialsN = p.Results.trialsN;
    phasesN = p.Results.phasesN;
    checkerSize = p.Results.checkerSize;
    checkersN = p.Results.checkersN;
    fixationLength = p.Results.fixationLength;

    InitScreen(0);
    
    x = 0:checkerSize*(checkersN+2)-1;
    bars = ceil(mod(floor(x/checkerSize),2)*screen.white);
    
    texture = Screen('MakeTexture', screen.w, bars);

    destRect = SetRect(0, 0, 1, 1)*checkerSize*checkersN;
    destRect = CenterRect(destRect, screen.rect);
    
    sourceRect = SetRect(0, 0, 1, 1)*checkerSize*checkersN;

    framesPerSec = round(screen.rate/screen.waitframes);
    framesN = fixationLength*framesPerSec;

    offsets = 0:2*checkerSize/phasesN:2*checkerSize;
    
    pd = DefinePD();
    
    for trial=1:trialsN
        comment = {['trial : ',num2str(trial), '/', num2str(trialsN)]};
        for angle=0:1
            for j = 0:2*phasesN-1
                offset = offsets(floor(j/2)+1);
                comment{2} = ['condition : ', num2str(floor(j/2)+1+phasesN*angle), '/', num2str(2*phasesN)];
                
                for frame=1:framesN
                    if mod(j,2)==0
                        Screen('FillRect', screen.w, screen.gray);
                    else
                        Screen('DrawTexture', screen.w, texture, sourceRect+offset, destRect, 90*angle);
                    end
                    DrawMultiLineComment(screen, comment);
                    
                    if (frame==1)
                        Screen('FillOval', screen.w, screen.white, pd);
                    end
                    
                    screen.vbl = Screen('Flip', screen.w, screen.vbl+(screen.waitframes-.5)*screen.ifi);
                    
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
    p.addParamValue('trialsN', 20, @(x) x>0);
    p.addParamValue('phasesN', 4, @(x) X>0);
    p.addParamValue('checkerSize', PIXELS_PER_100_MICRONS, @(x) x>0);
    p.addParamValue('checkersN', 8, @(x) x>0);
    p.addParamValue('fixationLength', 1, @(x) isnumeric(x) && x>=0);
    
    % Call the parse method of the object to read and validate each argument in the schema:
    p.parse(varargin{:});
    
end


