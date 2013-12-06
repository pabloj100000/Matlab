function testMask(screen, text1)
    
    mask = ones(513, 513, 2)*screen.gray;
    [x y] = meshgrid(-256:256, -256:256);
    radia = 50;
    for alphaOut = 0:255:255
        for alphaIn = 50:50:255
            mask(:,:,2) = alphaOut;
            mask(:, :, 2) = ((x.^2+y.^2)<radia^2)*(alphaIn-alphaOut) + alphaOut;
            text2 = Screen('MakeTexture', screen.w, mask);

            displayMasks(screen, text1, text2);
            Screen('Close', text2);
            pause(1)
        end
    end    
end

function displayMasks(screen, text1, text2)
    Screen('FillRect', screen.w, screen.gray);
    
     % Disable alpha-blending, restrict following drawing to alpha channel:
    Screen('Blendfunction', screen.w, GL_ONE, GL_ZERO, [0 0 0 1]);

    % Clear 'dstRect' region of framebuffers alpha channel to zero:
    %        Screen('FillRect', screen.w, [0 0 0 0], backRect);
    Screen('FillRect', screen.w, [0 0 0 0], screen.rect);

    % Fill circular 'dstRect' region with an alpha value of 255:
    Screen('DrawTexture', screen.w, text2,[],screen.rect);

    % Enable DeSTination alpha blending and reenalbe drawing to all
    % color channels. Following drawing commands will only draw there
    % the alpha value in the framebuffer is greater than zero, ie., in
    % our case, inside the circular 'dst2Rect' aperture where alpha has
    % been set to 255 by our 'FillOval' command:
    Screen('Blendfunction', screen.w, GL_DST_ALPHA, GL_ONE_MINUS_DST_ALPHA, [1 1 1 1]);

    % Draw 2nd grating texture, but only inside alpha == 255 circular
    % aperture, and at an angle of 90 degrees:
    Screen('DrawTexture', screen.w, text1);
    
    % Restore alpha blending mode for next draw iteration:
    Screen('Blendfunction', screen.w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

    Screen('Flip', screen.w);
end
