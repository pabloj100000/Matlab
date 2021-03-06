function OMS_identifier_LD(varargin)
% Wrapper to call JitterBackTex_JitterObjTex
%
% Divide the screen in object and background.
% Object will be a given texture changing phases every so often.
% Back will be a grating of a giving contrast and spatial frequency
% that reverses periodically at backReverseFreq.

global screen pd

p=ParseInput(varargin{:});

backContrast = p.Results.backContrast;
barsWidth = p.Results.barsWidth;

presentationLength = p.Results.presentationLength;
stimSize = p.Results.stimSize;
waitframes = p.Results.waitframes;

try
    InitScreen(0);
    Add2StimLogList();
      
    % make the background texture
    barsN = floor(stimSize/barsWidth)+1;
    stimSize = barsWidth * (barsN-1);
    
    x= 0:barsN;
    bars = ceil(mod(x,2)*2*screen.gray*backContrast...
        + screen.gray*(1-backContrast));
    backTex = Screen('MakeTexture', screen.w, bars);
    
    % Define the background Destination Rectangle, length is
    % (barsN-1)*barsWIdth
    backRect = SetRect(0,0,stimSize, stimSize);
    backRect = CenterRect(backRect, screen.rect);
    
    % Define the back source rectangle
    backSource1 = SetRect(0,0,barsN-1,1);
    backSource2 = SetRect(1,0,barsN, 1);
    
    
    %stimSize    % in pixels
    objSize = 8*PIXELS_PER_100_MICRONS; % in pixels
    %cetnerX     % in pixels
        
    % define the obj rect. Center of the rect is in the upper left corner of the array
    objRect = SetRect(0, 0, 8*PIXELS_PER_100_MICRONS, 8*PIXELS_PER_100_MICRONS);
    objRect = CenterRect(objRect, screen.rect);
    objRect = OffsetRect(objRect, -2*PIXELS_PER_100_MICRONS, -2*PIXELS_PER_100_MICRONS);
    
    % obj source
    objSource = SetRect(-1, -1, 1, 1)* (barsN-1)*objSize/stimSize/2;%*PIXELS_PER_100_MICRONS, 8*PIXELS_PER_100_MICRONS)*(barsN-1)/stimSize;
    objSource1(1, :) = CenterRect(objSource, (barsN-1)/2-2*PIXELS_PER_100_MICRONS*(barsN-1)/stimSize*[1 0 1 0]);     %objSource + [1 0 1 0]*(1/2 - .75*objSize/stimSize);
    objSource1(2, :) = objSource1(1,:)+4*PIXELS_PER_100_MICRONS*(barsN-1)/stimSize*[1 0 1 0];
    objSource = objSource1(1, :);
    
    % Define the PD box
    if exist('pd', 'var')==0 || isempty(pd)
        pd = DefinePD();
    end

    framesN = uint32(presentationLength*screen.rate/waitframes);
    jumpFrames = 2*round(screen.rate/waitframes/2);     % every 0.5s
    framesN = jumpFrames*floor(framesN/jumpFrames);

    % Animationloop:
    for trial=1:2
        for i=0:4        % i=0 Global Motion, i=1:4 DIfferential
            for frame=0:framesN-1
                % Background Drawing
                % ---------- -------
                if mod(frame, 2*jumpFrames)==0
                    backSource = backSource1;
                elseif mod(frame, jumpFrames)==0
                    backSource = backSource2;
                end
                Screen('DrawTexture', screen.w, backTex, backSource, backRect, 0,0);
                
                
                
                % Object Drawing
                % --------------
                if (i>0)
                    if mod(frame+jumpFrames/2, 2*jumpFrames)==0
                        index = mod(i, 2);
                        if index==0
                            index=2;
                        end
                        objSource = objSource1(index, :);
                    elseif mod(frame+jumpFrames/2, jumpFrames)==0
                        objSource = objSource + [1 0 1 0];
                    end
                    Screen('DrawTexture', screen.w, backTex, objSource, objRect, 0,0);
                        
                    %        Screen('DrawTexture', screen.w, objTex, objSource + objShiftRect, objRect, 0,0);
                end
%}                
                % Photodiode box
                % --------------
                if (mod(frame, jumpFrames)==0 || (i>0 && mod(frame, jumpFrames/2)==0))
                    Screen('FillOval', screen.w, screen.white, pd);
                end
                
                % Flip 'waitframes' monitor refresh intervals after last redraw.
                screen.vbl = Screen('Flip', screen.w, screen.vbl + (waitframes - 0.5) * screen.ifi);
                if KbCheck
                    break
                end
            end
            if KbCheck
                break
            end
            
% {
            if (i==0)
                % do nothing
            elseif (i==2)
            % move object down and left
                objRect = OffsetRect(objRect, -4*PIXELS_PER_100_MICRONS, 4*PIXELS_PER_100_MICRONS);
            elseif (i==4)
                % move object up and left
                objRect = OffsetRect(objRect, -4*PIXELS_PER_100_MICRONS, -4*PIXELS_PER_100_MICRONS);
            else
                % move object to the right
                objRect = OffsetRect(objRect, 4*PIXELS_PER_100_MICRONS, 0);
            end
%}            
        end
    end
    
    % After drawing, we have to discard the noise checkTexture.
    Screen('Close', backTex);

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
    p.addParamValue('presentationLength', 10, @(x)x>0);
    p.addParamValue('stimSize', 32*PIXELS_PER_100_MICRONS, @(x)x>0);
    p.addParamValue('debugging', 0, @(x)x>=0 && x <=1);
    p.addParamValue('waitframes', round(rate/30), @(x)x>0);
    p.addParamValue('pdStim', 1, @(x) isnumeric(x));
    
    % Background related
    p.addParamValue('backContrast', 1, @(x)x>=0 && x<=1);
    p.addParamValue('backReverseFreq', 1, @(x) x>0);
    p.addParamValue('barsWidth', PIXELS_PER_100_MICRONS, @(x) x>0);

    
    % Call the parse method of the object to read and validate each argument in the schema:
    p.parse(varargin{:});
    
end


