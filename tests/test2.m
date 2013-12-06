function test2()
    global screen

    pdStim = 0;
    
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
    %pause(1)
    pdStim = pdStim+1;
    objSeed = JitterAllTextures(textures, maskTex, objSeed, ...
        presentationsN, jitter, objSize, imSize/2, objMode);

    % Natural scene version of gating with weak centers.
    %pause(1)
    pdStim = pdStim+1;
    objMode = 1;
    presentationsN = 7200;
    objSeed = JitterAllTextures(textures, maskTex, objSeed, ...
        presentationsN, jitter, objSize, imSize/2, objMode);
    
    Screen ('closeAll')
    clear global

end

function nextSeed = JitterAllTextures(textures, maskTex, objSeed, ...
    presentationsN, jitter, objSize, halfImageSize, objMode)
    % this proceure will mimic saccade and jitters.
    % The random jitter sequence comes in through 'jitter' which also sets
    % the framesN = length(jitter). At the beginning of every jitter a
    % saccade is simulated by choosing a new texture out of 'textures'.
    % MaskTex defines how opaque or transparent the center is.
    %
    % objMode lets you select between different object modes
    %   mode 0:     center mode is identical to background
    %   mode 1:     center is somewhat transparent/opaque as defined by the
    %               mask that would be used.
    %   mode 2:     center is uniform filed of constant intensity given by
    %               objColor.
    global screen pdStim vbl
    
tic
    if (isempty(pdStim))
        pdStim=0;
    end
    
    if (isempty(vbl))
        vbl=0;
    end
    
    framesN = length(jitter);
  
    
    % Define the PD box
    pd = SetRect(0,0, 100, 100);
    pd = CenterRectOnPoint(pd, screen.rect(3)*.95, screen.rect(4)*.15);

    % Get rect for objMode=2
    objRectOri = SetRect(0,0,objSize,objSize);
    objRectOri = CenterRect(objRectOri, screen.rect);
    
    % Get order of images and masks
    S1 = RandStream('mcg16807', 'Seed',objSeed);
    order=randperm(S1, presentationsN);
    imOrder = mod(order, length(textures))+1;
    maskOrder = mod(order, length(maskTex))+1;
    nextSeed = S1.State;
    
%    destRectOri = [0 0 2*halfImageSize-1 2*halfImageSize-1];
    destRectOri = GetRects(2*halfImageSize, [screen.rect(3) screen.rect(4)]/2);
    sourceRectOri = [0 0 2*halfImageSize-1 2*halfImageSize-1];

    % define some constants
    angle = 0;    
    Screen('TextSize', screen.w,12);
    colorCh = floor(presentationsN/8);
    
toc    
    for i=1:presentationsN
        destRect = destRectOri;
        sourceRect = sourceRectOri;
        objRect = objRectOri;
        for frame = 0:framesN-1    % for every frame
            destRect = destRect + jitter(frame+1)*[1 0 1 0];
            objRect = objRect + jitter(frame+1)*[1 0 1 0];
            
            switch objMode
                case 0
                    Screen('DrawTexture', screen.w, textures{imOrder(i)}, sourceRect, destRect, angle);
                case 1
                    % Disable alpha-blending, restrict following drawing to alpha channel:
                    Screen('Blendfunction', screen.w, GL_ONE, GL_ZERO, [0 0 0 1]);
                    
                    % Clear 'dstRect' region of framebuffers alpha channel to zero:
                    Screen('FillRect', screen.w, [0 0 0 0], destRect);
                    
                    % Write value of alpha channel and RGB according to our mask
                    Screen('DrawTexture', screen.w, maskTex{maskOrder(i)},[],destRect);
                    
                    % Enable DeSTination alpha blending and reenalbe drawing to all
                    % color channels. Following drawing commands will only draw there
                    % the alpha value in the framebuffer is greater than zero, ie., in
                    % our case, inside the circular 'dst2Rect' aperture where alpha has
                    % been set to 255 by our 'FillOval' command:
                    Screen('Blendfunction', screen.w, GL_DST_ALPHA, GL_ONE_MINUS_DST_ALPHA, [1 1 1 1]);
                    
                    % Draw 2nd texture
                    Screen('DrawTexture', screen.w, textures{imOrder(i)}, sourceRect, destRect, angle);
                    
                    % Restore alpha blending mode for next draw iteration:
                    Screen('Blendfunction', screen.w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
                case 2
                    objColor = 85*mod(floor((i-1)/colorCh),4);
                    Screen('DrawTexture', screen.w, textures{imOrder(i)}, sourceRect, destRect, angle);
                    Screen('FillRect', screen.w, objColor, objRect);
                    
            end
            
            Screen('DrawText', screen.w, ['presentatin = ',num2str(i)], 20,20, screen.black);
            Screen('DrawText', screen.w, ['image = ',num2str(imOrder(i))], 20,40, screen.black);
            Screen('DrawText', screen.w, ['mask = ', num2str(maskOrder(i))] , 20,60, screen.black);

            % Photodiode box
            % --------------
            DisplayStimInPD2(pdStim, pd, frame, 60, screen)

            vbl = Screen('Flip', screen.w, vbl);
            if (KbCheck)
                break
            end
        end
        if (KbCheck)
            break
        end
    end
end


function Textures = LoadAllTextures(debugging, varargin)
    global screen
    if (nargin==1)
        folder = '../Images/';
    else
        folder = varargin{1};
    end
    
    InitScreen(debugging);
    files = dir(folder);
    textN = 0;
    Textures = cell(1, size(files,1)-2);        % -2 because "." and ".." are always present
    for i=1:size(files,1)   % for every file
        [~, ~, ext] = fileparts(files(i).name);
        if strcmpi(ext, '.jpg')
            % load the image
            im = imread([folder,files(i).name]);
            % make a texture
            textN = textN + 1;
            Textures{textN} = Screen('MakeTexture', screen.w, im);
        end
    end
    % if there are empty elements in Textures, delete them
    if (length(Textures) > textN)
        Textures(textN+1:end) = [];
    end
end

