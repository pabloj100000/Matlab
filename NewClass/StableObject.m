function StableObject(varargin)
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
p.addParamValue('objMeans', [0 63 127 255]);
p.addParamValue('angle', 0, @(x) isnumeric(x));
p.addParamValue('pdStim', 6, @(x) isnumeric(x));
p.addParamValue('barsWidth', PIXELS_PER_100_MICRONS/2, @(x) x>0);
p.addParamValue('backPattern', 0, @(x) x==1 || x==0);   % 0 for bars
                                                        % 1 for checkers

p.parse(varargin{:});

objRect = p.Results.objRect;
objMeans = p.Results.objMeans;
angle = p.Results.angle;
backPattern = p.Results.backPattern;
pdStim = p.Results.pdStim;
barsWidth = p.Results.barsWidth;
%%%%%%%%%%%%%% Input Parser Ends %%%%%%%%%%%%%%%%

%%%%%%%%%%%%%% Constants %%%%%%%%%%%%%%%%
[screenW screenH] = SCREEN_SIZE;
presentationLength = 2;
movieDurationSecs = 2;
stimSize = screenH;
objContrast = 0;
try

    for i=1:2
        for j=1:length(objMeans)
            objMean = objMeans(j);
            UFlickerObj(...
                'presentationLength', presentationLength, ...
                'movieDurationSecs', movieDurationSecs, ...
                'stimSize', stimSize, ...
                'objContrast', objContrast, ...
                'barsWidth', barsWidth, ...
                'objMean', objMean, ...
                'rects', objRect, ...
                'angle', angle, ...
                'backPattern', backPattern, ...
                'pdStim', pdStim);
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


