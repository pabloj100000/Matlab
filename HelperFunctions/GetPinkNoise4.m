function pink = GetPinkNoise4(framesN, polesN, alpha, seed)
%   read this webpage http://sampo.kapsi.fi/PinkNoise/
%   Generates a sequence of length 'framesN' of pseudorandom numbers
%   following a 1/f^alpha sequence.
%
%   polesN: how many numbers to take into consideration before generating
%   the next one

    S1 = RandStream('mcg16807', 'Seed',seed);

    poles = GetPoles(polesN, alpha)
    polesN = length(poles);

    pink = randn(S1, framesN+polesN, 1);

    for i=polesN+1:framesN+polesN
        previousPinks = pink(i-polesN:i-1);
%        [poles previousPinks]
        pink(i) = pink(i) - dot(poles, previousPinks);
    end
    
    pink(1:polesN)=[];
    
end

function poles = GetPoles(polesN, alpha)
    poles = ones(polesN, 1);
    for i=1:polesN
        poles(i+1) = (i-1-alpha/2)*poles(i)/i;
    end
    poles(1)=[]; % I'm doing this to be able to subtract from the next
                % Gaussian number the dot product between poles and
                % prevousNumbers
    poles = wrev(poles);
end

