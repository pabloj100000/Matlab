function test
    global screen
    InitScreen(0);

    Add2StimLogList();
    Screen closeAll
    framesN = 6000;
    
    objRects = ones(4,32);
    oneRect = SetRect(0,0, 32, 1)*PIXELS_PER_100_MICRONS;
    for i=0:31
        objRects(:,i+1) = CenterRect(oneRect, screen.rect-(16-i)*PIXELS_PER_100_MICRONS)';
    end
    
    frame = randn(32,1);
    frameFFT = fft(frame);
    [theta, rho] = cart2pol(real(frameFFT), imag(frameFFT));
    figure(1)
    plot(frame);
    for i=1:framesN
        theta = rand(32,1)*2*pi;
        randFFT = rho.*exp(i*theta);
        newFrame = ifft(randFFT);
        figure(1);
        plot(real(newFrame));
    end
