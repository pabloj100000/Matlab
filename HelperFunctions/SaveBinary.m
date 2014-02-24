function SaveBinary(obj, precision, varargin)

    Add2StimLogList();
    % precision has to be a string literal in acordance to what fread wants
    % use:
    % 'int8' for small signed numbers
    % 'uint8' for <256 unsigned numbers
    % 'int16' etc...

    if (nargin==3)
        nameout = varargin{1};
        if (isempty(regexp(nameout, 'bin$', 'ONCE')))
            nameout = [nameout, '.bin'];
        end
    else
        nameout = [inputname(1), '.bin'];
    end
    fid = fopen(nameout, 'w');
    fwrite(fid, obj, precision);
    fclose(fid);
end

