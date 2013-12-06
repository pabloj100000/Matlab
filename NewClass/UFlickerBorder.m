function newSeed = UFlickerBorder(varargin)
% Calls UFlickerBOrder_Implementation. You can pass many 'parameter',
% value pairs to affect behaviour. Possible parameters are:
% borders
% repetas
% pdStim
% stimSize
% objSize
% backPeriod
% presentationLength
% objContrast
% objMean
% checkerSize
% objSeed
% backTexture
% borderPosition
try
    p  = inputParser;   % Create an instance of the inputParser class.
    p.KeepUnmatched = true;

    p.addParamValue('repeats', 4, @(x) x>0);
    p.addParamValue('objSeed', 1, @(x) isnumeric(x));
    p.addParamValue('borders', [0:2/32:9/32 10/32:1/32:20/32], @(x) size(x,1)==1 && size(x,2)>0);
    
    p.parse(varargin{:});
    
    repeats = p.Results.repeats;
    borders = p.Results.borders;
    objSeed = p.Results.objSeed;

    newSeed = objSeed;
    
    for i=1:repeats
        % first time it sets objSeed to the parameter passed by the user
        % (or default parameter) on subsequent executions it uses the value
        % returned by UFlickerBorder_Implementation below
        objSeed = newSeed;
        
        for j=1:size(borders,2)
            borderPosition = borders(j);
   
            newSeed = UFlickerBorder_Implementation(...
                varargin{:}, ...
                'objSeed', objSeed, ...
                'borderPosition', borderPosition...
                );
            if (KbCheck)
                break
            end

        end
        if (KbCheck)
            break
        end
    end
    
    FinishExperiment();
    
catch exception
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.
    CleanAfterError();
%    psychrethrow(psychlasterror);
    rethrow(exception)
end %try..catch..
end
