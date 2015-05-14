function test()

[screen.w screen.rect] = Screen('OpenWindow',0, [0 0 0]);

% Draw a red square
Screen('FillRect', screen.w, [255 0 0], [0 0 200 200]);
Screen('Flip', screen.w);
pause(1);

% disable writing to the red channel 
Screen('Blendfunction', screen.w, GL_ONE, GL_ZERO, [0 1 1 1]);

% Draw to R and G channels, but only G pixels should draw
Screen('FillRect', screen.w, [255 255 0], [100 0 300 200]);
Screen('Flip', screen.w);
pause(1);

Screen('Flip', screen.w);
pause(1);

% Write only to the alpha channel
Screen('Blendfunction', screen.w, GL_ONE, GL_ZERO, [0 0 0 1]);
% Set alpha to 0 in a small square
Screen('FillRect', screen.w, [0 0 0 0], [0 0 200 200]);
% Reenable writing to RGB channels
Screen('Blendfunction', screen.w, GL_ONE, GL_ZERO, [1 1 1 0]);
% Draw in a region that overlaps with the previuos one. I expect only part of the
% square should be drawn
Screen('FillRect', screen.w, [255 255 255], [100 0 300 200]);
Screen('Flip', screen.w);
pause(1);

Screen('Flip', screen.w);
pause(1);

% same example but writing 255 in the alpha channel
Screen('Blendfunction', screen.w, GL_ONE, GL_ZERO, [0 0 0 1]);
Screen('FillRect', screen.w, [0 0 0 255], [0 0 200 200]);
Screen('Blendfunction', screen.w, GL_ONE, GL_ZERO, [1 1 1 0]);
Screen('FillRect', screen.w, [255 255 255], [100 0 300 200]);
Screen('Flip', screen.w);
pause(1);

sca;