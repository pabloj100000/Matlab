function run030911()
global pdStim screen

try
    CreateStimuliLogStart();
    
    
    % Define the rectangles
    [centerX, centerY] = Screen('WindowSize', max(Screen('Screens')));
    center1 =[centerX centerY]/2;
    objRect1 = GetRects(192, center1);
    
    
    Wait2Start('debugging',0)

    % record for 1000 + 500*2 + 7200 + 800 = 10000 seconds
    
    pdStim = 0;
%{
    pause(1)
    RF( ...
        'movieDurationSecs', 1000, ...
        'barsWidth',16, ...
        'objContrast',1, ...
        'waitFrames', 1 ...
        );

    

    pdStim = pdStim + 1;
    pause(1)
    backTex = GetCheckersTex(768, 8, screen, 1);
    UflickerObj2( ...
        'objContrast', [.12 1 .24 .06 .03], ...     % I put the contrasts in this order so that they will be shown (after randommization) in order of increasing contrast.
        'rects', objRect1, ...
        'backMode', [0 0 1 0], ...
        'backTexture', backTex, ...
        'objJitterPeriod', 100, ...
        'backJitterPeriod', 1, ...
        'backReverseFreq', 1, ...
        'presentationLength', 100, ...
        'movieDurationSecs', 500 ...
        );
%}    
    backTex = GetCheckersTex(768, 8, screen, 1);
    pdStim = pdStim + 1;
    pause(1)
    UflickerObj2( ...
        'objContrast', [.03 .06 .12 .24 1], ... 
        'rects', objRect1, ...
        'objJitterPeriod', 1, ...
        'backJitterPeriod', 1, ...
        'backMode', [0 0 1 0], ...
        'backReverseFreq', 1, ...
        'backTexture', backTex, ...
        'presentationLength', .5, ...
        'movieDurationSecs', 500 ...
        );

%}

    % some definitions needed for the natural scene stimuli
    objSize = 192;
    imSize = 768;
    textures = LoadAllTextures(0, '../Images/');
    maskTex = GetMaskTexture(imSize/2, objSize, screen, [6 12 18 24]);
    objSeed = 3;
    S1 = RandStream('mcg16807', 'Seed', objSeed);
    jitter = randi(S1, 3, 1, 60)-2;
    clear S1

    % Natural scene version of the ski doesn't dissapear. (800 secs total)
    objSeed = 3;
    objMode = 2;
    presentationsN = 400;
    pause(1)
    pdStim = pdStim+1;
    objSeed = JitterAllTextures(textures, maskTex, objSeed, ...
        presentationsN, jitter, objSize, imSize/2, objMode);


    % Natural scene version of gating with weak centers.
    pause(1)
    pdStim = pdStim+1;
    objMode = 1;
    presentationsN = 7200;
    objSeed = JitterAllTextures(textures, maskTex, objSeed, ...
        presentationsN, jitter, objSize, imSize/2, objMode);
        
    CreateStimuliLogWrite();

catch
    FinishExperiment();
    psychrethrow(psychlasterror);
end %try..catch..
end
    
function maskTex = GetMaskTexture(halfImageSize, objSize,  screen, alphaIn)
    % Create a single gaussian transparency mask and store it to a texture:
    % The mask must have the same size as the visible size of the grating
    % to fully cover it. Here we must define it in 2 dimensions and can't
    % get easily away with one single row of pixels.
    %
    % We create a  two-layer texture: One unused luminance channel which we
    % just fill with the same color as the background color of the screen
    % 'gray'. The transparency (aka alpha) channel is filled with a
    % gaussian (exp()) aperture mask:
    mask=ones(2*halfImageSize+1, 2*halfImageSize+1, 2) * screen.gray;
    [x,y]=meshgrid(-1*halfImageSize:1*halfImageSize,-1*halfImageSize:1*halfImageSize);
    % mask == 0 is opaque, mask == 255 is transparent
    maskTex = cell(1, length(alphaIn));
    for alphaOut=255:255:255
        for i = 1:length(alphaIn)
            mask(:, :, 2) = (abs(x)<objSize/2 & abs(y)<objSize/2)*(alphaIn(i)-alphaOut) + alphaOut;
            maskTex{i}=Screen('MakeTexture', screen.w, mask);
        end
    end
end