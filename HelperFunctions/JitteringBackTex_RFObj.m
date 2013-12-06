function JitteringBackTex_RFObj(jitterSeq, checkersN, ...
    waitframes, framesN, objContrast, backTex, pdStim)
    % Screen is divided in background and object.
    % background will display the given texture and will jitter it around
    % as specified by jitterSeq.
    % Object will be random binary checkers.
    % The time of the presentation comes in through framesN and if it is
    % longer than jitterSeq, then the jitter is repeated as many times as
    % needed. In this way you can have either:
    %   one background and one object
    %   one background with different objects
    %   different backgrounds with one object
    %
    % This procedure can also be used for reverse grating backgrounds, just
    % define the background to be the grating texture and define jitterSeq
    % to something like jitterSeq = [J 0 0 0 0 0 0 0 0 -J 0 0 0 0 0 0 0 0]
    % were the J is the size of the jump and the 0s are the frames where
    % the background is still
    % jitterSeq:    an array describing how many pixels to jump
    %               at each frame (+ to the right, - to the left)
    % checkerN:     Number of checkers in either horizontal or vertical
    %               direction
    % waitFrames:   how often is the Flip going to be called?
    %               in general this will be either 1 or 2
    % framesN:      frames/screen.rate = totalLength of the presentation
    % backTex:      the texture to show in the background.

    global vbl screen backRect backSource objRect pd
    Add2StimLogList();
    
    jumpsN = size(jitterSeq,2);
    
    for frame=0:framesN-1
        if mod(frame, waitframes)==0
            backIndex = mod(frame/waitframes, jumpsN)+1;
            backSource = backSource + jitterSeq(backIndex)*[1 0 1 0];
            
            Screen('DrawTexture', screen.w, backTex, backSource, backRect, 0,0)
            
            % Object Drawing
            % --------------
            
            objColor = (rand(checkersN, checkersN)>.5)*2*screen.gray*objContrast...
                + screen.gray*(1-objContrast);
            objTex  = Screen('MakeTexture', screen.w, objColor);
            Screen('DrawTexture', screen.w, objTex, [], objRect, 0, 0);
            
            % After drawing, we have to discard the noise checkTexture.
            Screen('Close', objTex);
        end
        

        % Photodiode box
        % --------------
        DisplayStimInPD2(pdStim, pd, frame, screen.rate, screen)

        % Flip 'waitframes' monitor refresh intervals after last redraw.
        vbl = Screen('Flip', screen.w, vbl + 0.5 * screen.ifi, 1);

        if KbCheck
            break
        end
    end
end
