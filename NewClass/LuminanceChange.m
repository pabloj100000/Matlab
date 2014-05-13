function LuminanceChange()
    % wrapper to call ShowOneLuminanceChange, 
    % just toggle between different luminance levels, trying to find sets
    % of values for which cells will not respond. It allows to have
    % fractional Luminance values (ie, 127.5 or 127.2). I'm just drawing
    % many tiny rectangles and the average across all rectangles is the
    % desired luminance. Each tiny rectangle is either ceil(Luminance) or
    % floor(Luminance) and they are evenly spaced throught the larger
    % rectangle.
    % if you want to make sure it is working change the checkerSize
    % parameter from 2 to something larger like 10 or 20 (is in pixels)
 
try
    InitScreen(0)
    Add2StimLogList();

    repeatsN = 20;
    ShowOneLuminanceChange([127, 127.25], repeatsN, 1);
    ShowOneLuminanceChange([127, 127.5], repeatsN, 1);
    ShowOneLuminanceChange([127, 128], repeatsN, 1);
    ShowOneLuminanceChange([127, 129], repeatsN, 1);
    ShowOneLuminanceChange([127, 130], repeatsN, 1);
    
    ShowOneLuminanceChange([250, 250.25], 60+repeatsN, 1);  % adapt to new mean first
    ShowOneLuminanceChange([250, 250.5], repeatsN, 1);
    ShowOneLuminanceChange([250, 251], repeatsN, 1);
    ShowOneLuminanceChange([250, 252], repeatsN, 1);
    ShowOneLuminanceChange([250, 253], repeatsN, 1);
    ShowOneLuminanceChange([250, 254], repeatsN, 1);
    ShowOneLuminanceChange([250, 255], repeatsN, 1);
    FinishExperiment();
        
catch exception
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.
    CleanAfterError();
    rethrow(exception)
end %try..catch..
end

function ShowOneLuminanceChange(Luminance, repeatsN, fixationLength)
    global screen
   
    % start the stimulus

    if ~all(size(Luminance)==[1 2])
        error('Luminance has to be of size [1 2]')
    end
    
    objSize = 12*PIXELS_PER_100_MICRONS;
    checkerSize = 2;%round(PIXELS_PER_100_MICRONS/4);
    objSize = round(objSize/checkerSize)*checkerSize;
    checkersNinX = objSize/checkerSize;
    checkersN = checkersNinX^2;
    Xoffset = screen.center(1)-checkersNinX/2*checkerSize;
    Yoffset = screen.center(2)-checkersNinX/2*checkerSize;
    
    checkers = tileCheckers(checkersNinX, checkersNinX, checkerSize, checkerSize,...
    Xoffset, Yoffset, checkerSize, checkerSize);

    % change fixationLength into frames and force it to be an even number.
    framesPerFixation = round(fixationLength*screen.rate/screen.waitframes/2)*2;
        
    % Define the PD box
    pd = DefinePD();
    
    Screen('FillRect', screen.w, screen.gray);
    
    colors1 = GetColors(Luminance(1), checkersN);
    colors2 = GetColors(Luminance(2), checkersN);
    mean([colors1(:) colors2(:)])
    
    for repeat = 1:repeatsN
        
        
        for frame = 0:2*framesPerFixation - 1
            
            if (frame==0)
                lum = colors1;
            elseif (frame==framesPerFixation-1)
                lum = colors2;
%            lum = ones(3, 1)*ones(1, checkersN)*Luminance(floor(frame/framesPerFixation)+1);
            end
            
            if (frame==0)
                pdColor = 255;
            else
                pdColor = lum(1,1)/2;
            end

            Screen('FillRect', screen.w, lum, checkers);

            Screen('FillOval', screen.w, pdColor, pd);
            
            screen.vbl = Screen('Flip', screen.w, screen.vbl + (screen.waitframes - 0.5) * screen.ifi);

            if KbCheck
                break
            end
        end
        if KbCheck
            break
        end
    end
    

end

function [colors] = GetColors(Luminance, checkersN)
    % Given values for Luminance, return colors that are arrays
    % of size (3, checkersN) with the color of each checker.
    % The idea is that the mean value of the checkers in colors will be
    % Luminance. This will allow me for example to say Luminance=127.5 and
    % in this case, colors will be 127
    % and half 128.
    L1 = floor(Luminance);
    L2 = ceil(Luminance);
    
    if L1==L2
        colors = ones(3, checkersN)*L1;
        return
    end
    
    %n11 + n12 = checkersN
    % n11*L1 + n12*L2 = Luminance(1)
%    n11 = checkersN*(L2-Luminance(1))/(L2-L1);
    n12 = round(checkersN*(Luminance-L1)/(L2-L1));
    
    colors = ones(3,checkersN)*L1;
    if n12
        colors(:, 1:checkersN/n12:checkersN) = L2;
    end
end
