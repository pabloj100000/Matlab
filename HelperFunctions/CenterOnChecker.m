function [newCenter] = CenterOnChecker(checkX, checkY, varargin)
    p=ParseInput(varargin{:});

    checkN = p.Results.checkN;
    checkSize = p.Results.checkSize;

    [screenX, screenY] = Screen('WindowSize', max(Screen('Screens')));
    center = [screenX screenY]/2;
    
    % define newCenter to be the middle of checker (0,0)
    newCenter = center-checkSize*(checkN-1)/2;

    if checkX < 0
        checkX = checkN/2-.5;
    end
    
    if checkY < 0
        checkY = checkN/2-.5;
    end
    
    % shift the center from that of checker (0,0) to that of checer
    % (checkX, checkY)
    newCenter = newCenter + [checkX checkY]*checkSize;
    newCenter = newCenter';
end

function p =  ParseInput(varargin)
    p  = inputParser;   % Create an instance of the inputParser class.


    % Background related
    p.addParamValue('checkN', 32, @(x)x>0);
    p.addParamValue('checkSize', 100, @(x) x>0);

    % Call the parse method of the object to read and validate each argument in the schema:
    p.parse(varargin{:});
    
end
