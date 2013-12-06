function [oneFrame seed deltaT] = RFframe(checkersH, checkersV, seed, deltaT)
    % Generates the frames displayed in computing the RF map

    % init random seed generator
    randomStream = RandStream('mcg16807', 'Seed', seed);

    oneFrame = rand(randomStream, checkersH, checkersV)>.5;
    
    seed = randomStream.State;
end
