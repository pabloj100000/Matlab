function UFlickerObj_loop1(varargin)
%   Basic Gating experiment. Only a few tunable parameters
    global screen
    
    p  = inputParser;   % Create an instance of the inputParser class.

    p.addParamValue('backPeriod', 2, @(x) x>0);
    p.addParamValue('presentationLength', 2, @(x) x>0);
    p.addParamValue('objContrast', [.03 .06 .12 .24 .35], @(x) all(x>=0 & x<=1));
    p.addParamValue('objMean', 127, @(x) all(x>=0 & x<=255));
    p.addParamValue('pdStim', 106, @(x) isnumeric(x));

    p.parse(varargin{:});

    backPeriod = p.Results.backPeriod;
    presentationLength = p.Results.presentationLength;
    objContrast = p.Results.objContrast;
    objMean = p.Results.objMean;
    pdStim = p.Results.pdStim;
    stimSize = 768;
    barsWidth = 8;
    backContrast = 1;
    backTexture = GetCheckersTex(stimSize+barsWidth, barsWidth, backContrast);

    for i=1:length(objMean)

        for j=1:length(objContrast)

            UFlickerObj_Implementation(...
                'pdStim', pdStim, ...
                'stimSize', stimSize, ...
                'backPeriod', backPeriod, ...
                'backTexture', backTexture{1}, ...
                'presentationLength', presentationLength, ...
                'objContrast', objContrast(j), ...
                'objMean', objMean(i) ...
                );
            
            if (KbCheck)
                break
            end
        end
        if (KbCheck)
            break
        end
    end
    
    Screen('Close', backTexture{1});
    
    FinishExperiment()
end
