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
    Add2StimLogList();
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
