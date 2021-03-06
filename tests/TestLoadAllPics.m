function TestLoadAllPics()
    global screen
    
    texts = LoadAllPics(0);
    vbl = Screen('Flip', screen.w);
    
    % Get 1sec random jitter (60 frames per sec)
    S1 = RandStream('mcg16807', 'Seed', 1);
    jitter = randi(S1, 3, 1, 60)-2;
    clear S1

    imSize = 400;      % half the size of each image
    maskSize = 200;
    drawMask=1;

    % Create a single gaussian transparency mask and store it to a texture:
    % The mask must have the same size as the visible size of the grating
    % to fully cover it. Here we must define it in 2 dimensions and can't
    % get easily away with one single row of pixels.
    %
    % We create a  two-layer texture: One unused luminance channel which we
    % just fill with the same color as the background color of the screen
    % 'gray'. The transparency (aka alpha) channel is filled with a
    % gaussian (exp()) aperture mask:
    mask=ones(2*imSize+1, 2*imSize+1, 2) * screen.gray;
    [x,y]=meshgrid(-1*imSize:1*imSize,-1*imSize:1*imSize);
    mask(:, :, 2) = screen.white * (exp(-((x/maskSize).^2)-((y/maskSize).^2)));
    maskTex=Screen('MakeTexture', screen.w, mask);


    
    destRectOri = [0 0 1000 800];
    sourceRect = [0 0 300 300];
    angle = 0;
%    while  ~KbCheck
%        i=1;
%        frame=1;
    for i=1:length(texts)
        destRect = destRectOri;
        for frame = 1:60
            destRect = destRect + jitter(frame)*[1 0 1 0];
            
            if (drawMask)

                % Disable alpha-blending, restrict following drawing to alpha channel:
                Screen('Blendfunction', screen.w, GL_ONE, GL_ZERO, [0 0 0 1]);
                
                % Clear 'dstRect' region of framebuffers alpha channel to zero:
                %        Screen('FillRect', screen.w, [0 0 0 0], backRect);
                Screen('FillRect', screen.w, [0 0 0 0], destRect);
                
                % Fill circular 'dstRect' region with an alpha value of 255:
                Screen('DrawTexture', screen.w, maskTex,[],destRect);
                
                % Enable DeSTination alpha blending and reenalbe drawing to all
                % color channels. Following drawing commands will only draw there
                % the alpha value in the framebuffer is greater than zero, ie., in
                % our case, inside the circular 'dst2Rect' aperture where alpha has
                % been set to 255 by our 'FillOval' command:
                Screen('Blendfunction', screen.w, GL_DST_ALPHA, GL_ONE_MINUS_DST_ALPHA, [1 1 1 1]);
                
                % Draw 2nd grating texture, but only inside alpha == 255 circular
                % aperture, and at an angle of 90 degrees:
                Screen('DrawTexture', screen.w, texts{i}, sourceRect, destRect, angle);

                % Restore alpha blending mode for next draw iteration:
                Screen('Blendfunction', screen.w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
            else
                Screen('DrawTexture', screen.w, texts{i}, sourceRect, destRect, angle);
            end                

            vbl = Screen('Flip', screen.w, vbl);
        end
    end
    
    clear global screen
    Screen closeAll
end


