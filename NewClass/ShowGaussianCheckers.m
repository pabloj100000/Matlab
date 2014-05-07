function ShowGaussianCheckers(checkers, framesN, means, stds, seeds)
% show many gaussian checkers at once, each checker has its own mean, std 
% and seed
% All these parameters should be of the same size.
global screen
waitframes = 3;

try
    % start the stimulus
    InitScreen(0)
    Add2StimLogList();
    
    checkersN = size(checkers,2);
    
    % Define the object order sequence. 
    S = cell(checkersN);
    for i=1:checkersN
        S{i} = RandStream('mcg16807', 'Seed',seeds(i));
    end
    
    % Define the PD box
    pd = DefinePD();
    

    Screen('FillRect', screen.w, screen.gray);

    for frame=1:framesN
%{
        frame
        colors = double(ones(1,3))
        colors = rand(1,checkersN)
        colors = colors.*means
        colors = colors.*stds
        colors = colors + means
        colors = uint8(colors)
        %}
        colors = uint8(ones(3,1)*(rand(1, checkersN).*means.*stds + means));
        %.*means.*stds+means)
        Screen('FillRect', screen.w, colors, checkers)

        %        Screen('FillOval', screen.w, pdColor, pd);
        
        % Flip 'waitframes' monitor refresh intervals after last redraw.
        screen.vbl = Screen('Flip', screen.w, screen.vbl + (waitframes - 0.5) * screen.ifi);
        if KbCheck
            break
        end
    end
        
    FinishExperiment();
        
catch exception
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.
    CleanAfterError();
    rethrow(exception)
end %try..catch..
end
