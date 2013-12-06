function DisplayGabor(gabor, center)
    % calling function should set
    %      Screen(screen.w,'BlendFunction',GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    % see for example GetGaborTex and TestGetGabor
    % gabor should have following fields 
    %   
    %   gabor.size = 100;
    %   gabor.period = 10;                            % number of pixels per period
    %   gabor.sigma = 10;                             % gaussian standard deviation in pixels
    %   gabor.phase = .0;                             % gabor.phase (0 -> 2?)
    %   gabor.contrast = 1; 
    %   gabor.mean = 127;                             % mean luminance of patch
    %   gabor.tex = GetGaborFromStruct                % textured to be displed
    %   gabor.mask = GetGaborMaskFromStruct                % mask to be displed
    global screen

    Add2StimLogList();

    % change size
    gaborRect = Screen('Rect', gabor.tex);
    destRect = centerRectOnPoint(gaborRect, center(1), center(2));
    Screen('DrawTexture', screen.w, gabor.tex, [], destRect)
end
