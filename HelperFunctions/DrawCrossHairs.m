function DrawCrossHairs(positions)
    % Draw a crossHair in every xy in positions/
    % positions = [x1 x2 ... xn; y1 y2 ... yn];
    
    global screen
    Add2StimLogList();
    
%    Screen 'CloseAll'
    lines = ones(2, 4*size(positions,2));
    for i=0:size(positions,2)-1
        lines(:, i*4+1) = positions(:, i+1) + [16 0]';
        lines(:, i*4+2) = positions(:, i+1) - [16 0]';
        lines(:, i*4+3) = positions(:, i+1) + [0 16]';
        lines(:, i*4+4) = positions(:, i+1) - [0 16]';
        Screen('DrawLines', screen.w, lines);%, width, colors, center);%] [,smooth]);
    end

end
