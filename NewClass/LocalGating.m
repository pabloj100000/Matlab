function LocalGating(varargin)
    global screen

    InitScreen(0);
    Add2StimLogList();

    % ********** Input parser starts ***********
    p  = inputParser;   % Create an instance of the inputParser class.

    p.addParamValue('centers', [screen.center+[48 48];screen.center-[48 48]], @(x) size(x,2)==2);
    p.addParamValue('presentationLength', 50, @(x) isnumeric(x));
    p.addParamValue('objContrast', 1, @(x) x>=0 && x<=1);
    p.addParamValue('backSeed', 1, @(x) isnumeric(x));
    p.addParamValue('pdStim', 102, @(x) isnumeric(x));
    
    p.parse(varargin{:});

    centers = p.Results.centers;
    presentationLength = p.Results.presentationLength;
    objContrast = p.Results.objContrast;
    backSeed = p.Results.backSeed;
    pdStim = p.Restuls.pdStim;
    % ********** Input parser ends ***********
  

    for i=1:2
        if i==2
            % all sizes run with the same seed
            backSeed = nextSeed;
        end
        for j=-1:3
            if j==-1
                % negative control with no object
                center = [0 0];
                sizes = 1;
            else
                % Change the object size in powers of 2
                center = centers;
                sizes=ones(1,size(center,1))*4*2^j;
            end
            nextSeed = UFlickerObjInverted('objSize', sizes, ...
                'backSeed', backSeed, 'objCenter', center, 'objContrast', objContrast, ...
                'movieDurationSecs', presentationLength, ...
                'presentationLength', presentationLength, 'pdStim', pdStim);
        end
    end
    FinishExperiment();
    
end
