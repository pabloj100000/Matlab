function texture = maskMatrix(matrix, radia, saccadeSize, mode)
    % Given a matrix, generate a texture that has matrix everywhere except
    % in the mask (which depends on mode). The mask is the superposition of
    % 2 circles and a rectangle. The rectangle is centered on the screen 
    % and has height radia and width saccadeSize, the circles are centerd
    % at +- [saccadeSize/2 0] + screen.center and have radia = "radia"
    % mode: 0   periphery textures, mask out the inside of the rectangle 
    %           and circles
    % mode: 1   object textures, mask out the outside of the rectangle 
    %           and circles
    
    global screen

    InitScreen(0);
    Add2StimLogList;
    
    % Enable alpha-blending, set it to a blend equation useable for linear
    % superposition with alpha-weighted source. This allows to linearly
    % superimpose gabor patches in the mathematically correct manner, should
    % they overlap. Alpha-weighted source means: The 'globalAlpha' parameter in
    % the 'DrawTextures' can be used to modulate the intensity of each pixel of
    % the drawn patch before it is superimposed to the framebuffer image, ie.,
    % it allows to specify a global per-patch contrast value:
    Screen('BlendFunction', screen.w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

    [width height] = size(matrix);
    [x, y] = meshgrid(1:width, 1:height);
    mask = ((x-width/2-saccadeSize/2).^2 + (y-height/2).^2>radia^2);
    mask = mask.*((x-width/2+saccadeSize/2).^2 + (y-height/2).^2>radia^2);
    mask = mask.*((abs(x-width/2)>saccadeSize/2) | (abs(y-height/2)>radia));
    mask = mask*255;

    % Generate Peripheral texture 
    if (mode)
        matrix(:,:,2) = 255-mask;
    else
        matrix(:,:,2) = mask;
    end
    
    texture  = Screen('MakeTexture', screen.w, matrix);
end

