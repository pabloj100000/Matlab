function TestGabor()
global screen

InitScreen(0);
tic
for i=0:10
    tex = GetGaborText2(100,10,10,0,i/10);
    Screen('Flip', screen.w);
    Screen('DrawTexture', screen.w, tex);
    Screen('Flip', screen.w);
    pause(2)
    Screen('Close', tex);
end
t=toc;
fprintf('%f', t/1000)
%{
%}
Screen('CloseAll')
clear global
