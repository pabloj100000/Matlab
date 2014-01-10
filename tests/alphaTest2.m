% I want to have a list of natural scenes and checkers
% and then combine two of those images such that  the center is given by
% centerIm at centerContrast and centerMean and the periphery is given by
% periIm at periContrast and periMean.

% Implementation
% Enable alpha masking
% First generate all the textures that I'm going to use.
% Then chose textures for center and peirphery
% 
function AlphaTest2()
    % Two textures are rocked back and forth following FEM + saccades.
    % periIndex:    -1 uses checkers
    %               >=5 uses images
    % periAlpha:    between 0 and 1
    % periMeanLum:  between -127 and 127, is the deviation from gray.
    %
    % obj Parameters are the same except that center can not be checkers.
    %
    % Usage (interesting ones):
    % SaccadesAndFEM('objAlpha', 0, 'periAlpha', 1)
    % SaccadesAndFEM('objAlpha', 0, 'periAlpha', 1, 'periIndex', -1)
    % SaccadesAndFEM('objAlpha', 0, 'periAlpha', 1, 'objMeanLum', -127)
    % SaccadesAndFEM('objAlpha', 1, 'periAlpha', 1, 'objMeanLum', -127, 'periMeanLum', 127)
global screen
    
    InitScreen(0);
    
    % display 4 checkers at 4 different colors
    ctrl = [0 63 127 255];
    rect = SetRect(0, 0, screen.rect(3)/4, screen.rect(4)/2);
    rect1 = OffsetRect(rect, screen.rect(3)/4, 0);
    rect2 = OffsetRect(rect1, screen.rect(3)/4, 0);
    rect3 = OffsetRect(rect2, screen.rect(3)/4, 0);

    rect4 = offsetRect(rect, 0, screen.rect(4)/2);
    rect5 = offsetRect(rect1, 0, screen.rect(4)/2);
    rect6 = offsetRect(rect2, 0, screen.rect(4)/2);
    rect7 = offsetRect(rect3, 0, screen.rect(4)/2);
    
    Screen('FillRect', screen.w, 0, rect);
    Screen('FillRect', screen.w, 63, rect1);
    Screen('FillRect', screen.w, 127, rect2);
    Screen('FillRect', screen.w, 255, rect3);

    array=ones(2,2)*255;
    tex = Screen('MakeTexture', screen.w, array);
    Screen('BlendFunction', screen.w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
% {
    Screen('FillRect', screen.w, 0, rect4);
    Screen('FillRect', screen.w, 0, rect5);
    Screen('FillRect', screen.w, 0, rect6);
    Screen('FillRect', screen.w, 0, rect7);
    Screen('DrawTexture', screen.w, tex, [], rect4, [], [], 0);
    Screen('DrawTexture', screen.w, tex, [], rect5, [], [], 63/255);
    Screen('DrawTexture', screen.w, tex, [], rect6, [], [], 127/255);
    Screen('DrawTexture', screen.w, tex, [], rect7, [], [], 255/255);
%}    
    Screen('Flip', screen.w);

    pause(1)
    
    CleanAfterError();
end

