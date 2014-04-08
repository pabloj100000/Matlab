function [x] = GetPinkNoise3b(framesN, contrast, meanLum, seed, plotFlag)
    % Generate a noise wave with 'pink like characterisitics'
    %
    %   Start by constructing a white noise sequence and then in Fourier
    %   space multiply by 1/sqrt(freq).
    %   After converting back into real space I added capabilities for
    %   scaling the high and lo frequency independently to match the given
    %   contrasts
    Add2StimLogList();
    
    S1 = RandStream('mcg16807', 'Seed',seed);

    NFFT = 2^nextpow2(framesN); % Next power of 2 from length of y
    
    xOri = randn(S1, NFFT, 1);

    Y = fft(xOri,NFFT)/framesN;
    f = 1/2*linspace(0,1,NFFT);

    Y = Y./sqrt(f'+.00001);

    x = real(ifft(Y));
%    x = ifft(Y);
    x(framesN+1:end)=[];

    vMean = mean(x);
    vSTD = std(x);
    
    % first make x zero mean and SDT of 1
    x = (x-vMean)/vSTD;

    % now make it meanLum and contrast
    x = meanLum + meanLum*contrast*x;

    [mean(x) std(x)/mean(x)]
    if plotFlag
        AnalyseNoise(x)
    end
end
