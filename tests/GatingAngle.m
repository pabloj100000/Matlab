function GatingMean(varargin)
% Wrapper to call JitterBackTex_JitterObjTex
%
% Divide the screen in object and background.
% Object will be a given texture changing phases every so often.
% Back will be a grating of a giving contrast and spatial frequency
% that reverses periodically at backReverseFreq.
global screen

CreateStimuliLogStart();
InitScreen(0);

%%%%%%%%%%%%%% Input Parser Start %%%%%%%%%%%%%%%%
p  = inputParser;   % Create an instance of the inputParser class.

p.addParamValue('objRect', GetRects(192, screen.center), @(x) size(x,2)==4);
p.addParamValue('angles', [0 45 90 135], @(x) all(all(isnumeric(x))));
p.addParamValue('backPattern', 0, @(x) x==1 || x==0);   % 0 for bars
                                                        % 1 for checkers

p.parse(varargin{:});

objRect = p.Results.objRect;
angles = p.Results.angles;
backPattern = p.Results.backPattern;
%%%%%%%%%%%%%% Input Parser Ends %%%%%%%%%%%%%%%%

%%%%%%%%%%%%%% Constants %%%%%%%%%%%%%%%%
presentationLength = 5;
movieDurationSecs = 5;
objSeed = 1;
stimSize = 768;
objContrast = .03;
objMean = 127;
try
    CreateStimuliLogStart();

    for i=1:2
        if i==2
            objSeed = objStream{1,1}.State;
        end
        
        for j=1:length(angles)
            angle = angles(j);
            objStream = UFlickerObj(...
                'presentationLength', presentationLength, ...
                'movieDurationSecs', movieDurationSecs, ...
                'stimSize', stimSize, ...
                'objSeed', objSeed, ...
                'objContrast', objContrast, ...
                'objMean', objMean, ...
                'rects', objRect, ...
                'angle', angle, ...
                'backPattern', backPattern);
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


