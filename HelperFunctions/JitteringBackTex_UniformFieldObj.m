function JitteringBackTex_UniformFieldObj(jitterSeq, objSeq, ...
    waitframes, framesN, backTex, backAngle, barsWidth, pdStim)
    % Screen is divided in background and objects.
    % background will display the given texture at the given backAngle and will jitter it around
    % as specified by jitterSeq.
    % Objects will follow the intensities in objSeq
    % The time of the presentation comes in through framesN and if it is
    % longer than either jitterSeq or objSeq, then the jitter or the objSeq
    % sequences are repeated as many times as needed. In this way you can
    % have either:
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
    % objSeq:       the intensities to display in the Uniform Field obj
    % screen:       the usual screen struct.
    % waitFrames:   how often is the Flip going to be called?
    %               in general this will be either 1 or 2
    % framesN:      frames/screen.rate = totalLength of the presentation
    % backTex:      the texture to show in the background.
    % backRect:     where to display the background
    % backSource:   what part of the texture to display
    % objRect:      where to display the object
    % vbl:          time of last flip call
    % pd:           PD box definition

    global vbl screen backRect backSource objRect pd
    Add2StimLogList();

    recenterFlag=1;

    backSize = backSource(4)-backSource(2);
    y1ori = backSource(2);
    x1 = mod(backSource(1), 2*barsWidth);
%    x1 = x1ori;
    
    jumpsN = size(jitterSeq,2);
    objSeqN = size(objSeq, 2);
    
    for frame=0:framesN-1
        if (mod(frame, waitframes)==0)
%            backIndex = mod(frame/waitframes, jumpsN)+1;
            backIndex = mod(frame, jumpsN)+1;
            x1 = x1 + jitterSeq(backIndex);
            if (recenterFlag)
                x1 = mod(x1, 2*barsWidth);
            end
            backSource = x1*[1 0 1 0] + y1ori*[0 1 0 1] + backSize*[0 0 1 1];
            Screen('FillRect', screen.w, screen.gray, screen.rect);

            % Disable alpha-blending, restrict following drawing to alpha channel:
            Screen('Blendfunction', screen.w, GL_ONE, GL_ZERO, [0 0 0 1]);

            % Clear 'dstRect' region of framebuffers alpha channel to zero:
    %        Screen('FillRect', screen.w, [0 0 0 0], backRect);
            Screen('FillRect', screen.w, [0 0 0 0], screen.rect);

            % Fill circular 'dstRect' region with an alpha value of 255:
            Screen('FillOval', screen.w, [0 0 0 255], backRect);

            % Enable DeSTination alpha blending and reenalbe drawing to all
            % color channels. Following drawing commands will only draw there
            % the alpha value in the framebuffer is greater than zero, ie., in
            % our case, inside the circular 'dst2Rect' aperture where alpha has
            % been set to 255 by our 'FillOval' command:
            Screen('Blendfunction', screen.w, GL_DST_ALPHA, GL_ONE_MINUS_DST_ALPHA, [1 1 1 1]);

            % Draw 2nd grating texture, but only inside alpha == 255 circular
            % aperture, and at an angle of 90 degrees:
            Screen('DrawTexture', screen.w, backTex, backSource, backRect, backAngle,0)

            % Restore alpha blending mode for next draw iteration:
            Screen('Blendfunction', screen.w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);


            % Object Drawing
            % --------------
            for i=1:size(objRect,1)
                objIndex = mod(frame/waitframes, objSeqN)+1;
                objColor = objSeq(i, objIndex);
                Screen('FillRect', screen.w, objColor, objRect(i,:));
            end
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

