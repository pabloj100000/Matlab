function Tex = GetCheckersTex(screen, stimSize, barsWidth)
    Add2StimLogList();
    
    if size(stimSize,2)==1
        [x, y]  = meshgrid(0:stimSize-1);
    else
        [x, y] = meshgrid(0:stimSize(1)-1, 0:stimSize(2)-1);
    end
    x = mod(floor(x/barsWidth),2);
    y = mod(floor(y/barsWidth),2);
    bars = x.*y + ~x.*~y;
    bars = bars*255;
    Tex = Screen('MakeTexture', screen.w, bars);
end

