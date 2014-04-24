function TNF3()
%   just a wrapper to call TNF2 with different Luminance and Contrast
%   sequences.
%   The luminance follows an m-sequence with base 4 and 2 frames (16 frames
%   with all possible combinations of 4 luminances, spaced by powers of 2)
%   The 
    lumSeq = GetLumSeq();
    
    for i=1:2
        TNF2('meanSeq', lumSeq, 'contrastSeq', ones(1,length(lumSeq))*0, 'tnfGaussianFlag', 1);
        
        TNF2('meanSeq', lumSeq, 'contrastSeq', ones(1,length(lumSeq))*.03, 'tnfGaussianFlag', 1);
        
        TNF2('meanSeq', lumSeq, 'contrastSeq', ones(1,length(lumSeq))*.3, 'tnfGaussianFlag', 1);
    end
end


function lumSeq = GetLumSeq()
    repeats = 100;
    L = [32 64 128 256]-1;
    
    lumSeq = ones(1, repeats*length(L)^2);
    for i=1:repeats
        lumSeq((i-1)*length(L)^2+1:i*length(L)^2) = [L(1) L(2) L(3) L(4) L(1) L(3) L(1) L(4) L(2) L(4) L(4) L(3) L(3) L(2) L(2) L(1)];
    end
end

