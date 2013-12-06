function JitteringBackTex_RandContrRF(framesN, jitterSeq, objSeq, ...
            waitframes, backTex, pdStim)
     

    global vbl screen backRect backSource objRect pd 
    Add2StimLogList();

    % init the frame counter
    frame = 0;
    
    jumpsN = size(jitterSeq,2);
    
    while (frame < framesN) & ~KbCheck %#ok<AND2>
        
        backIndex = mod(frame/waitframes, jumpsN)+1;
        backSource = backSource + jitterSeq(backIndex)*[1 0 1 0];

        Screen('DrawTexture', screen.w, backTex, backSource, backRect, 0,0)

        % Object Drawing
        % --------------
        
        objColor = objSeq(:,:, frame+1);
        objTex  = Screen('MakeTexture', screen.w, objColor);
        Screen('DrawTexture', screen.w, objTex, [], objRect, 0, 0);

        % After drawing, we have to discard the noise checkTexture.
        Screen('Close', objTex);


        % Photodiode box
        % --------------
        DisplayStimInPD2(pdStim, pd, frame, screen.rate, screen)

        % Flip 'waitframes' monitor refresh intervals after last redraw.
        vbl = Screen('Flip', screen.w, vbl + (waitframes - 0.5) * screen.ifi);
        frame = frame + waitframes;

    end
end
