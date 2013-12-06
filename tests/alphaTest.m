function alphaTest()
    % Have two textures (center and periphery)
    global screen
try    
    AssertOpenGL;
    screenid = max(Screen('Screens'));
    % Open a fullscreen, onscreen window with gray background. Enable 32bpc
    % floating point framebuffer via imaging pipeline on it, if this is possible
    % on your hardware while alpha-blending is enabled. Otherwise use a 16bpc
    % precision framebuffer together with alpha-blending. We need alpha-blending
    % here to implement the nice superposition of overlapping gabors. The demo will
    % abort if your graphics hardware is not capable of any of this.
    PsychImaging('PrepareConfiguration');
    PsychImaging('AddTask', 'General', 'FloatingPoint32BitIfPossible');
    [screen.w screen.rect] = PsychImaging('OpenWindow', screenid, 128);
    screen.vbl = 0;
    screen.ifi = Screen('GetFlipInterval', screen.w);
    
    % Enable alpha-blending, set it to a blend equation useable for linear
    % superposition with alpha-weighted source. This allows to linearly
    % superimpose gabor patches in the mathematically correct manner, should
    % they overlap. Alpha-weighted source means: The 'globalAlpha' parameter in
    % the 'DrawTextures' can be used to modulate the intensity of each pixel of
    % the drawn patch before it is superimposed to the framebuffer image, ie.,
    % it allows to specify a global per-patch contrast value:
    Screen('BlendFunction', screen.w, GL_SRC_ALPHA, GL_ONE);

    mean1 = 128;
    contrast1 = .5;
    mean2 = 128;
    contrast2 = .5;
    waitframes=3;
    checkerSize = 16;
    
    pd = DefinePD();

    array = (rand(32, 32)>.5)*2*mean1*contrast1 + mean1*(1-contrast1);
    objTex1  = Screen('MakeTexture', screen.w, array);
    
    array = (rand(2, 2)>.5)*2*mean1*contrast2 + mean2*(1-contrast2);
    objTex2  = Screen('MakeTexture', screen.w, array);

    objRect0 = GetScreenSubRect(2,3,0);
    objRect1 = GetScreenSubRect(2,3,1);
    objRect2 = GetScreenSubRect(2,3,2);
    objRect3 = GetScreenSubRect(2,3,3);
    objRect4 = GetScreenSubRect(2,3,4);
    objRect5 = GetScreenSubRect(2,3,5);

    for frame=0:1000
        % display last texture
        Screen('DrawTexture', screen.w, objTex1, [], objRect0, 0, 0);
        
        % display last texture
        Screen('DrawTexture', screen.w, objTex2, [], objRect1, 0, 0);

        % display last texture
        Screen('DrawTexture', screen.w, objTex1, [], objRect2, 0, 0, .5);

        Screen('DrawTexture', screen.w, objTex2, [], objRect3, 0, 0, .5);

        Screen('DrawTexture', screen.w, objTex1, [], objRect4, 0, 0, .5);
        Screen('DrawTexture', screen.w, objTex2, [], objRect4, 0, 0, .5);
        
        %        Screen('FillOval', screen.w, color, pd);
        
        % uncomment this line to check the coordinates of the 1st checker
        % Flip 'waitframes' monitor refresh intervals after last redraw.
        screen.vbl = Screen('Flip', screen.w, screen.vbl + (waitframes-.5) * screen.ifi);

        if (KbCheck)
            break
        end
    end
 
    % We have to discard the noise checkTexture.
    Screen('Close', objTex1);
    clear Screen
    clear global
    clear global expLog
    clear global screen
    clear global StimLogList
    Screen('CloseAll');         % Close all open onscreen and offscreen
                                % windows and textures, movies and video
                                % sources. Release nearly all ressources.
    Priority(0);
    ShowCursor();
    
catch exception
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.
    CleanAfterError();
    rethrow(exception);
end %try..catch..end
