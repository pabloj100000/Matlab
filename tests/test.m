function test()
    global screen
    
    % process Input variables
    InitScreen()
    % I want framesN to have an even number of background reversals
    % 
    updateTime = 1/screen.rate-1/screen.rate/2;

    screen.vbl = Screen('Flip', screen.w);

    times = ones(2,10);
    
    for frame = 1:10
        Screen('FillRect', screen.w);
        oldvbl = screen.vbl;
        screen.vbl = Screen('Flip', screen.w, screen.vbl + updateTime);
        times(1,frame) = screen.vbl-oldvbl;
        oldvbl = screen.vbl;
        screen.vbl = Screen('Flip', screen.w, screen.vbl + updateTime, 1);
        times(2,frame) = screen.vbl-oldvbl;
    end
    
    figure(1)
    plot(times(1,:), 'r')
    hold on
    plot(times(2,:))
    hold off
    Screen('CloseAll')
    
end

function InitScreen()
    global screen

    screen.rate = Screen('NominalFrameRate', max(Screen('Screens')));
    AssertOpenGL;

    screenNumber=max(Screen('Screens'));

    screen.w = Screen('OpenWindow',screenNumber, 0);

    Priority(1);
   
    % Query duration of monitor refresh interval:
    screen.ifi=Screen('GetFlipInterval', screen.w);

    screen.vbl = 0;
end


