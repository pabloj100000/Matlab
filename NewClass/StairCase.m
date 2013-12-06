function [reading gof] = StairCase(varargin)
    global screen
try    
    p  = inputParser;    % Create an instance of the inputParser class.

    p.addParamValue('stepsN', 10, @(x) x>0);
    p.parse(varargin{:});

    stepsN = p.Results.stepsN;
    stepSize = round(255/stepsN);
    luminance = [0:stepSize:255 255];
    reading = zeros(1, length(luminance));
    
    InitScreen(0);
    Add2StimLogList();
    
    for i=1:length(luminance)
        Screen('FillRect', screen.w, luminance(i));
        Screen('Flip', screen.w);

        reading(i) = input('Enter the luminance reading: ');
        
        pause(.2)
    end
    
    FinishExperiment();
    figure(1);
    plot(luminance, reading, 'LineWidth', 2);
    
    [cfun gof] = fit(luminance', reading', 'poly1');
    fprintf('gof = %f\n', gof.rsquare);
    
catch exception
    CleanAfterError();
    rethrow(exception);
    psychrethrow(psychlasterror);
end

