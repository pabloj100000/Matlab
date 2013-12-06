% File executed on: 06-Jul-2011 13:29:35
% List of default arguments:
% angle = 0
% backContrast = 1
% backJitterPeriod = 11
% backMode = 0  0  1  0
% backRect = 128    0  896  768
% backReverseFreq = 1
% backSeed = 2
% barsWidth = 8
% checkersN = 12
% checkersSize = 16  16
% color = 0
% debugging = 0
% distance = 5
% movieDurationSecs = 1600
% objCenterXY = 0  0
% objContrast = 0.05
% objJitterPeriod = 11
% objMean = 127
% objSeed = 1
% objSizeH = 192
% objSizeV = 192
% presentationLength = 10
% rects = 0    0  192  192
% repeatBackSeq = 0
% repeatObjSeq = 0
% sizeH = 0
% sizeV = 0
% stimSize = 512
% vbl = 0
% waitframes = 1

function run070611()
global pdStim screen

%  Record for 402s three times, then
% Record for 5000  +   2120
try
    CreateStimuliLogStart();    

    Wait2Start()
    
    % Define the rectangles
    objRect = GetRects(192, screen.center);
    stimSize = 768;
    barsWidth = 8;

%{
    pause(.2)
    pdStim = 0;
    RF( ...
        'movieDurationSecs', 1000, ...
        'barsWidth',16, ...
        'objContrast',1, ...
        'waitFrames', 1 ...
        );

    % 120s
    pdStim = 1;
    pause(.2)
    OMS_identifier_LD('presentationLength',20, 'barsWidth', 16);
%}    

    % 500
%    pdStim = 2;
    pause(.2)
    Sensitization();

    %%%%%%%%%%%%%%%%%%%%%% Changing contrast every 100s %%%%%%%%%%%%%%%%%%%
    % traditional Gatting Experiment switching contrast every 100s
    % reversing 100um Checkers in background
    % 500
    pdStim = 3;
    pause(.2)
    UflickerObj( ...
        'objContrast', [.12 .35 .24 .06 .03], ...
        'rects', objRect, ...
        'backMode', [0 0 1 0], ...
        'backPattern', 0, ...
        'barsWidth', barsWidth, ...
        'stimSize', stimSize, ...
        'backReverseFreq', 1, ...
        'backJitterPeriod', 100, ...
        'objJitterPeriod', 100, ...
        'presentationLength', 100, ...
        'movieDurationSecs', 500 ...
        );

    pdStim = 104;
    BiMonoPhasicInformation(...
        'backContrast', 1, ...
        'backPattern', 0, ...
        'backCheckerSize', barsWidth, ...
        'movieDurationSecs', 3600*3, ...
        'objRect', objRect ...
        );
    
    CreateStimuliLogWrite();

catch 
    FinishExperiment();
    psychrethrow(psychlasterror);
end %try..catch..
end


function Sensitization(varargin)
%   obj and background will both be either bars or checkers of a given
%   size. The phase and contrast will change over some values.
% 
% Divide the screen in object and background.
% Object will be a given texture changing phases every so often.
% Back will be a grating of a giving contrast and spatial frequency
% that reverses periodically at backReverseFreq.

global vbl screen pd pdStim
CreateStimuliLogStart()

if isempty(vbl)
    vbl=0;
end
if isempty(pdStim)
    pdStim=0;
end


    p  = inputParser;   % Create an instance of the inputParser class.

    p.addParamValue('lowLength', 16, @(x)x>0);
    p.addParamValue('hiLength', 4, @(x) x>0);
    p.addParamValue('repeats', 25, @(x) x>0);
    
    p.parse(varargin{:});
    

    lowLength = p.Results.lowLength;
    hiLength = p.Results.hiLength;
    repeatsN = p.Results.repeats;
try
    InitScreen(1);

    % each presentation will have all possible contrasts.

    % Init all random streams
    stream1 = RandStream('mcg16807', 'Seed', 1);
        

    framesPerSec = 60;
    
    framesLo = framesPerSec*lowLength;
    framesHi = framesPerSec*hiLength;
    
    contrastHi = .35;
    contrastLo = .05;
a=[];    
    sigmaHi = contrastHi*screen.gray;
    sigmaLo = contrastLo*screen.gray;
Screen 'closeAll'    
    for repeat=1:repeatsN
        for frame=0:framesHi+framesLo-1
            if (frame<framesHi)
                % Hi contrast
                color = sigmaHi*randn()+screen.gray
            else
                color = sigmaLo*randn()+screen.gray
            end
a=[a color];
            if (KbCheck)
                break
            end

        end
        if (KbCheck)
            break
        end
    end
    
    CreateStimuliLogWrite(p);
    
catch
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.
    FinishExperiment();
    psychrethrow(psychlasterror);
end %try..catch..
end
