function MessageScreen(message)
% Display message and wait for spaceBar to continue
    global screen
    Add2StimLogList();
    InitScreen(0);
 
    KbName('UnifyKeyNames');
    ESCAPE = KbName('Escape');
%    SPACEBAR = KbName('space');
            
    Screen('FillRect', screen.w, 128);
    Screen(screen.w,'TextSize', 24);
    
    
    text2 = 'Press ''Esc'' to continue';
    
    Screen(screen.w, 'DrawText', message ,30,30, 0 );
    Screen(screen.w, 'DrawText', text2 ,30,60, 0 );
    screen.vbl = Screen('Flip',screen.w);

%

%    ListenChar(2)
    while (1)       % if only one monitor
        [~, ~, keyCode, ~] = KbCheck;
        if (keyCode(ESCAPE))
            pause(.2);
            break;
        end
    end
    
    FinishExperiment;
%    ListenChar(0)
end

