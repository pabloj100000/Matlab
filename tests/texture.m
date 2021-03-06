function texture()

% Define the rectangles
global screen expLog
CreateStimuliLogStart()

InitScreen(0);
% record for 1000 + 200*2 + 2000*2 + 4000 = 9400 seconds

stimSize = 800;
barsWidth = 8;
Contrast = 1;
Tex = GetCheckersTex(stimSize, barsWidth, screen, Contrast);    
tic
for (i=1:100)
    UflickerObj2('backTexture', Tex, 'stimSize', 100, 'movieDurationSecs', 1, 'presentationLength',1)
end
toc
CreateStimuliLogWrite()
