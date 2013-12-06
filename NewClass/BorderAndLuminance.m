function BorderAndLuminance(varargin)
% Wrapper to call JitterBackTex_JitterObjTex
%
% Divide the screen in object and background.
% Object will be a given texture changing phases every so often.
% Back will be a grating of a giving contrast and spatial frequency
% that reverses periodically at backReverseFreq.
global screen 

InitScreen(0);
    Add2StimLogList();

%%%%%%%%%%%%%% Input Parser Start %%%%%%%%%%%%%%%%
p  = inputParser;   % Create an instance of the inputParser class.

p.addParamValue('objMeans', [0 63 127 255]);
p.addParamValue('pdStim', PIXELS_PER_100_MICRONS/2, @(x) isnumeric(x));
p.addParamValue('jumpWidth', PIXELS_PER_100_MICRONS/2, @(x) x>0);
p.addParamValue('seed', 1, @(x) x>0);

p.parse(varargin{:});

objMeans = p.Results.objMeans;
pdStim = p.Results.pdStim;
seed = p.Results.seed;
jumpWidth = p.Results.jumpWidth;
%%%%%%%%%%%%%% Input Parser Ends %%%%%%%%%%%%%%%%

%%%%%%%%%%%%%% Constants %%%%%%%%%%%%%%%%
presentationLength = screen.rate;
movieDurationSecs = screen.rate;
stimSize = floor(screen.rect(4)/PIXELS_PER_100_MICRONS)*PIXELS_PER_100_MICRONS;
objContrast = 0;
framesN = presentationLength*screen.rate;
leftScreen = [0 0 screen.size.*[.5 1]];
rightScreen = [screen.size*[.5 0] screen.size];

try

    stream = RandStream('mcg16807', 'Seed', backSeed);
    
    for frame=0:framesN-1
        Luminances = randi(stream, 1, 2);
        Screen('FillRect', screen.w, leftScreen, Luminance);

        
    end
    FinishExperiment();
    
catch exception
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.
    CleanAfterError();
    psychrethrow(psychlasterror);
    rethrow(exception)
end %try..catch..
end


