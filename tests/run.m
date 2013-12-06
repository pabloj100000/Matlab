function run()
try
    CreateStimuliLogStart()
    LoadHelperFunctions();

    % general global variables
    global screen presentationLength waitframes vbl

    % object related global variables
    global objSizeH objSizeV objCenterXY objJitterPeriod objSeed


    % background related global variables
    global stimSize barsWidth backContrast backSeed
    
    debugging = 0;
    if debugging
        movieDurationSecs = 10;
    else
        movieDurationSecs = 1640;
    end

    stimSize = 600;
    objSizeH = 16*12;
    objSizeV = 16*12;
    objCenterXY = [0 0];
    barsWidth = 7;
    backContrast = 1;
    objJitterPeriod = 11;
    presentationLength = 11;
    objSeed = 1;
    backSeed = 1;
    waitframes = 1;
    InitScreen(debugging);
    InitScreen(debugging);
    InitScreen(debugging);
    Screen('Flip', screen.w);

    
    % Start with some RF
    checkersN_H=32;
    checkersN_V=32;
    checkerSize = 16;
    objContrast = 1;
    seed = 1;

    pdStim = 250;
    vbl = RF(debugging, checkersN_H, checkersN_V, checkerSize, objContrast...
        ,vbl, seed, waitframes, movieDurationSecs, pdStim, screen);

    
    % Naturalistic stimulus, can eye movements help encode low contrast
    % stimulus?
    pdStim = 1;
    movieDurationSecs=22;
    objContrast = .05;
    vbl = LowContrastObj_FixEyeMovements(debugging, stimSize, ...
        objSizeH, objSizeV, objCenterXY, barsWidth, backContrast, objContrast, ...
        vbl, objJitterPeriod, presentationLength, objSeed, ...
        waitframes, movieDurationSecs, pdStim, screen);

    % Building an LN model, with LC and HC random flickering
    backJitterPeriod = 1;
    if (~debugging)
        movieDurationSecs=movieDurationSecs/4;
    end
    for i=1:2
        objContrast = .05;
        pdStim = 2;
        vbl = ShiftEffect_RF4(debugging, stimSize, ...
            objSizeH, objSizeV, objCenterXY, barsWidth, backContrast, objContrast, ...
            vbl, backJitterPeriod, objJitterPeriod, presentationLength, objSeed, ...
            waitframes, movieDurationSecs, pdStim, screen);

        pdStim = 3;
        objContrast = .35;
        vbl = ShiftEffect_RF4(debugging, stimSize, ...
            objSizeH, objSizeV, objCenterXY, barsWidth, backContrast, objContrast, ...
            vbl, backJitterPeriod, objJitterPeriod, presentationLength, objSeed, ...
            waitframes, movieDurationSecs, pdStim, screen);
    end

    movieDurationSecs=22;
    pdStim = 4;
    objIntensities = 1:4;
    objIntensities = objIntensities.*256/size(objIntensities,2);
    objIntensities = objIntensities-mean(objIntensities)+127;
    StableObject_FixEyeMovements(debugging, stimSize, ...
        objSizeH, objSizeV, objCenterXY, barsWidth, backContrast, objIntensities, ...
        vbl, backJitterPeriod, presentationLength, backSeed, ...
        waitframes, movieDurationSecs, pdStim, screen)


    % Finish up
    clean()

    if ~debugging
        doSave = menu('Do you want to save a log of the stimulus?', 'yes', 'no');
        if (doSave==1)
            CreateStimuliLog([], mfilename);
        end
    end
catch
    clean()
end
end

function clean()
    showCursor();
    clear Screen;
    clear global;
    Priority(0);
end
function LoadHelperFunctions()
    % load Helper functions
    oldDir = pwd;
    cd ..
    cd('HelperFunctions');
    addpath(genpath(pwd));
    cd ..
    cd('NewClass');
    addpath(genpath(pwd));
    cd(oldDir)
end
