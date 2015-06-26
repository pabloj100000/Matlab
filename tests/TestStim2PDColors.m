function TestStim2PDColors(stim_number, base, digits, waitframes)

global screen pd

try
    InitScreen(0);
    Add2StimLogList();
    
    % Define the PD box
    if exist('pd', 'var')==0 || isempty(pd)
        pd = DefinePD();
    end
    
    Wait2Start();
    
    framesN = 10 * screen.rate/waitframes;       % # of frames for 10 s stimulus

    pd_colors = stim2pdColors(stim_number, base, digits);
    
    % Animationloop:
    for frame=0:framesN-1
        Screen('FillRect', screen.w, screen.gray);
        DrawMultiLineComment(screen, {int2str(frame)});
        % Draw PD
        if (frame==0)
            pdColor = 255;
        elseif (frame <= digits)
            pdColor = pd_colors(frame)*255/(base+1);
        else
            pdColor = rand(1)*255;
        end
        
        Screen('FillOval', screen.w, pdColor, pd); 
        % Flip 'waitframes' monitor refresh intervals after last redraw.
        screen.vbl = Screen('Flip', screen.w, screen.vbl + (waitframes - 0.5) * screen.ifi);
        if KbCheck
            break
        end
    end
    
    FinishExperiment();
    
catch
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.
    CleanAfterError();
    psychrethrow(psychlasterror);
end %try..catch..
end



