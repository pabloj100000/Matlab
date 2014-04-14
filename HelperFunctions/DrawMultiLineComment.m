function DrawMultiLineComment(screen, comment)
    % comment is a cell array of strings
    % each cell array gets printed onto the screen on the left top corner,
    % one line per cell array
    
    for i=1:length(comment)
        Screen('DrawText', screen.w, comment{i}, 0, (i-1)*20);
    end
end