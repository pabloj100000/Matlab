function testNaturalScene()

global screen
InitScreen(0);

for i=0:3
    spatialPeriod = 16*2^i;
    saccade = spatialPeriod/4*[0 1 2 3; 0 0 0 0];
    for j=0:3
        contrast = .03*2^j;
        checkers = GetCheckers(1024, 768, spatialPeriod/2, contrast, screen.gray);
        tex = Screen('MakeTexture', screen.w, checkers);
        probeEyeMovements(tex, 'saccade', saccade)
        Screen('Close', tex)
        pause(.2)
    end
end
%{
tex = GetCheckersTex(48,1,screen, 1);
sourceRect=[0 0 47 47];
destRect = GetRects(768, screen.center);
NaturalScene3( tex{1}, destRect, 'sourceRect', sourceRect);

pause(.2)
im = imread('../Images/NaturalScene.jpg');
tex = Screen('MakeTexture', screen.w, im);
sourceRect=SetRect(0, 0, size(im,2)-1, size(im,1)-1);
destRect = SetRect(0,0,size(im,1), size(im,2));
destRect = CenterRectOnPoint(destRect, screen.center(1), screen.center(2));
NaturalScene3( tex, destRect, 'sourceRect', sourceRect);
%}
FinishExperiment();

