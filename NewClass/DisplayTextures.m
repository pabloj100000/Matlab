function DisplayTextures()
    global screen
try
    InitScreen(0)
    Add2StimLogList();

    % Define some variables
    stimSize=768;
    lastTrial = 50;
    saccadeRate = 1;
    objSeq = [0 1 2 3 0 2 0 3 1 3 3 2 2 1 1 0];
    objSeqLength = length(objSeq);
    periSeq = [0 1 2 3 4 0 2 4 1 3 0 3 1 4 2 0 4 3 2 1 0];
    periSeqLength = length(periSeq);
    objDelta = 10;
    images2load = [23 32 39 19 69];%57 69 70];

    objSize = 12*PIXELS_PER_100_MICRONS;
    
    % Define the rectangles
    periSourceRect = SetRect(0, 0, stimSize, stimSize);
    periDestRect = CenterRect(periSourceRect, screen.rect);
    
    objSourceRect = SetRect(0, 0, objSize, objSize);
    objSourceRect = CenterRect(objSourceRect, periSourceRect);
    objDestRect = CenterRect(objSourceRect, screen.rect);
    
    textures = LoadAllTextures(images2load, [stimSize stimSize]);

    pd = DefinePD;
    
    waitFrames = 2;
    framesPerSaccade = screen.rate/saccadeRate/2/waitFrames;
    
    imagesPerTrial = objSeqLength*periSeqLength;
    for trial = 1:lastTrial
        for im = 1:imagesPerTrial
            for frame=1:framesPerSaccade;
                objIndex = mod(im-1, objSeqLength)+1;
                object = objSeq(objIndex)+1;
                periIndex = mod(im-1, periSeqLength)+1;
                peri = periSeq(periIndex)+1;
                objLum = 127+objSeq(object)*objDelta-25;
                periLum = 0;
                objAlpha = 0;
                periAlpha = 1;
                objTex = textures{1};
                periTex = textures{peri};

                LocalDisplayTextures(screen.w, objTex, objLum, objAlpha, objSourceRect, objDestRect, ...
                periTex, periLum, periAlpha, periSourceRect, periDestRect)

                if (frame==1)
                    pdColor = 255;
                else
                    pdColor = objLum;
                end
                
                Screen('FillOval', screen.w, pdColor, pd);
                screen.vbl = Screen('Flip', screen.w, screen.vbl+(waitFrames-.5)*screen.ifi);

                text = sprintf('obj: %d,\t peri: %d,cycle: %d/%d\ttrial: %d/%d', objIndex, periIndex, im, imagesPerTrial, trial, lastTrial);

                Screen('DrawText', screen.w, text, 0, 0, 0);
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
    for i=1:length(textures)
        Screen('Close', textures{i});
    end
    FinishExperiment();

catch exception
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.
    CleanAfterError();
    rethrow(exception);
end %try..catch..end
end

function LocalDisplayTextures(winPointer, objTex, objLum, objAlpha, objSourceRect, objDestRect, ...
    periTex, periLum, periAlpha, periSourceRect, periDestRect)
% THis is going to be a somewhat complicated function that will be called
% from whithin other wrappers.
%
% There are several things i want to accomplish with this function
% 1. There will be a periphery and an object each defined by a rect, a
% luminance value, an alpha value and a texture.
% 2. I will enable alpha blending and for each region I will display first
% the corresponding luminance value and then the texture at its alpha value
try    

    Add2StimLogList;
    
    % Draw peri luminance values
    Screen('FillRect', winPointer, periLum, periDestRect);

    % enable alpha blending
    Screen('BlendFunction', winPointer, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    
    % draw peri textures
    Screen('DrawTexture', winPointer, periTex, periSourceRect, periDestRect, 0, 0, periAlpha);

    
    Screen('FillRect', winPointer, objLum, objDestRect);
    Screen('DrawTexture', winPointer, objTex, objSourceRect, objDestRect, 0, 0, objAlpha);
        
catch exception
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.
    CleanAfterError();
    rethrow(exception);
end %try..catch..end
end
