function run072910_a()
CreateStimuliLogStart();

Wait2Start()
RF('movieDurationSecs', 900, 'barsWidth',16, 'objContrast',1);

objContrast = [.05 .20 .35];
backContrast = [.05 .35 1];
movieDuration = 11*3*15;        % roughly 500 secs

for globalRepeat = 1:2
    for i=1:length(objContrast)
        objC = objContrast(i);
        for j=1:length(backContrast)
            backC = backContrast(j);

            UFlickerObj_SSF( ...
                'objContrast', objC, ...
                'backContrast', backC, ...
                'movieDurationSecs', movieDuration, ...
                'pdStim', j+length(backContrast)*(i-1));
        end
    end
    UFlickerObj_SSF( ...
        'objContrast', .05, ...
        'backContrast', 0, ...
        'movieDurationSecs', 11*15, ...
        'pdStim', 0);
    
end

CreateStimuliLogWrite();
end

