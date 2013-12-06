function AnalyseNoise(noise)
    Hs = spectrum.periodogram;
    psd(Hs,noise);
    xValue = .01:.001:1;
% {
    hold on
    plot(xValue, 1./xValue, 'k')
    hold off
    %}
end
