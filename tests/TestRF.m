function TestRF()
    global screen
    InitScreen(0)
    seed = 1;
    rect = GetRects(512, screen.center);
    for i=1:10
        [deltaT oneFrame seed]= RFframe(seed, 32, 32, 1);
        oneFrame = oneFrame*255;
        tex = Screen('MakeTexture', screen.w, oneFrame);
        Screen('DrawTexture', screen.w, tex, [], rect, 0, 0);
        Screen('Flip', screen.w);
    end
end