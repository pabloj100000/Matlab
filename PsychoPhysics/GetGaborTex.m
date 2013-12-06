function gabor = GetGaborTex(gabor)
    % For usage with DisplayGaborStruct
    %     Screen(screen.w,'BlendFunction',GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    % has to be enabled

    % Changing phase and/or mean are not working well, for an example, try
    % period=100, sigma=50, phase = 3*pi/2, contrast=1,
    % mean=127
    
    global screen
    Add2StimLogList();
    
    % gabor should have teh following fields
    %   gabor.size
    %   gabor.period = 10;                            % number of pixels per period
    %   gabor.sigma = 10;                             % gaussian standard deviation in pixels
    %   gabor.phase = .0;                             % gabor.phase (0 -> 2?)
    %   gabor.contrast = 1; 
    %   gabor.mean = 127;                             % mean luminance of patch
    %   gabor.tex
    s0 = gabor.size/2;
    
    [x,y]=meshgrid(-s0:s0, -s0:s0);
    maskblob=uint8(ones(2*s0+1, 2*s0+1, 2));

    % Layer 1 (Sigmoid with the given freq and phase
    freq = 2*pi/gabor.period;                    % compute frequency from wavelength
    maskblob(:,:,1) = sin( x*freq + gabor.phase)*gabor.contrast*gabor.mean+gabor.mean;

    % Layer 2 (Transparency aka Alpha) is filled with gaussian transparency
    % mask.
    sd = gabor.sigma;
    maskblob(:,:,2)=uint8(exp(-((x/sd).^2)-((y/sd).^2))*255);

    if isfield(gabor, 'tex') && ~isempty(gabor.tex)
        Screen('Close', gabor.tex)
    end
    gabor.tex=Screen('MakeTexture', screen.w, maskblob);
end

