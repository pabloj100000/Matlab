function [x] = GetPinkNoise3(framesN, contrastHI, contrastLO, meanLuminance, seed, plotFlag)
    % Generate a noise wave with 'pink like characterisitics'
    %
    %   Start by constructing a white noise sequence and then in Fourier
    %   space multiply by 1/sqrt(freq).
    %   After converting back into real space I added capabilities for
    %   scaling the high and lo frequency independently to match the given
    %   contrasts
    Add2StimLogList();
    
    S1 = RandStream('mcg16807', 'Seed',seed);
    xOri = randn(S1, framesN, 1);

    NFFT = 2^nextpow2(framesN); % Next power of 2 from length of y
    Y = fft(xOri,NFFT)/framesN;
    f = 1/2*linspace(0,1,NFFT);

    Y = Y./sqrt(f'+.00001);
    x = real(ifft(Y));
    x(framesN+1:end)=[];

    length=31;
    xLO = smooth(x, length);  % smoothing box is centered on the point
    xLO = circshift(xLO, (length-1)/2);

    % separate the stimulus into a high and a low frequency components.
    % Impose contrastHI to the high freq one and contrastLO to the low freq
    % one
    xHI = x-xLO;    % high freq fluctuations
    
    % Scale the low freq component to have the desired contrastLO and mean
    A = mean(xLO);
    B = std(xLO);
    xLO = (xLO - A)*contrastLO*meanLuminance/B + meanLuminance;
%    [mean(xLO) std(xLO) std(xLO)/meanLuminance]

    % Scale the high freq component to have the desired contrastHI and mean
    B = std(xHI);
    xHI = (xHI)*contrastHI.*xLO/B;

    x = xLO + xHI;
    %    Xstd = std(x-xLO);
%    x = ((x-xLO)*contrastHI*meanLuminance/Xstd)+xLO;    

    if plotFlag
        AnalyseNoise(x)
    end
end
