function FinishExperiment()
    % only execute this code if the calling function (the one above
    % this one in the stack) is the 1st function that initialized the
    % screen. 
    Add2StimLogList();
    
%{    
    s = dbstack('-completenames');
    if size(s,1)<=2
        
        Screen('CloseAll');         % Close all open onscreen and offscreen
        if  max(Screen('Screens'))==0
            button = questdlg('Save log file?','Finishing experiment', 'Yes');
            if (strcmp(button, 'Yes'));
                CreateStimuliLog();
            end
        end
    end
%}
    Screen('CloseAll');
    Priority(0);
    ShowCursor();
end



