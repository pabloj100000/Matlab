function SaccadeObject(varargin)
    % objLums should be a 3D array of luminance values for each object.
    % texture i will be created out of objLums(:, :, i) and it will
    % be stretched to fill the object
    global screen
try
    InitScreen(0)
    Add2StimLogList();

    %%%%%%%%%%%%%% Input Parser Starts here %%%%%%%%%%%%%%%%
    p  = inputParser;   % Create an instance of the inputParser class.

    p.addParamValue('objLums', DefaultObjLums(), @(x) isnumeric(x) && size(x,3)>=1);
    p.addParamValue('checkersSize', PIXELS_PER_100_MICRONS/2, @(x) x>0);
    p.addParamValue('stimSize', 768, @(x) x>0);
    p.addParamValue('blocksN', 4, @(x) x>0);
    p.addParamValue('trialsPerBlock', 110, @(x) x>0);
    p.addParamValue('saccadeRate', 1, @(x) x>0);   % in Hz
    p.addParamValue('objSize', 12*PIXELS_PER_100_MICRONS, @(x) x>0);   % in Hz
%    p.addParamValue('periLum', 127, @(x) x>=0 && x<=255);
%    p.addParamValue('periAlpha', 1, @(x) x>=0);

    p.parse(varargin{:});

    objLums = p.Results.objLums();
    checkersSize = p.Results.checkersSize;
    stimSize = p.Results.stimSize;
    blocksN = p.Results.blocksN;
    trialsPerBlock = p.Results.trialsPerBlock;
    saccadeRate = p.Results.saccadeRate;
    objSize = p.Results.objSize;
%    periLum = p.Results.periLum;
%    periAlpha = p.Results.periAlpha;
    
    %%%%%%%%%%%%%% Input Parser Ends %%%%%%%%%%%%%%%%
    % Define some variables
    
    
    % adjust stimSize to be an even number of checkers
    checkersN = floor(stimSize/checkersSize/2);
    stimSize = checkersN*checkersSize*2;
    
    % adjust object size to be an even number of checkers
    objSize = 2*checkersSize*floor(objSize/checkersSize/2);
    
    if (stimSize<1.5*objSize)
        stimSize = 768;
    end
    
    % create all the center textures;
    objTexture = cell(1, size(objLums,3));
    for i=1:size(objLums,3)
        objTexture{i} = Screen('MakeTexture', screen.w, objLums(:,:,i));
    end
    
    objectN = size(objLums,3);
    
    % Define the rectangles
    periDestRect = SetRect(0, 0, stimSize, stimSize);
    periDestRect = CenterRect(periDestRect, screen.rect);
    
    objDestRect = SetRect(0, 0, objSize, objSize);
    objDestRect = CenterRect(objDestRect, screen.rect);
    
    % offset both destination rectangles such that when saccading back and
    % forth they straddle the center of the screen
    objDestRect = floor(OffsetRect(objDestRect, -checkersSize/2, 0));
    periDestRect = floor(OffsetRect(periDestRect, -checkersSize/2, 0));
    
    texture = GetCheckersTex(stimSize/checkersSize+1, 1);
    
    pd = DefinePD;
    
    waitFrames = round(.02/screen.ifi);
    framesPerSaccade = screen.rate/saccadeRate/waitFrames;
    if (mod(framesPerSaccade,2));
        framesPerSaccade = framesPerSaccade+1;
    end
    
    % init random seed generator
    seqStream = RandStream('mcg16807', 'Seed', 1);
    periStream = RandStream('mcg16807', 'Seed', 1);
%objects = [];
%peris=[];
%periPhase=[];
    for block=1:blocksN
        objectOrder = randperm(seqStream, objectN);
%objects = [objects objectOrder]
        periSourceRect = SetRect(0, 0, stimSize/checkersSize, stimSize/checkersSize) + mod(block,2)*[1 0 1 0];
%periPhase=[periPhase mod(block, 2)]        
        for i=1:objectN
            object = objectOrder(i);
%            periAlphas = (randperm(periStream, 2)-1)*periAlpha;
            saccadingOrder = (randperm(periStream, 2)-1);
%peris = [peris periAlphas]
            % {
            for peri=1:2
                saccadingFlag = saccadingOrder(peri);
                for trial = 1:trialsPerBlock
                    for frame=1:framesPerSaccade;
                        if (frame==1)
                            objOffset = [0 0 0 0];
                            periOffset = [0 0 0 0];
                        elseif (frame==framesPerSaccade/2+1)
                            objOffset = [1 0 1 0]*checkersSize;
                            periOffset = objOffset*saccadingFlag;
                        end
                        
                        % enable alpha blending
%                        Screen('BlendFunction', screen.w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
                        
                        % Draw peri luminance values
%                        Screen('FillRect', screen.w, periLum, periDestRect+offset);
                        
                        % draw peri textures
                        Screen('DrawTexture', screen.w, texture{1}, periSourceRect, periDestRect + periOffset,0, 0);
                        
                        % disable alpha blending
%                        Screen('BlendFunction', screen.w, GL_ONE, GL_ZERO);
                        
                        % draw center
                        Screen('DrawTexture', screen.w, objTexture{object}, [], objDestRect+objOffset, 0, 0);
                        
                        if (frame==1)
                            pdColor = 255;
                        else
                            pdColor = 255/2;
                        end
                        
                        Screen('FillOval', screen.w, pdColor, pd);
                        
                        % write some text on the margin
                        text1 = sprintf('block: %d/%d', block, blocksN);
                        Screen('DrawText', screen.w, text1, 0, 0);
                        text1 = sprintf('object: %d/%d', i, objectN);
                        Screen('DrawText', screen.w, text1, 0, 20);
                        text1 = sprintf('trial: %d/%d', trial, trialsPerBlock);
                        Screen('DrawText', screen.w, text1, 0, 40);
                        
                        screen.vbl = Screen('Flip', screen.w, screen.vbl+(waitFrames-.5)*screen.ifi);
                        if (KbCheck())
                            break
                        end
                    end
                    if (KbCheck())
                        break
                    end
                end
                if (KbCheck())
                    break
                end
            end
            if (KbCheck())
                break
            end
                        %}
        end
        if (KbCheck())
            break
        end
    end
    
    Screen('Close', texture{1});
    FinishExperiment();

catch exception
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.
    CleanAfterError();
    rethrow(exception);
end %try..catch..end
end

function objLums = DefaultObjLums()
    objectsN = 9;       % has to be odd
    amplitud=1;
    barsN = 6;
    objLums = ones(1, barsN, objectsN);
    bars = [0 -1 1 -1 1 0];
    bars(1)=0;
    bars(barsN)=0;

    for i=1:objectsN
        objLums(1, :, i) = bars*(i-floor(objectsN/2))*amplitud + 127;
    end
end
