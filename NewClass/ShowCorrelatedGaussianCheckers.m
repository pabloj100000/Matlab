function seed = ShowCorrelatedGaussianCheckers(checkers, framesN, means, changes, ...
    contrast, seed)
% show many gaussian checkers at once.
% The luminance value in checker 'i' is:
%   means(i) + rand(contrast)*changes(i, j)
% 
% changes is an array that has gradients, how much the image will change
% upon moving in a given direction. Changes will be a 2D array
% (moving the image up-donw, left-right)
%
% checkers: 4 x checkersN
% framesN:  
% means: 1D checkersN
% changes: 2D 2 x checkersN (changes(1,:) has the gradients in either
% vertical or horizontal and changes(2,:) has the gradients along the other
% direction

global screen

try
    % start the stimulus
    InitScreen(0)
    Add2StimLogList();
        
    % if changes is 3D, change it to 2D 
    if (length(size(changes))==3)
        if size(changes,1)~=1
            error('ShowCorrelatedGaussianCheckers wants to change an array from 3D to 2D but 1st dimension should be of length 1 and it is not');
        end
        changes = reshape(changes, 2, length(changes));
    end
    RS = RandStream('mcg16807', 'Seed', seed);
    
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
        % colors has to be of size = (3,n) or (4,n)
        colors = uint8(ones(3,1)*(randn(RS)*means.*changes(1,:)*contrast + ...
            randn(RS)*means.*changes(2,:)*contrast + means));
        
        %.*means.*stds+means)
        Screen('FillRect', screen.w, colors, checkers)

        %        Screen('FillOval', screen.w, pdColor, pd);
% {        
        if (mod(frame, round(screen.rate/screen.waitframes))==1)
            pdColor = 255;
        else
            pdColor = colors(1,1)/2;
        end
        
        Screen('FillOval', screen.w, pdColor, pd);
  %}      
        % Flip 'waitframes' monitor refresh intervals after last redraw.
        screen.vbl = Screen('Flip', screen.w, screen.vbl + (screen.waitframes - 0.5) * screen.ifi);

        if KbCheck
            break
        end
    end
        
    seed = RS.State;
    
    FinishExperiment();
        
catch exception
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.
    CleanAfterError();
    rethrow(exception)
end %try..catch..
end
