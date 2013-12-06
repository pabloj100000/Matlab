function showMask(screen, mask)
    text = Screen('MakeTexture', screen.w, mask(:,:,2));
    Screen('DrawTexture', screen.w, text);
    Screen('Close', text);
    Screen('Flip', screen.w);
    