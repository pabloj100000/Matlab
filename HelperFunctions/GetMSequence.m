function GetMSequence(base, codeLength, varargin)
% This functions generates a text file with all M sequences using base and
% code length.
% For example, GetMSequence(4, 2) generates file MSequence_4_2.txt
%   one of those entries is: 0 1 2 3 0 2 0 3 1 3 3 2 2 1 1 0
%   which has 16 numbers, 4 times each number in the [0-4) range
%   converting consecutive numbers to a single number gives
%   0 1 2 3 0 2 0 3 1 3 3 2 2 1 1 0
%   1 6 11 12 2 8 3 13 7 15 14 10 9 5 4 0

    % varargin{1}:  available
    % varargin{2}:  seq
    % varargin{3}:  fid
    % varargin{4}:  last number added
    if nargin==2
        seq = zeros(1,codeLength);
        available = ones(base^codeLength,1);
        available(GetStim(seq,base,codeLength)+1)=0;
%        fid = fopen('MSequence.bin', 'w+');
        fname = ['MSequence_', num2str(base), '_', num2str(codeLength), '.txt'];
        fid = fopen(fname, 'w+');
        for i=0:base-1
            GetMSequence(base, codeLength, available, [seq i], fid, i);
        end
    else
        available = varargin{1};
        seq = varargin{2};
        fid = varargin{3};
        lastAdded = varargin{4};
    end
    
    currentStim = GetStim(seq, base, codeLength);
    if available(currentStim+1)
        % so far so good, add another number and see what happens
        available(currentStim+1)=0;
        
        % are we done?
        if max(available)==0
            % done, return sequence
%            if (seq(1:codeLength-1)==seq(end-codeLength+2:end))
%                fwrite(fid, seq, 'uint8');
                fprintf(fid, '%g ', seq(codeLength:end));
                fprintf(fid, '\n');
                fprintf('%g ', seq(codeLength:end));
                fprintf('\n');
%                readSeq(seq, base, codeLength);
%            end
        else
            for i=1:base
                next = mod(lastAdded+i,base);
                GetMSequence(base, codeLength, available, [seq next], fid, next);
            end
        end
    else
        % destroy this search
        seq = [];
    end
    
    stack = dbstack;
    if size(stack,1)==1 || ~strcmp(stack(2).name, 'GetMSequence') 
        fclose(fid);
    end
end

function stim = GetStim(seq, base, codeLength)
    a = seq(end-codeLength+1:end);
    stim = sum(a.*(base.^(0:codeLength-1)));
end

function readSeq(seq, base, codeLength)
    out = ones(1, length(seq)-codeLength+1);
    for i=1:length(seq)-codeLength + 1
        out(i) = GetStim(seq(i:i+codeLength-1), base, codeLength);
    end
    out    
end