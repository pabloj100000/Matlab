function probeFreq()
global screen
    
try
    Add2StimLogList();


    % start the stimulus
    InitScreen(0)

    % Define the PD box
    pd = DefinePD();
    totalFrames=0;
    
    halfPeriod = [2 1 .5 .25 .1];
    repeatsN = 20;
    for i=1:length(halfPeriod)
        framesN = round(halfPeriod(i)/screen.ifi);
        for repeat =1:2*repeatsN
            for frames=1:framesN
                Screen('FillRect', screen.w, 255*mod(repeat,2));

                if (mod(totalFrames,screen.rate)==0)
                    Screen('FillOval', screen.w, screen.white, pd);
                else
                    Screen('FillOval', screen.w, screen.black, pd);
                end

                screen.vbl = Screen('Flip', screen.w, screen.vbl + screen.ifi/2 , 1);
                totalFrames = totalFrames+1;
                if (KbCheck)
                    break
                end
            end
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
    rethrow(exception)
end %try..catch..
end

