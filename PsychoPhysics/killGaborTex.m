function gabor = killGaborTex(gabor)    
    if isfield(gabor, 'tex')
%        Screen('Close', gabor.tex);
        gabor = rmfield(gabor, 'tex');
    end
end