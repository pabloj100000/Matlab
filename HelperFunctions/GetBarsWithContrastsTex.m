function Tex = GetBarsWithContrastsTex(stimSize, screen, Contrasts)
% Usage: Tex = GetCheckersTex(stimSize, barsWidth, screen, Contrast)
    Add2StimLogList();
    
    x = 0:stimSize-1;
    x = mod(x,2);
    bars = ones(length(Contrasts), stimSize);
    bars = Contrasts'*x*2*screen.gray...
            + screen.gray*(1-Contrasts)'*ones(1, stimSize);
%{
    for i=1:length(Contrasts)
        bars(i, :) = Contrasts(i)*x*2*screen.gray*...
            + screen.gray*(1-Contrasts(i));
    end
    %}
            Tex{1} = Screen('MakeTexture', screen.w, bars);
end

