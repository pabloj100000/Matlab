function TNF2Wrapper()
%   modify as needed

InitScreen(0)
Add2StimLogList();
%commonFlags = ['resetFixationSeed', 1, 'blocksN', 1, 'repeatsPerBlock', 1];

for i=1:2
    TNF2('contrast', 0, 'resetFixationSeed', 1, 'blocksN', 1, 'repeatsPerBlock', 1);
    TNF2('contrast', .03, 'resetFixationSeed', 1, 'blocksN', 1, 'repeatsPerBlock', 1);
    TNF2('contrast', .15, 'resetFixationSeed', 1, 'blocksN', 1, 'repeatsPerBlock', 1);    
end

FinishExperiment();
