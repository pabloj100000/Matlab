function Tex = GetBarsTex(stimSize, barsWidth, Contrast)
    global screen
    Add2StimLogList();
    
    InitScreen(0);

    x = 0:stimSize-1;
    bars = ceil(mod(floor(x/barsWidth),2)*2*screen.gray*Contrast...
        + screen.gray*(1-Contrast));
    
    Tex{1} = Screen('MakeTexture', screen.w, bars);
end

