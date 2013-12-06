function [rect] = GetScreenSubRect(rowsN, colsN, item)
    % Divide teh whole screen rowsN and colsN and return the coordinates
    % for one of those rects, the one corresponding to item
    global screen

    hori = screen.rect(3)/rowsN;
    vert = screen.rect(4)/colsN;
    
    rect = SetRect(0,0,hori,vert);
    rect = OffsetRect(rect, mod(item, rowsN)*hori, floor(item/rowsN)*vert);

end