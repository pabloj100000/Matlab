function out = GetPsychoData()
    % Run Different versions of the gating experiment
try
    tasksN = 1;
    blocksN = 3;
    trialsPerBlock = 40;
    timeDelaysN = 3;
    InitScreen(0);
    
    out = PreallocateQ(tasksN, timeDelaysN);
    
    arguments = {'trialsPerDelay', trialsPerBlock, 'backMaskSize', 2550, 'updatePlot',1};
    for i=1:blocksN
        tasksOrder = randperm(tasksN);
        for j=1:tasksN
            
            % compute Quest struct for task j
            StartingNewBlock()
            switch tasksOrder(j)
                case 1
                    q = LuminanceDiscriminationTask(arguments{:});
                case 2
                    q = FreqDiscriminationTask(arguments{:});
                case 3
                    q = ContrastDiscriminationTask(arguments{:});
                case 4
                    q = OrientationDiscriminationTask(arguments{:});
            end
            
            % Merge q into the corresponding Quest
            if (i==1)
                % if the 1st one, just store it
                out(tasksOrder(j), :) = q;
            else
                out(tasksOrder(j), :) = MergeQuests(out(tasksOrder(j), :), q);
            end             
        end
        
        PlotQuests(out)
    end

    FinishExperiment();
catch exception
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.
    CleanAfterError();
    rethrow(exception);
    psychrethrow(psychlasterror);
end
end

function PlotQuests(out)
%   out has as many quest structs as tasks
%   each quest struct is actually an array of quests
    
    Qmean = zeros(size(out));
    Qsd = zeros(size(out));
    for i=1:size(out,1)
        Qmean(i, :) = QuestMean(out(i,:));
        Qsd(i, :) = QuestSd(out(i,:));
    end
    
    x=ones(1,size(out,1))'*[0 .1 .3];
    errorbar(x', Qmean', Qsd', 'LineWidth',2)
    legend('L', 'F', 'C', 'O');
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
