function pink = GetPinkNoise(startFrame, framesN, contrast, meanLuminance, plotFlag)
    % Generate a noise wave with 'pink like characterisitics'
    %
    %   Start by loading matlab's pink noise sequence and then adjust the
    %   scaling to have contrast and meanLuminance.
    
    Add2StimLogList();
    
    load pinknoise;
    x(1:startFrame)=[];
    x(framesN+1:end)=[];

    Xstd = std(x);
    pink = x*contrast*meanLuminance/Xstd + meanLuminance;    
    
    if plotFlag
        figure(1)
        plot(pink, 'r')
        figure(2)
        AnalyseNoise(pink)
    end
end
