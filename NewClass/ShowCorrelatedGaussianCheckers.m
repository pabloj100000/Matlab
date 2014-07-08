function seed = ShowCorrelatedGaussianCheckers(framesN, cellSize, means, gradientUp, ...
    gradientLeft, contrast, seed)
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

    % mean, gradientUp and gradientLeft are 3D, change them to be 2D
    % if changes is 3D, change it to 2D 
    if length(size(means))==3
        means = reshape(means, size(means,2), size(means,3));
        gradientUp = reshape(gradientUp, size(gradientUp,2), size(gradientUp,3));
        gradientLeft = reshape(gradientLeft, size(gradientLeft,2), size(gradientLeft,3));
    end
    
    RS = RandStream('mcg16807', 'Seed', seed);
    
    destRect = SetRect(0, 0, size(means,1), size(means,2))*cellSize;
    destRect = CenterRect(destRect, screen.rect);
    
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
        colors = uint8((randn(RS)*means.*gradientUp*contrast + ...
            randn(RS)*means.*gradientLeft*contrast + means));
        
        texture = Screen('MakeTexture', screen.w, colors);
        Screen('DrawTexture', screen.w, texture, [],destRect,[], 0);
        
        if (mod(frame, round(screen.rate/screen.waitframes))==1)
            pdColor = 255;
        else
            pdColor = colors(1,1)/2;
        end
        
        Screen('FillOval', screen.w, pdColor, pd);

        % Flip 'waitframes' monitor refresh intervals after last redraw.
        screen.vbl = Screen('Flip', screen.w, screen.vbl + (screen.waitframes - 0.5) * screen.ifi);

        % We have to discard the noise checkTexture.
        Screen('Close', texture);

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
