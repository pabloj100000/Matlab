function GatingAngle(varargin)
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

p.addParamValue('objRect', GetRects(12*PIXELS_PER_100_MICRONS, screen.center), @(x) size(x,2)==4);
p.addParamValue('angles', [0 45 90 135], @(x) all(all(isnumeric(x))));
p.addParamValue('pdStim', 6, @(x) isnumeric(x));
p.addParamValue('barsWidth', PIXELS_PER_100_MICRONS/2, @(x) x>0);
p.addParamValue('backPattern', 0, @(x) x==1 || x==0);   % 0 for bars
                                                        % 1 for checkers

p.parse(varargin{:});

objRect = p.Results.objRect;
angles = p.Results.angles;
backPattern = p.Results.backPattern;
pdStim = p.Results.pdStim;
barsWidth = p.Results.barsWidth;
%%%%%%%%%%%%%% Input Parser Ends %%%%%%%%%%%%%%%%

%%%%%%%%%%%%%% Constants %%%%%%%%%%%%%%%%
presentationLength = 50;
movieDurationSecs = 50;
objSeed = 1;
[screenW screenH] = SCREEN_SIZE;
stimSize = screenH;
objContrast = .03;
objMean = 127;
try

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
                'barsWidth', barsWidth, ...
                'rects', objRect, ...
                'angle', angle, ...
                'pdStim', pdStim, ...
                'backPattern', backPattern);
        end
    end
    FinishExperiment();
    
catch
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.
    CleanAfterError();
    psychrethrow(psychlasterror);
end %try..catch..
end


