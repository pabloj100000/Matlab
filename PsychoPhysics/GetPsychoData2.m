function out = GetPsychoData2(task)
    % Run Different versions of the gating experiment
try
    tic
    blocksN = 3;
    trialsPerBlock = 40;
    timeDelaysN = 3;
    InitScreen(0);
    
    out = PreallocateQ(1, timeDelaysN);
    sharedArguments = {'trialsPerDelay', trialsPerBlock,...
                    'updatePlot',1};%, ...
%                    'contrast', .35};
    for i=1:blocksN
%        tasksOrder = task;
        for j=1:2
            if j==1
                arguments = {'backMaskSize', 2550, sharedArguments{:}};
            else
                arguments = {'backMaskSize', 150, sharedArguments{:}};
            end
            
            % compute Quest struct for task j
            StartingNewBlock()
            switch task;%tasksOrder(j)
                case 1
                    q = LuminanceDiscriminationTask(arguments{:});
                case 2
                    q = FreqDiscriminationTask(arguments{:});
                case 3
                    q = ContrastDiscriminationTask(arguments{:});
                case 4
                    q = OrientationDiscriminationTask(arguments{:});
                case 5
                    q = HeightDiscriminationTask(arguments{:});
            end
            
            % Merge q into the corresponding Quest
            if (i==1)
                % if the 1st one, just store it
                out(j, :) = q;
            else
                out(j, :) = MergeQuests(out(j, :), q);
            end             
        end
%        figure(2); PlotQuests(q)
        figure(1); PlotQuests(out)
    end

    FinishExperiment();
    toc
catch exception
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.
    CleanAfterError();
%    psychrethrow(psychlasterror);
    rethrow(exception);
end
end

function out = PreallocateQ(tasksN, timeDelaysN)
tGuess = 1;
tGuessSd = 2;
pThreshold=0.82;
beta=3.5;delta=0.01;gamma=0.5;
q = QuestCreate(tGuess,tGuessSd,pThreshold,beta,delta,gamma, .1, 10);
q.normlizedPdf = 1;
out(tasksN, timeDelaysN)=q;
end

function StartingNewBlock()
    global screen
    
    Screen('FillRect', screen.w, screen.gray);
    Screen('TextSize', screen.w, 32);
    Screen('DrawText', screen.w, 'About to start a new block', 300, 400);
    Screen('DrawText', screen.w, 'Press ''Exc'' to continue', 400, 500);
    Screen('Flip', screen.w);
    
    KbName('UnifyKeyNames');
    ESCAPE = KbName('escape');
    while (1)
        [~, ~, keyCode] = KbCheck;
        
        if keyCode(ESCAPE)
            break
        end
    end
    pause(.2)
end
