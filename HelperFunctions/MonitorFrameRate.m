function frameRate = MonitorFrameRate
    Add2StimLogList();
    
    frameRate = Screen('NominalFrameRate', max(Screen('Screens')));
    if frameRate==0
        frameRate=60;
    end
end
