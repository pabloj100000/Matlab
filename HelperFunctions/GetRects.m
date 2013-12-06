function rects = GetRects(diameters, centers)
    Add2StimLogList();
    if (length(diameters) ~= size(centers,1))
        error('# of diameters and # of centers do not match');
    end
    
    rects = ones(length(diameters), 4);
    for i=1:length(diameters)
        rects(i,:) = SetRect(0,0,diameters(i), diameters(i));
        rects(i,:) = CenterRectOnPoint(rects(i,:), centers(i,1), centers(i,2));
    end
    
end
