function CheckMSequence(fileIn, varargin)
    % This function will print the histogram of how many times a given
    % stimulus was presented in fileIn. A sequence of "codeLength" 
    % consecutive frames encode a stimulus in base 'base'.
    % fileIn has to have a namme of the form:
    % MSequence_base_codeLength
    % if varargin is given, it uses a different codeLength than the one
    % given in the filename.
    
    fid = fopen(fileIn, 'r+');
    sequence = fscanf(fid, '%u');
    
    % remove all chars at the eof so that last char will be a number.
    fseek(fid, -1, 'eof');
    lastChar = fscanf(fid, '%u', 1);
    if isempty(lastChar)
        error('Delete last chars from fileIn');
    end
    
    findDash = strfind(fileIn, '_');
    base = str2num(fileIn(findDash(1)+1:findDash(2)-1));
    if (nargin==1)
        codeLength = str2num(fileIn(findDash(2)+1:strfind(fileIn, '.')-1));
    else
        codeLength = varargin{1};
    end
    
    stimSeq = readSeq(sequence, base, codeLength);
    
    % how many time does each stim appear?
    freq = hist(stimSeq, 0:base^codeLength-1);
    
    maxFreq = max(freq);
    minFreq = min(freq);

    if (maxFreq==minFreq)
        fprintf('\n\tSequence is OK\n\n');
        fprintf('When computing the freq of each stim with base %d and length %d\n', base, codeLength);
        fprintf('I got a maximum occurrance freq of %d and a minimum of %d\n', maxFreq, minFreq);
    else
        fprintf('**** Error **** Error **** Error\n');
        fprintf('The sequence generates numbers such that the frequency of occurance is not constant\n');
    end
    
    avg = smooth(sequence);
    plot(avg)
    title('Running avg of luminance')
    xlabel('sequence')
    ylabel('avg')
end

function out = readSeq(seq, base, codeLength)
    out = ones(1, length(seq));
    seq = [seq; seq(1:codeLength-1)];
    for i=1:length(out)
        out(i) = GetStim(seq(i:i+codeLength-1), base, codeLength);
    end
%    out = [out 0];
end

function stim = GetStim(seq, base, codeLength)
    a = seq(end-codeLength+1:end);
    stim = sum(a'.*(base.^(0:codeLength-1)));
end
