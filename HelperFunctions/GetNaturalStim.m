function [natStim objSeed] = GetNaturalStim(framesN, objSeed, alpha)
    % Generates a distribution of intensities with a power spectrum that
    % goes like 1/f^2 mimicing natural stim
    % "Efficient  Coding  of  Natural  Scenes  in  the  Lateral  Geniculate 
    % Nucleus:  Experimental  Test  of  a  Computational  Theory 
    % Yang  Dan,?  Joseph  J.  Atick,  and  R.  Clay  Reid?
    Add2StimLogList();

    stream = RandStream('mcg16807', 'Seed', objSeed);
    y = randn(stream, 1, framesN);
    objSeed = stream.State;
    
    % sampling frequency
    Fs = max(Screen('NominalFrameRate', max(Screen('Screens'))), 60);   % Sampling Freq

    % compute FFT of random numbers
    NFFT = 2^(nextpow2(framesN));
    Y = fft(y,NFFT)/framesN;
%    f = linspace(0, Fs-Fs/NFFT, NFFT);
    f = linspace(-Fs+Fs/NFFT, Fs-Fs/NFFT, NFFT);
Y0 = Y;
    % Multiply by 1/f
    Y = Y./f;
Y = sign(f)./f;    
    Y(1)=Y(2);
Y1 = Y;
    % reconstruct the signal with the modified power spectra
    natStim = ifft(Y, framesN);
    natStim(framesN+1:end)=[];
%    natStim = real(natStim);
Y2 = fft(natStim, NFFT);

figure(1)
subplot(3, 1, 1)
plot(Y0);
subplot(3, 1, 2)
plot(Y1);
subplot(3, 1, 3)
plot(Y2);


    screen.gray=127;
    natStim = alpha*natStim*screen.gray+screen.gray;
end