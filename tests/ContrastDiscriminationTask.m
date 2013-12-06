function q = ContrastDiscriminationTask(varargin)
    % Quest test.
    % You'll be presented to patches and have to identify the highest
    % contrast one. Press left/right arrow to identify the highest contrast
    % one or "Esc" to quit
global screen

try
    [objSize lambda sigma phase pedestal deltaX trialsPerDelay] = GetParameters(varargin{:});

    % *************** Constants ******************
    KbName('UnifyKeyNames');
    ESCAPE = KbName('escape');
    RIGHT_BTN = KbName('RightArrow');
    LEFT_BTN = KbName('LeftArrow');
    RIGHT = 2;
    LEFT = 1;
    minPhysicalContrast = 0;
    % *************** End of Constants ******************
    % *************** Variables that need to be init ***********
    InitScreen(0);
    
    vbl = 0;
    abortFlag=0;
    
    % Get object texture
    pedestalTex = GetGaborText2(objSize, lambda, sigma, phase, pedestal);
    
    % Make all necessary rectangles
    objDest = GetRects(objSize, screen.center-[deltaX 0])';
    objDest(:,2) = GetRects(objSize, screen.center+[deltaX 0])';
    objSource = Screen('Rect', pedestalTex);

    % Get 2 rectangles for the fixation point
    fixationLength = 11;
    fixationRect(:,1) = CenterRectOnPoint(SetRect(0,0, fixationLength, 1), screen.center(1), screen.center(2))';
    fixationRect(:,2) = CenterRectOnPoint(SetRect(0, 0, 1, fixationLength), screen.center(1), screen.center(2));
    
    % start Quest structure
    tGuess = -3.9;
    tGuessSd = 2;
    pThreshold=0.82;
    beta=3.5;delta=0.01;gamma=0.5;
    q=QuestCreate(tGuess,tGuessSd,pThreshold,beta,delta,gamma);
    q.normalizePdf=1; % This adds a few ms per call to QuestUpdate, but otherwise the pdf will underflow after about 1000 trials.
    
    for i=1:trialsPerDelay
                
        % Get recommended level.  Choose your favorite algorithm.
        tTest = QuestQuantile(q);	% Recommended by Pelli (1987), and still our favorite.
        tTest = tTest*(.9+rand()/5);   % add 10% noise to the suggested value;
        tTest = max(log(minPhysicalContrast),tTest);
        pedestalPatch = randi(2, 1, 1);      % pedestalPatch = 1=> left
        %                                                      2=> right
        
        % grab a gabor patch of the suggested contrast
        intendedContrast = exp(tTest)+pedestal;
        [testTex actualContrast] = GetGaborText2(objSize, lambda, sigma, phase, intendedContrast);
        tTested = log(actualContrast-pedestal);
        
        % order the two patches randomly
        if pedestalPatch==LEFT
            objTextures = [pedestalTex testTex];
        else
            objTextures = [testTex pedestalTex];
        end
        
        % show the fixation spot
        Screen('FillRect', screen.w, 0, fixationRect);

        Screen('DrawTextures', screen.w, objTextures, objSource, objDest);
        Screen('Close', testTex);
      
        vbl = Screen('Flip', screen.w, vbl + 0.5 * screen.ifi);
                    
        % figure out which patch had the higest contrast
        % WHAT DO I DO IF THE PATCHES HAVE EQUAL CONTRAST?
        if (0)%pedestal>exp(tTest))
            higestPatch = pedestalPatch;
        else
            higestPatch = 3 - pedestalPatch;
        end
        
        while 1
            [keyIsDown, ~, keyCode, ~] = KbCheck;
            if (keyIsDown)
                if keyCode(ESCAPE)
                    % finish experiment
                    abortFlag=1;
                    break
                elseif (keyCode(RIGHT_BTN) && higestPatch==RIGHT) || ...
                        (keyCode(LEFT_BTN) && higestPatch==LEFT)
                    % got the contrast right
                    % Update the pdf
                    answer = 'Right';
                    q=QuestUpdate(q,tTested, true); % Add the new datum (actual test intensity and observer response) to the database.
                    break
                elseif (keyCode(RIGHT_BTN) && higestPatch==LEFT) || ...
                        (keyCode(LEFT_BTN) && higestPatch==RIGHT)
                    % got the contrast wrong
                    % Update the pdf
                    answer = 'Wrong';
                    q=QuestUpdate(q,tTested, false); % Add the new datum (actual test intensity and observer response) to the database.
                    break
                end
            end
        end
        
        fprintf('%s, tTest=%f, intendedContrast=%f, acutalContrast = %f\n',answer, tTest, intendedContrast, actualContrast)
        pause(.2)
        %}
        if (abortFlag)
            break
        end

    end
    
    % Ask Quest for the final estimate of threshold.
    t=QuestMean(q);		% Recommended by Pelli (1989) and King-Smith et al. (1994). Still our favorite.
    sd=QuestSd(q);
    fprintf('Final threshold estimate (mean±sd) is %.2f ± %.2f\n',t,sd);
    fprintf('corresponding contrast is %.2f\n', exp(t));
        
    Screen('CloseAll')
    clear global screen
    
catch exception
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.
    fprintf('Error');
end %try..catch..
end

function [objSize lambda sigma phase pedestal deltaX trialsPerDelay] = GetParameters(varargin)
    p  = inputParser;   % Create an instance of the inputParser class.

    % Gabor parameters
    p.addParamValue('objSize', 100, @(x) x>0);
    p.addParamValue('lambda', 10, @(x) x>0);        % # of pixels per cycle
    p.addParamValue('sigma', 10, @(x) x>0);         % gaussian standard deviation in pixels
    p.addParamValue('phase', 0, @(x) x>0);          % phase, 0->1
    p.addParamValue('pedestal', .1, @(x) all(x>=0 & x<=1)); % contrast of the reference patch
    p.addParamValue('deltaX', 128, @(x) x>0);       % Distance of each patch to the fixation point (pixels)
    p.addParamValue('trialsPerDelay', 20, @(x) x>0);    % how many points per delay do you want to use to estimate the contrast.
    
    p.parse(varargin{:});
    
    % gabor parameters
    objSize = p.Results.objSize;
    lambda = p.Results.lambda;
    sigma = p.Results.sigma;
    phase = p.Results.phase;
    pedestal = p.Results.pedestal;
    deltaX = p.Results.deltaX;
    trialsPerDelay = p.Results.trialsPerDelay;
end



