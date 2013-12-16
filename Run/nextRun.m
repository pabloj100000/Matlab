function nextRun()

try
    Add2StimLogList();
%    Wait2Start()

    RF('movieDurationSecs', 1000)
    pause(.2)

    PL = 50;
    mr = 5*PIXELS_PER_100_MICRONS;
    sz = PIXELS_PER_100_MICRONS/2;
    images = [0 7 10 12 14 18];
    alphas = [.025 .05 .1 .2 .4];
    for block=0:1
        % Sky doesn't dissapear
        SaccadesAndFEM('objAlpha', 0, 'periAlpha', 1, 'objMeanLum', -127, 'periIndex', -1, 'presentationLength', PL, 'pdMode',1, 'saccadeSize', sz, 'maskRadia', mr)
        SaccadesAndFEM('objAlpha', 0, 'periAlpha', 1, 'objMeanLum', 0, 'periIndex', -1, 'presentationLength', PL, 'pdMode',1, 'saccadeSize', sz, 'maskRadia', mr)
        SaccadesAndFEM('objAlpha', 0, 'periAlpha', 1, 'objMeanLum', 127, 'periIndex', -1, 'presentationLength', PL, 'pdMode',1, 'saccadeSize', sz, 'maskRadia', mr)

        for i=1:length(images)
            % Object plus full contrast periphery
            SaccadesAndFEM('objAlpha', 0, 'presentationLength', PL, 'periIndex', images(i), 'objIndex', images(i), 'pdMode',1, 'saccadeSize', sz, 'maskRadia', mr);
            if (KbCheck)
                break
            end
        end
        
        for i=1:length(images)
            nextImage = mod(i, length(images))+1;
            for j = 1:length(alphas)

                % Object only
                SaccadesAndFEM('objAlpha', alphas(j), 'presentationLength', PL, 'periIndex', images(i), 'objIndex', images(i), 'periAlpha', 0, 'pdMode',1, 'saccadeSize', sz, 'maskRadia', mr);
                
                % Object plus full contrast periphery
                SaccadesAndFEM('objAlpha', alphas(j), 'presentationLength', PL, 'periIndex', images(i), 'objIndex', images(i), 'pdMode',1, 'saccadeSize', sz, 'maskRadia', mr);
                
                % Object plus full contrast periphery but different
                % periphery
                SaccadesAndFEM('objAlpha', alphas(j), 'presentationLength', PL, 'periIndex', images(i), 'objIndex', images(nextImage), 'pdMode',1, 'saccadeSize', sz, 'maskRadia', mr);

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
% }
    FinishExperiment();
    
catch exception
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.
    CleanAfterError();
    rethrow(exception)
end %try..catch..

end
