function alphaTest2()
    % Have two textures (center and periphery)
    global screen
try    

    InitScreen(0);
    
    % Enable alpha-blending, set it to a blend equation useable for linear
    % superposition with alpha-weighted source. This allows to linearly
    % superimpose gabor patches in the mathematically correct manner, should
    % they overlap. Alpha-weighted source means: The 'globalAlpha' parameter in
    % the 'DrawTextures' can be used to modulate the intensity of each pixel of
    % the drawn patch before it is superimposed to the framebuffer image, ie.,
    % it allows to specify a global per-patch contrast value:
    Screen('BlendFunction', screen.w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

    % We create a Luminance+Alpha matrix for use as transparency mask:
    % Layer 1 (Luminance) is filled with luminance value 'gray' of the
    % background.
%    horiRadia=300;
%    vertRadia=100;
%    transLayer=2;
%    [x,y]=meshgrid(-vertRadia:vertRadia, -horiRadia:horiRadia);
%    maskblob=uint8(ones(2*horiRadia+1, 2*vertRadia+1, transLayer) * 128);


    % Layer 2 (Transparency aka Alpha) is filled with gaussian transparency
    % mask.
%    maskblob(:,:,transLayer)=uint8(sqrt((x/vertRadia).^2 + (y/horiRadia).^2)<1);
%    
    % Build a single transparency mask texture
%    masktex=Screen('MakeTexture', screen.w, maskblob);
%    maskSource=Screen('Rect', masktex);
%    maskDest = CenterRect(maskSource, screen.rect);
    
    mean1 = 127;
    contrast1 = 1;
    mean2 = 127;
    contrast2 = 1;
    waitframes=3;
    checkerSize = 16;
    
    objRect = SetRect(0,0, 32, 32)*checkerSize;
    objRect = CenterRect(objRect, screen.rect);

%    array = ones(32,32,2);
    array(:,:,1) = (rand(32, 32)>.5)*2*mean1*contrast1 + mean1*(1-contrast1);    
    objTex1  = Screen('MakeTexture', screen.w, array);

    array = (rand(2, 2)>.5)*2*mean1*contrast2 + mean2*(1-contrast2);
    array(:, :, 2) = 255;
    array(1, 1, 2) = 0;
    objTex2  = Screen('MakeTexture', screen.w, array);

    for frame=0:100
        % display last texture
%        Screen('DrawTexture', screen.w, objTex1, [], [], 0, 0);
        Screen('DrawTexture', screen.w, objTex1, [], objRect, 0, 0);
        
        % display last texture
        Screen('DrawTexture', screen.w, objTex2, [], objRect, 0, 0);

        
        %        Screen('FillOval', screen.w, color, pd);
        
        % uncomment this line to check the coordinates of the 1st checker
        % Flip 'waitframes' monitor refresh intervals after last redraw.
        screen.vbl = Screen('Flip', screen.w, screen.vbl + (waitframes-.5) * screen.ifi);

        if (KbCheck)
            break
        end
    end
 
    % We have to discard the noise checkTexture.
    Screen('Close', objTex1);
    Screen('Close', objTex2);
    clear screen
    clear global
    clear global expLog
    clear global screen
    clear global StimLogList
    
catch exception
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.
    CleanAfterError();
    rethrow(exception);
end %try..catch..end
