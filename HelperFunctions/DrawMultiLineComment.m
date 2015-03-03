function DrawMultiLineComment(screen, comment, varargin)
    % comment is a cell array of strings
    % each cell array gets printed onto the screen on the left top corner,
    % one line per cell array
    p=ParseInput(varargin{:});

    x0 = p.Results.x0;
    y0 = p.Results.y0;
    color = p.Results.color;

    for i=1:length(comment)
        Screen('DrawText', screen.w, comment{i}, x0, y0+(i-1)*20, color);
    end
end

function p =  ParseInput(varargin)
    p  = inputParser;   % Create an instance of the inputParser class.
    
    p.addParamValue('x0', 0, @(x) x>=0);
    p.addParamValue('y0', 0, @(x) x>=0);
    p.addParamValue('color', [0 0 0], @(x) size(x,1)==1 && ...
        (size(x,2)==3 || size(x,2)==4));
    p.parse(varargin{:});
end
