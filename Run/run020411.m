function run020411()
CreateStimuliLogStart();

global pdStim;

% Define the rectangles



% Define the rectangles
[centerX, centerY] = Screen('WindowSize', max(Screen('Screens')));
center1 =[centerX centerY]/2;
objRect1 = GetRects(192, center1);


Wait2Start()
% record for 1000 + 2*6*500 = 7000 seconds

pdStim = -1;

for j=1:2
    for i=1:6
        objRect1 = GetRects(i*64, center1);
        pdStim = pdStim+1;
        %pause(1)
        UflickerObj( ...
            'objContrast', [.03], ...     % I put the contrasts in this order so that they will be shown (after randommization) in order of increasing contrast.
            'rects', objRect1, ...
            'objJitterPeriod', 100, ...
            'repeatObjSeq', 1, ...
            'backJitterPeriod', 1, ...
            'backMode', [0 0 1 0], ...
            'angle', 0, ...
            'backReverseFreq', 1, ...
            'barsWidth', 8, ...
            'presentationLength', 100, ...
            'movieDurationSecs', 100 ...
            );
    end
end
CreateStimuliLogWrite();

