function rects = GetRects(diameters, centers)
    % generate rects from diameters and centers.
    % Since psychtoolbox uses centers as 2 row arrays and rects as 4 row
    % arrays that's what I'm using here.
    Add2StimLogList();
    if (length(diameters) ~= size(centers,2))
        error('# of diameters and # of centers do not match');
    end
    if (size(centers,1) ~= 2)
        error('centers in GetRects should be a 2 row array');
    end
    
    rects = ones(4, length(diameters));
    for i=1:length(diameters)
        rects(:, i) = CenterRectOnPoint(SetRect(0,0,diameters(i), diameters(i)), centers(1, i), centers(2, i));
    end
    
end
