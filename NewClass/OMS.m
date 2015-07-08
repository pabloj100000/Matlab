function newSeed = OMS(varargin)
% Wrapper to call JitterBackTex_JitterObjTex
%
% Divide the screen in object and background.
% Object will be a given texture changing phases every so often.
% Back will be a grating of a giving contrast and spatial frequency
% that reverses periodically at backReverseFreq.

global screen pd

p=ParseInput(varargin{:});

backContrast = p.Results.backContrast;
checkersSize = p.Results.checkersSize;
peripheryStep = p.Results.peripheryStep;
centerStep = p.Results.centerStep;
centerSize = p.Results.centerSize;
globalFlag = p.Results.globalFlag;
seed = p.Results.seed;

presentationLength = p.Results.presentationLength;
stimSize = p.Results.stimSize;
waitframes = p.Results.waitframes;

try
    InitScreen(0, 800, 600, 100);
    Add2StimLogList();
    
    % make the background texture
    checkersN = floor(stimSize/checkersSize)+2;         % make two checkers bigger than what will be seen
    stimSize = checkersSize * (checkersN);
    
    % make a texture with 2 more checker than what would be displayed
    [X, Y] = meshgrid(1:checkersN, 1:checkersN);
    Z = mod(X+Y+1,2)*screen.white;
    checkerTexture = Screen('MakeTexture', screen.w, Z);
    
    
    % Define the background Destination Rectangle, length is
    % (checkersN+2)*barsWIdth
    backDestOri = SetRect(0,0,stimSize, stimSize);
%    backDestOri = OffsetRect(backDestOri,screen.rect(1)+2*checkersSize,screen.rect(1)+2*checkersSize)  
    backDestOri = CenterRect(backDestOri, screen.rect);
    backDestOri = OffsetRect(backDestOri, -checkersSize, -checkersSize);
    
    % Define the source rectangle
    peripherySource = SetRect(0,0,checkersN, checkersN);

    centerSource = SetRect(0,0,centerSize+2, centerSize+2);
    centerDestori = SetRect(0, 0, (centerSize+2)*checkersSize, (centerSize+2)*checkersSize);
    centerDestOri = CenterRect(centerDestori, screen.rect);
    centerDestOri = OffsetRect(centerDestOri, -checkersSize, -checkersSize);
    
    centerMask = SetRect(0,0,centerSize*checkersSize, centerSize*checkersSize);
    centerMask = CenterRect(centerMask, screen.rect);
    
    peripheryMask = SetRect(0,0,(checkersN-2)*checkersSize, (checkersN-2)*checkersSize);
    peripheryMask = CenterRect(peripheryMask, screen.rect);
    
    % Define the PD box
    if exist('pd', 'var')==0 || isempty(pd)
        pd = DefinePD();
    end
    

    framesN = uint32(presentationLength*screen.rate/waitframes);
    if (mod(framesN,2))
        framesN = framesN+1;
    end

    offsetPeriphery = 0;
    offsetCenter = 0;
    
    % Get a random sequence representing FEM
    S1 = RandStream('mcg16807', 'Seed',seed);

    FEMcenter = randi(S1, 3, framesN, 1)-2;
    newSeed = S1.State;
    
    if (~globalFlag)
        FEMPeriphery = circshift(FEMcenter, double(framesN/2));
    else
        FEMPeriphery = FEMcenter;
    end
    
    
    % Animationloop:
    for frame=0:framesN-1
        Screen('FillRect', screen.w, screen.gray);
        
        % Offset peripherySource randomly according to back Step
        offsetPeriphery = mod(offsetPeriphery + FEMPeriphery(frame+1)*peripheryStep, 2*checkersSize);
        offsetCenter = mod(offsetCenter + (FEMcenter(frame+1))*centerStep, 2*checkersSize);

        peripheryDest = backDestOri + offsetPeriphery*[1 0 1 0];
        centerDest = centerDestOri + offsetCenter*[1 0 1 0];
        
        % Draw the center
        % Disable alpha-blending, restrict following drawing to alpha channel:
        Screen('Blendfunction', screen.w, GL_ONE, GL_ZERO, [0 0 0 1]);
        
        % Clear 'dstRect' region of framebuffers alpha channel to zero:
        % Disable drawing everywhere
        Screen('FillRect', screen.w, [0 0 0 0], screen.rect);
        
        % Fill circular 'dstRect' region with an alpha value of 255: Next
        % Drawing will only affect pixels with alph=255        
        Screen('FillRect', screen.w, [0 0 0 255], peripheryMask);

        % Enable DeSTination alpha blending and reenalbe drawing to all
        % color channels. Following drawing commands will only draw there
        % the alpha value in the framebuffer is greater than zero, ie., in
        % our case, inside the circular 'dst2Rect' aperture where alpha has
        % been set to 255 by our 'FillOval' command:
        Screen('Blendfunction', screen.w, GL_DST_ALPHA, GL_ONE_MINUS_DST_ALPHA, [1 1 1 1]);

        % Draw 2nd grating texture, but only inside alpha == 255 circular
        % aperture:
        % Background Drawing
        Screen('DrawTexture', screen.w, checkerTexture, peripherySource, peripheryDest, 0,0);

        % Disable alpha-blending, restrict following drawing to alpha channel:
        Screen('Blendfunction', screen.w, GL_ONE, GL_ZERO, [0 0 0 1]);

        % Clear 'dstRect' region of framebuffers alpha channel to zero:
        Screen('FillRect', screen.w, [0 0 0 0], peripheryMask);

        Screen('FillRect', screen.w, [0 0 0 255], centerMask);
        
        % Enable DeSTination alpha blending and reenalbe drawing to all
        % color channels. Following drawing commands will only draw there
        % the alpha value in the framebuffer is greater than zero, ie., in
        % our case, inside the circular 'dst2Rect' aperture where alpha has
        % been set to 255 by our 'FillOval' command:
        Screen('Blendfunction', screen.w, GL_DST_ALPHA, GL_ONE_MINUS_DST_ALPHA, [1 1 1 1]);
        
        % Draw 2nd grating texture, but only inside alpha == 255 circular
        % aperture:
        Screen('DrawTexture', screen.w, checkerTexture, centerSource, centerDest, 0, 0);
        
        % Restore alpha blending mode for next draw iteration:
        Screen('Blendfunction', screen.w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        
        % Draw PD
        if (frame==0)
            pdColor = 255;
        else
            pdColor = FEMcenter(frame+1)*50 + 127;
        end
        
        Screen('FillOval', screen.w, pdColor, pd); 
        % Flip 'waitframes' monitor refresh intervals after last redraw.
        screen.vbl = Screen('Flip', screen.w, screen.vbl + (waitframes - 0.5) * screen.ifi);
        if KbCheck
            break
        end
    end
    
    
    % After drawing, we have to discard the noise checkTexture.
    Screen('Close', checkerTexture);
    Screen('CloseAll');

    FinishExperiment();
    
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
p  = inputParser;   % Create an instance of the inputParser class.

rate = Screen('NominalFrameRate', max(Screen('Screens')));
if (rate==0)
    rate=100;
end

% General
p.addParamValue('presentationLength', 30, @(x)x>0);
p.addParamValue('stimSize', 32*PIXELS_PER_100_MICRONS, @(x)x>0);
p.addParamValue('debugging', 0, @(x)x>=0 && x <=1);
p.addParamValue('waitframes', round(rate/30), @(x)x>0);
p.addParamValue('pdStim', 1, @(x) isnumeric(x));
p.addParamValue('globalFlag', 1, @(x) x==0 || x==1);
p.addParamValue('seed', 1, @(x) isnumeric(x));

% Background related
p.addParamValue('backContrast', 1, @(x)x>=0 && x<=1);
p.addParamValue('backReverseFreq', 1, @(x) x>0);
p.addParamValue('peripheryStep', 1, @(x) x>=0);
p.addParamValue('centerStep', 1, @(x) x>=0);
p.addParamValue('centerSize', 8, @(x) x>=0);
p.addParamValue('checkersSize', PIXELS_PER_100_MICRONS, @(x) x>0);


% Call the parse method of the object to read and validate each argument in the schema:
p.parse(varargin{:});

end


