function MaskHiDensArray(screen, array_name)
    % Paint all screen in black except the center rectangle defined by 
    % 'array_name'
    % array_name should be one of {
    
    Add2StimLogList();
    array_mask = GetRect(array_name);
    % Draw a black mask around peri_rect to prevent illuminating the
    % electronics
    % Restrict drawing to the alpha channel
    Screen('Blendfunction', screen.w, GL_ONE, GL_ZERO, [0 0 0 1]);
    % set alpha = 255 everywhere and then to 0 inside peri_rect
    Screen('FillRect', screen.w, [0 0 0 255]);
    Screen('FillRect', screen.w, [0 0 0 0], array_mask);
    % Enable alpha blending
    Screen('Blendfunction', screen.w, GL_DST_ALPHA, GL_ONE_MINUS_DST_ALPHA, [1 1 1 1]);
    % For some reason if I draw to the whole it doesn't work.
    Screen('FillRect', screen.w, [0 0 0], [0 0 1400 900]);
    
    
    % Restore alpha blending mode for next draw iteration:
    Screen('Blendfunction', screen.w, GL_ONE, GL_ZERO, [1 1 1 1]);
