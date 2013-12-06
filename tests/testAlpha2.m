function testAlpha2()
    global screen
    
    InitScreen(0);
    Screen(screen.w,'BlendFunction',GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

    ms=100;
    transLayer=2;
    [x,y]=meshgrid(-ms:ms, -ms:ms);
    maskblob=uint8(ones(2*ms+1, 2*ms+1, transLayer) * 127);
    size(maskblob);
    
    % Layer 2 (Transparency aka Alpha) is filled with gaussian transparency
    % mask.
    xsd=ms/2.0;
    ysd=ms/2.0;
    maskblob(:,:,transLayer)=uint8(round(255 - exp(-((x/xsd).^2)-((y/ysd).^2))*255));

    masktex=Screen('MakeTexture', screen.w, maskblob);
    mRect=Screen('Rect', masktex);


    Screen('FillRect', screen.w, 0);
    Screen('DrawTexture', screen.w, masktex, [], mRect);
    Screen('Flip', screen.w);
    pause(1)
    
    Screen('FillRect', screen.w, 255);
    Screen('Flip', screen.w);
    pause(1)

    Screen 'CloseAll'
    clear global screen
end