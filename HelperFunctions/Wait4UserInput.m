function selection = Wait4UserInput(values)
    global screen
    Add2StimLogList();
    
    KbName('UnifyKeyNames');
    ESCAPE = KbName('escape');
    text1 = 'Select with the mouse your choice';
    
    Screen('FillRect', screen.w, screen.gray);
    Screen(screen.w, 'DrawText', text1 ,30,30, 0 );

    objRect = SetRect(0, 0, 100, 100);
    x0 = 50;
    y0 = 70;

    ShowCursor();
    for i=1:length(values)
        textX = x0+100*(i-1);
        textY = y0;
        Screen(screen.w, 'DrawText', num2str(values(i)) ,textX, textY, 0);
    end
    
    Screen('Flip', screen.w)

    while (1)
        [x,y,buttons] = GetMouse(screen.w);
        [~, ~, keyCode, ~] = KbCheck;
        if (keyCode(ESCAPE))
            break
        end
        if buttons(1)
            x = floor(x/100);
            y = floor((y-y0)/100);
            if (x < length(values));
                selection = values(x+1);
                break
            end
        end
    end
    
    HideCursor();
end
