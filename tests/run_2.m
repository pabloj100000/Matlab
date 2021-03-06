% File executed on: 19-Jul-2010 11:39:38
function run()
    CreateStimuliLogStart();
    LowContrastObj_FixEyeMovements('movieDurationSecs',1, 'presentationLength',1);
    RandomBackground('movieDurationSecs',1, 'presentationLength',1);
    RandomBackground2('movieDurationSecs',1, 'presentationLength',1);
    RandomBackground3('movieDurationSecs',1, 'presentationLength',1);
    RandomBackgroundSpeed('movieDurationSecs',1, 'presentationLength',1);
    RF('movieDurationSecs',1, 'presentationLength',1);
    ShiftEffect_RF3('movieDurationSecs',5, 'presentationLength',1);
    ShiftEffect_RF4('movieDurationSecs',1, 'presentationLength',1);
    Stable_Object('movieDurationSecs',1, 'presentationLength',1);
    StableObject_FixEyeMovements('movieDurationSecs',1, 'presentationLength',1);
    VariableSpeedJumpsInBackground('movieDurationSecs',1, 'presentationLength',1);
    RF('movieDurationSecs',1, 'presentationLength',1, 'objContrast',1);
    ShiftEffect_RF3('movieDurationSecs',5, 'presentationLength',1, 'objContrast',1, 'objCenterXY', [100 200]);
    RF('movieDurationSecs', 2, 'objContrast', .5, 'barsWidth', 16);
    CreateStimuliLogWrite();


end

function [exitFlag] = BinaryCheckers(screen, framesN, waitframes, checkersV, checkersH, objContrast,...
        objRect, pd, pdStim)
    exitFlag = -1;
    frame = 0;
    global vbl
    
    while (frame < framesN) & ~KbCheck %#ok<AND2>


        
        % CENTER REGION
        % ------ ------
        % Make and display obj texture
        objColor = (rand(checkersH, checkersV)>.5)*2*screen.gray*objContrast...
            + screen.gray*(1-objContrast);
        objTex  = Screen('MakeTexture', screen.w, objColor);
        Screen('DrawTexture', screen.w, objTex, [], objRect, 0, 0);

        % After drawing, we have to discard the noise checkTexture.
        Screen('Close', objTex);

        % PD
        % --
        % Draw the PD box
        DisplayStimInPD2(pdStim, pd, frame, 60, screen)
        
        % Flip 'waitframes' monitor refresh intervals after last redraw.
        vbl = Screen('Flip', screen.w, vbl + (waitframes - 0.5) * screen.ifi);
        frame = frame + waitframes;
    end;
    if (frame >= framesN)
        exitFlag = 1;
    end
end

function CreateStimuliLog(k, name)
% Creates a log file with calling parameters and all functions in
% HelperFunctions.
% this coding is a mess because ...
% I don't know how to cat in matlab and ...
% I am distinguishing between unix and pc and my coding in dos sucks.

    % get the output name to use
    basename = [name,'_'];
    i=1;
    fileOut = [basename, num2str(i),'.m'];
    % check if file exists in current directory
    while ( exist(fileOut,'file') )
        % append a number to it.
        i = i+1;
        fileOut = [basename, num2str(i), '.m'];
    end

    % work from the HelperFunctions dir
    oldDir = pwd;
    cd ..;
    cd('HelperFunctions')
       
        
    if (isunix())
        oldDir = [oldDir, '/'];
        fileOut = [oldDir, fileOut];
        fileIn = which(name);%[oldDir, name, '.m'];
    
        % Open the file and write the parameters used in the calling
        fid = fopen(fileOut, 'w');
        text = ['%% File executed on: ', datestr(clock), '\n'];
        fprintf(fid, text);

        if (isfield(k, 'labels'))


            fprintf(fid, '%% Function called with the following list of parameters\n');
            for i=1:size(k.labels, 2)
                if(isnumeric(k.args{i}))
                    fprintf(fid, '%% %s = %s\n', k.labels{i}, num2str(k.args{i}));
                else
                    fprintf(fid, '%% %s = %s\n', k.labels{i}, k.args{i});
                end
            end
            fprintf(fid, '\n');

        end
        fclose(fid);

        % cat this specific experiment file into the log file 
        cmd = ['cat ',fileIn, ' >> ', fileOut];
        unix(cmd);

        % cat everything in the HelperFunctions dir
        helperFiles = dir('*.m');
        for i=3:size(helperFiles,1)     % skips . and ..
            cmd = ['cat ',helperFiles(i).name, ' >> ', fileOut];
            unix(cmd);
        end
    elseif (ispc())
        oldDir = [oldDir, '\'];
        fileOut = [oldDir, fileOut];
        fileIn = [oldDir, '\', name, '.m'];

        
        % Open a dummy 'params.txt' file and write the parameters used in the calling
        fid = fopen('params.txt', 'w');

        text = ['%% File executed on: ', datestr(clock), '\n'];
        fprintf(fid, text);

        if (isfield(k, 'labels'))
            fprintf(fid, '%% Function called with the following list of parameters\n');
            for i=1:size(k.labels, 2)
                if(isnumeric(k.args{i}))
                    fprintf(fid, '%% %s = %g\n', k.labels{i}, k.args{i});
                else
                    fprintf(fid, '%% %s = %s\n', k.labels{i}, k.args{i});
                end
            end
        end
        fclose(fid);
        
        % start generating the copy command
        cmd = ['copy /a params.txt+',fileIn];

        % look for all .m files in the working directory
        helperFiles = dir('*.m');
        for i=1:size(helperFiles,1)    
            newFile = helperFiles(i).name;
            if (strcmp(newFile(1), '.'))
                continue % skip files of the form .*
            else
                cmd = [cmd, '+', newFile];
            end
        end
        cmd = [cmd, ' ', fileOut];
        dos(cmd)
        dos('del params.txt')
    end
    
    cd(oldDir)
end

function CreateStimuliLog2(args, labels, name)
% Creates a log file with calling parameters and all functions in
% HelperFunctions.
% this coding is a mess because ...
% I don't know how to cat in matlab and ...
% I am distinguishing between unix and pc and my coding in dos sucks.

    % get the output name to use
    basename = [name,'_'];
    i=1;
    name = [basename, num2str(i)];
    ext = '.m';
    % check if file exists in current directory
    while ( exist([name,ext],'file') )
        % append a number to it.
        name = [basename, num2str(i)];
        i = i+1;
    end
    fileOut=[name, ext];

    % work from the HelperFunctions dir
    oldDir = pwd;
    if (strcmp('/Applications/Psychtoolbox/stimuli/Pablo', pwd) || ...
            strcmp('C:\Apps\Psychtoolbox\stimulus\Pablo', pwd))
        cd 'HelperFunctions'
    else
        cd ../HelperFunctions
    end
        
        
    if (isunix())
        oldDir = [oldDir, '/'];
        fileOut = [oldDir, fileOut];
    
        % Open the file and write the parameters used in the calling
        fid = fopen(fileOut, 'w');

        fprintf(fid, '%% Function called with the following list of parameters\n');
        for i=1:size(labels, 2)
            if(isnumeric(args{i}))
                fprintf(fid, '%% %s = %s\n', labels{i}, num2str(args{i}));
            else
                fprintf(fid, '%% %s = %s\n', labels{i}, args{i});
            end
        end
        fprintf(fid, '\n');

        fclose(fid);

        % cat this specific experiment file into the log file 
        cmd = ['cat ',oldDir,name, ' >> ', fileOut];
        unix(cmd);

        % cat everything in the HelperFunctions dir
        helperFiles = dir('*.m');
        for i=3:size(helperFiles,1)     % skips . and ..
            cmd = ['cat ',helperFiles(i).name, ' >> ', fileOut];
            unix(cmd);
        end
    elseif (ispc())
        oldDir = [oldDir, '\'];
        fileOut = [oldDir, fileOut];

        % Open a dummy 'params.txt' file and write the parameters used in the calling
        fid = fopen('params.txt', 'w');

        fprintf(fid, '%% Function called with the following list of parameters\n');
        for i=1:size(labels, 2)
            if(isnumeric(args{i}))
                fprintf(fid, '%% %s = %g\n', labels{i}, args{i});
            else
                fprintf(fid, '%% %s = %s\n', labels{i}, args{i});
            end
        end

        fclose(fid);
        
        % start generating the copy command
        cmd = ['copy /a params.txt+',oldDir,name];

        % look for all .m files in the working directory
        helperFiles = dir('*.m');
        for i=1:size(helperFiles,1)    
            newFile = helperFiles(i).name;
            if (strcmp(newFile(1), '.'))
                continue % skip files of the form .*
            else
                cmd = [cmd, '+', newFile];
            end
        end
        cmd = [cmd, ' ', fileOut];
        dos(cmd)
        dos('del params.txt')
    end
    
    cd(oldDir)
end

function CreateStimuliLogStart()
    % this function should be called from whithin all the functions that I
    % might want to have in the log.
    % the idea is that it creates a global variable where the name of all
    % the functions used are stored (full path) so that later on, at the
    % end of teh experiment a call to CreateStimuliLogWrite, generates teh
    % file.
    global expLog
        
    % if expLog is empty add the date and time
    if (size(expLog, 1)==0)
        expLog{1} = datestr(clock);

        % who is the calling function?  s.file
        s = dbstack('-completenames');
        expLog{2} = s(2).name;
    end

end

function CreateStimuliLogWrite(p)
% Creates a log file.
% It relies on a call to CreateStimuliLogStart(varargin) at the beginning
% of the experiment.
% The log file will have:
% 1) All the parameters passed as varargin to the original function
% 2) All the procedures one folder inside the 'Stimuli' one (except for
% folders named '*BackUp*' or '*test*'

    global expLog       % a cell array created by CreateStimuliLogStart()
    
    % only execute this code if the calling function (the one above
    % this one in the stack) is the 1st function you executed.
    s = dbstack('-completenames');
    callingFunction = s(2).name;
    if ~strcmp(callingFunction, expLog{2})
        % functions are different, do nothing
        return
    end

    % get the output name to use
    basename = [s(2).name,'_'];
    i=1;
    fileOut = [basename, num2str(i),'.m'];
    % check if file exists in current directory
    while ( exist(fileOut,'file') )
        % append a number to it.
        i = i+1;
        fileOut = [basename, num2str(i), '.m'];
    end

    % work from the parent ('Stimuli') folder
    oldDir = pwd;
    cd ..;

    % Open the file
    fid = fopen(fileOut, 'w');
    
    % write the execution date and time
    fprintf(fid, ['%% File executed on: ', expLog{1}, '\n']);
    
    % write all the parameters passed to the function
    if (nargin==1)
        fieldNames = fieldnames(p.Results);
        fprintf(fid, '%% List of all arguments:\n');
        for i=1:length(fieldNames)
            fprintf(fid, ['%% ', char(fieldNames(i)), ' = ', num2str(p.Results.(char(fieldNames(i)))), '\n']);
        end
        fprintf(fid, '\n');
    end
    % get a list of Folders in 'Stimuli' Folder
    dirList = dir;

    % 1. get into every Folder that is not of the form '.', '..', 'Backup*'
    % 2. make a pseudo code file of every .m file.
    % 3. cat those at the end of fileOut
    % 4. remove .p file
    for i=3:size(dirList,1) % 1 & 2 correspond to '.' and '..'
        if (dirList(i).isdir && ...
                isempty(findstr(dirList(i).name, 'BackUp')) && ...
                isempty(findstr(dirList(i).name, 'test')))
            % dump all the contents of the directory onto the log file
            cd(dirList(i).name);
            fileList = dir('*.m');
            for file=1:size(fileList,1)
                 unix(['cat ',fileList(file).name, ' >> ../', fileOut]);
            end

            % get back into the 'Stimuli' Folder
            cd ..
        end
    end

    fclose(fid);
    cd(oldDir);
    FinishExperiment();
end

function pd = DefinePhotodiode(k, pd, flag)
% Define two photodiode boxes and the colors to be used in encoding the
% stimuli. I will use 4 different colors in the PD (black + 4) therefore
% the number of bits needed to encode stimN different stimuli are
% log4(stimN) = log2(stimN)/log2(4) = log2(stimN)/2
% Since the colors displayed can go up to 255 I will take 60, 120, 180 and
% 240 as bits 0-3 respectively
% 
% if flag = 0, real experiment pd.photodiodeBox1 is under the physical PD
% if flag = 1, adaptation period and pd. photodiodeBox2 us under the PD

%}

if (flag)
    pd.photodiodeBox2=[ ...
        k.screenBox(3)*8.7/10;      ... left border
        k.screenBox(4)*0.7/10;      ... top border
        k.screenBox(3);             ... right border
        k.screenBox(4)/10 + 100     ... bottom border
        ];

    pd.photodiodeBox1=[ ...
        0;                          ... left border
        k.screenBox(4)*9/10;        ... top border
        k.screenBox(3)*1/10;        ... right border
        k.screenBox(4)              ... bottom border
        ];
else
    pd.photodiodeBox1=[ ...
        k.screenBox(3)*8.7/10;      ... left border
        k.screenBox(4)*0.7/10;      ... top border
        k.screenBox(3);             ... right border
        k.screenBox(4)/10 + 100     ... bottom border
        ];

    pd.photodiodeBox2=[ ...
        0;                          ... left border
        k.screenBox(4)-1;           ... top border
        1;                          ... right border
        k.screenBox(4)              ... bottom border
        ];
end
    pd.color=60;
end

function [rectangles rectanglesN]= DefineRectangles(checkerSize, size, ...
    upperLeft)
    % Usage: DefineRectangles(20, [700 700], [0 0])
    % Devide a portion of the screen defined by the "upperLeft" pixel and
    % "size(1)" pixels vertical and "size(2)" pixels wide into
    % squares of size "checkerSize"
    % UpperLeft are coordinates with respect to the whole screen. NOT with
    % respect to the area filled with checkers (otherwise they will always
    % be [0 0])
    % 
    % if checkerSize == -1 a checker of 'size' is returned
    
    if (checkerSize == -1)
        rectanglesN = 1;
        rectangles  = [upperLeft upperLeft + size];
    else
    
        NumHBoxes=ceil(size(1)/checkerSize);
        NumVBoxes=ceil(size(2)/checkerSize);

        rectanglesN = NumHBoxes * NumVBoxes;

        % Define the rectangles array 4xNumber of total checkers
        rectangles=zeros(4,rectanglesN);

        % if user defined a screenSize then the left and top pixels of the
        % 1st square are not 0
        startX = upperLeft(1);
        startY = upperLeft(2);

        m1 = ones(NumVBoxes,1)*(startX:checkerSize:(startX + NumHBoxes*checkerSize-checkerSize));
        rectangles(1,:) = reshape(m1',1,rectanglesN)';
        rectangles(3,:) = rectangles(1,:) + checkerSize;
        m1 = ones(NumHBoxes,1)*(startY:checkerSize:startY + NumVBoxes*checkerSize-checkerSize);
        rectangles(2,:) = reshape(m1,1,rectanglesN);
        rectangles(4,:) = rectangles(2,:) + checkerSize;
    end
end

function DisplayStimInPD2(stim, pd, frame, framesPerCode, screen)
    % stim will be coded in the pdBox as 4 bits in base 4 (4 colors other
    % than white)
    % At frame 1 pd box will always be white to signal clearly the stim
    % onset
    % At pd.frame1 bit 0 is shown
    % At pd.frame2 bit 1 is shown
    % At pd.frame3 bit 2 is shown
    % At pd.frame4 bit 3 is shown
    %
    % framesPerCode is needed to know when the new stim is starting
    %
    % Bit is   Intensity
    %   0           60
    %   1           120
    %   2           180
    %   3           240
    %   -           30      in between coding frames
    %   -           255     1st frame of code

    
    temp=mod(frame, framesPerCode);
    if (temp==0)           % display white on 1st frame
        Screen('FillRect', screen.w, screen.white, pd);
    elseif (temp==1)    % display bit0
        % Change stim into the colors needed for the pd
        pdColors = stim2pdColors(stim);    % stim = pdColor(1)*4^0 + pdColor(2)*4^1 + pdColor(2)*4^2 + pdColor(3)*4^3
        Screen('FillRect', screen.w, pdColors(1), pd);
    elseif (temp==2)   % display bit1
        pdColors = stim2pdColors(stim);    % stim = pdColor(1)*4^0 + pdColor(2)*4^1 + pdColor(2)*4^2 + pdColor(3)*4^3
        Screen('FillRect', screen.w, pdColors(2), pd);
    elseif (temp==3)   % display bit2
        pdColors = stim2pdColors(stim);    % stim = pdColor(1)*4^0 + pdColor(2)*4^1 + pdColor(2)*4^2 + pdColor(3)*4^3
        Screen('FillRect', screen.w, pdColors(3), pd);
    elseif (temp==4)   % display bit3
        pdColors = stim2pdColors(stim);    % stim = pdColor(1)*4^0 + pdColor(2)*4^1 + pdColor(2)*4^2 + pdColor(3)*4^3
        Screen('FillRect', screen.w, pdColors(4), pd);
    else
        AlmostBlack = 60;       
        Screen('FillRect', screen.w, AlmostBlack, pd);
    end
end

function FinishExperiment()
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.
    clear Screen
    clear global all
    clear global expLog
    clear global screen
    Screen('CloseAll');
    Priority(0);
    ShowCursor();
end

function InitScreen(debugging)
    % Initializes the Screen.
    % The idea here is that you can call this function from within a given
    % stimulus where the 2nd parameter might or might no be defined. If it
    % is defined this function does nothing but if it is not defined then
    % this function initializes the screen.
    
    global screen
    if (isfield(screen, 'w'))
        return
    end
    AssertOpenGL;

    % Get the list of screens and choose the one with the highest screen number.
    screenNumber=max(Screen('Screens'));

    % Find the color values which correspond to white and black.
    screen.white=WhiteIndex(screenNumber);
    screen.black=BlackIndex(screenNumber);

    % Round gray to integral number, to avoid roundoff artifacts with some
    % graphics cards:
	screen.gray=floor((screen.white+screen.black)/2);

    % This makes sure that on floating point framebuffers we still get a
    % well defined gray. It isn't strictly neccessary in this demo:
    if screen.gray == screen.white
		screen.gray=screen.white / 2;
    end

    % Open a double buffered fullscreen window with a gray background:
    if (screenNumber == 0)
        if (debugging)
            [screen.w screen.rect]=Screen('OpenWindow',screenNumber, screen.gray, [0 0 400 400]);
        else
            [screen.w screen.rect]=Screen('OpenWindow',screenNumber, screen.gray);
            HideCursor();
        end
        Priority(1);
    else
        [screen.w screen.rect]=Screen('OpenWindow',screenNumber, screen.gray);
    end
    
        % Query duration of monitor refresh interval:
    screen.ifi=Screen('GetFlipInterval', screen.w);

end

function JitterBackTex_JitterObjTex(backSeq, objSeq, screen, ...
    waitframes, framesN, backTex, backRect, backSource, objTex, objRect, ...
    objSource, pd, pdStim)
    % Screen is divided in background and object.
    % background will display the given texture and will jitter it around
    % as specified by backSeq.
    % object will display the given texture and will jitter it around
    % as specified by objSeq.
    % The time of the presentation comes in through framesN and if it is
    % longer than either backSeq or objSeq, then the jitter or the objSeq
    % sequences are repeated as many times as needed. In this way you can
    % have either:
    %   one background and one object
    %   one background with different objects
    %   different backgrounds with one object
    %
    % This procedure can also be used for reverse grating backgrounds, just
    % define the background to be the grating texture and define backSeq
    % to something like backSeq = [J 0 0 0 0 0 0 0 0 -J 0 0 0 0 0 0 0 0]
    % were the J is the size of the jump and the 0s are the frames where
    % the background is still
    % backSeq:    an array describing how many pixels to jump
    %               at each frame (+ to the right, - to the left)
    % objSeq:       the intensities to display in the Uniform Field obj
    % screen:       the usual screen struct.
    % waitFrames:   how often is the Flip going to be called?
    %               in general this will be either 1 or 2
    % framesN:      framesN/60 = totalLength of the presentation
    % backTex:      the texture to show in the background.
    % backRect:     where to display the background
    % backSource:   what part of the texture to display
    % objRect:      where to display the object
    % vbl:          time of last flip call
    % pd:           PD box definition
    global vbl
    
    % init the frame counter
    frame = 0;
    
    backShiftRect = [0 0 0 0];
    objShiftRect = [0 0 0 0];
    
    backSeqN = size(backSeq,2);
    objSeqN = size(objSeq, 2);
    
    while (frame < framesN) & ~KbCheck %#ok<AND2>
        % Background Drawing
        % ---------- -------
        backIndex = mod(frame/waitframes, backSeqN)+1;
        backShiftRect = backShiftRect + backSeq(backIndex)*[1 0 1 0];

        Screen('DrawTexture', screen.w, backTex, backSource + backShiftRect, backRect, 0,0);

        % Object Drawing
        % --------------
        objIndex = mod(frame/waitframes, objSeqN)+1;
        objShiftRect = objShiftRect + objSeq(objIndex)*[1 0 1 0];

        Screen('DrawTexture', screen.w, objTex, objSource + objShiftRect, objRect, 0,0);
        

        % Photodiode box
        % --------------
        DisplayStimInPD2(pdStim, pd, frame, 60, screen)

        % Flip 'waitframes' monitor refresh intervals after last redraw.
        vbl = Screen('Flip', screen.w, vbl + (waitframes - 0.5) * screen.ifi);
        frame = frame + waitframes;

    end
    
end

function JitteringBackTex_UniformFieldObj(jitterSeq, objSeq, screen, ...
    waitframes, framesN, backTex, backRect, backSource, objRect, pd, pdStim)
    % Screen is divided in background and object.
    % background will display the given texture and will jitter it around
    % as specified by jitterSeq.
    % Object will follow the intensities in objSeq
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
    % framesN:      framesN/60 = totalLength of the presentation
    % backTex:      the texture to show in the background.
    % backRect:     where to display the background
    % backSource:   what part of the texture to display
    % objRect:      where to display the object
    % vbl:          time of last flip call
    % pd:           PD box definition

    global vbl
    
    % init the frame counter
    frame = 0;
    
    shiftRect = [0 0 0 0];
    
    jumpsN = size(jitterSeq,2);
    objSeqN = size(objSeq, 2);
    
    while (frame < framesN) & ~KbCheck %#ok<AND2>
        
        backIndex = mod(frame/waitframes, jumpsN)+1;
        shiftRect = shiftRect + jitterSeq(backIndex)*[1 0 1 0];

        Screen('DrawTexture', screen.w, backTex, backSource + shiftRect, backRect, 0,0)

        % Object Drawing
        % --------------
        
        objIndex = mod(frame/waitframes, objSeqN)+1;
        objColor = objSeq(objIndex);
        Screen('FillRect', screen.w, objColor, objRect);


        % Photodiode box
        % --------------
        DisplayStimInPD2(pdStim, pd, frame, 60, screen)

        % Flip 'waitframes' monitor refresh intervals after last redraw.
        vbl = Screen('Flip', screen.w, vbl + (waitframes - 0.5) * screen.ifi);
        frame = frame + waitframes;

    end
end

function p =  ParseInput(varargin)
    % Generates a structure with all the parameters
    % Allowed parameters are:
    %
    % objContrast, objJitterPeriod, objSeed, stimSize, objSizeH, objSizeV,
    % objCenterXY, backContrast, backJitterPeriod, presentationLength,
    % movieDurationSecs, pdStim, debugging, barsWidth, waitframes, vbl

    % In order to get a parameter back just use
    %   p.Resulst.parameter
    % In order to display all the parameters use
    %   disp 'List of all arguments:'
    %   disp(p.Results)
    %
    % General format to add inputs is...
    % p.addRequired('script', @ischar);
    % p.addOptional('format', 'html', ...
    %     @(x)any(strcmpi(x,{'html','ppt','xml','latex'})));
    % p.addParamValue('outputDir', pwd, @ischar);
    % p.addParamValue('maxHeight', [], @(x)x>0 && mod(x,1)==0);

    p  = inputParser;   % Create an instance of the inputParser class.

    
        
    % Object related
    p.addParamValue('objContrast', .05, @(x)x>0 && x<=1);
    p.addParamValue('objJitterPeriod', 2, @(x)x>0 );
    p.addParamValue('objSeed', 1, @(x)isnumeric(x));
    p.addParamValue('objSizeH', 16*12, @(x)x>0);
    p.addParamValue('objSizeV', 16*12, @(x)x>0);
    p.addParamValue('objCenterXY', [0 0], @(x)size(x,2)==2);
    
    % Background related
    p.addParamValue('backSeed', 1, @(x)isnumeric(x));
    p.addParamValue('backContrast', 1, @(x)x>0 && x<=1);
    p.addParamValue('backJitterPeriod', 2, @(x)x>0);

        % General
    p.addParamValue('stimSize', 16*32, @(x)x>0);
    p.addParamValue('presentationLength', 22, @(x)x>0);
    p.addParamValue('movieDurationSecs', 1600, @(x)x>0);
    p.addParamValue('pdStim', 1, @(x)x>=0 && x<256);
    p.addParamValue('debugging', 0, @(x)x>0 && x <=1);
    p.addParamValue('barsWidth', 8, @(x)x>0);
    p.addParamValue('waitframes', 1, @(x)isnumeric(x)); 
    p.addParamValue('vbl', 0, @(x)x>0);

    

    % Call the parse method of the object to read and validate each argument in the schema:
    p.parse(varargin{:});
    
end

function SaveBinary(obj, precision)
    % precision has to be a string literal in acordance to what fread wants
    % use:
    % 'int8' for small signed numbers
    % 'uint8' for <256 unsigned numbers
    % 'int16' etc...
    
    nameout = [inputname(1), '.bin'];
    fid = fopen(nameout, 'w');
    fwrite(fid, obj, precision);
    fclose(fid);
end

function vbl = Wait4Button(mywindow, debugging, varargin)
    KbName('UnifyKeyNames');
    while ~debugging
        Screen('FillRect', mywindow, 128);
        Screen(mywindow,'TextSize', 24);
        if (nargin > 2)
            text = varargin{1};
            Screen(mywindow, 'DrawText', text ,30,60, 0 );
        end
        text = 'Press any key to start stimulus';
        
        Screen(mywindow, 'DrawText', text ,30,30, 0 );
        vbl = Screen('Flip',mywindow);

        
        if KbWait
            pause(0.2);
            break;
        end
    end
end

function vbl = WaitForRecComp(winPtr, varargin)
    Screen('FillRect', winPtr, 0);
    Screen(winPtr,'TextSize', 36);
    Screen(winPtr, 'DrawText', 'Waiting for rec computer',200,200, 127);
    if (nargin>0)
        Screen(winPtr, 'DrawText', ['(Record for a bit more than ',...
            num2str(varargin{1}), ' secs)'],250,300, 127);
    end

    vbl = Screen('Flip',winPtr);

    WaitForRec();
end

function pdColor = stim2pdColors(stim)
    % Stim has to be a number < 4^4 = 255
    % stim2pdColors returns stim in 4 bits in base 4
    % stim = pdColor(1)*4^0 + pdColor(2)*4^1 + pdColor(2)*4^2 + pdColor(3)*4^3
    % pdColor(i) = {60, 120, 180, 240}
    pdBit0 = mod(stim, 4);
    pdBit1 = mod(floor((stim-pdBit0)/4),4);
    pdBit2 = mod(floor((stim-pdBit0)/16),4);
    pdBit3 = mod(floor((stim-pdBit0)/64),4);
    pdColor(1) = (pdBit0+1)*60;
    pdColor(2) = (pdBit1+1)*60;
    pdColor(3) = (pdBit2+1)*60;
    pdColor(4) = (pdBit3+1)*60;
end

function LoadHelperFunctions()
    % load Helper functions
    oldDir = pwd;
    cd ..
    cd('HelperFunctions');
    addpath(genpath(pwd));
    cd(oldDir)
end

function LowContrastObj_FixEyeMovements(varargin)



    p=ParseInput(varargin{:});

    objContrast = p.Results.objContrast;
    objSeed  = p.Results.objSeed;
    debugging = p.Results.debugging;
    objJitterPeriod = p.Results.objJitterPeriod;
    objSizeH = p.Results.objSizeH;
    objSizeV = p.Results.objSizeV;
    objCenterXY = p.Results.objCenterXY;
    presentationLength = p.Results.presentationLength;
    movieDurationSecs = p.Results.movieDurationSecs;
    stimSize = p.Results.stimSize;
    barsWidth = p.Results.barsWidth;
    backContrast = p.Results.backContrast;
    waitframes = p.Results.waitframes;
    pdStim = p.Results.pdStim;
    
    
    CreateStimuliLogStart()
    global vbl screen
    if isempty(vbl)
        vbl=0;
    end

    backSeqN = 2;       % there are only two backgrounds, the random one and a still one.

% 
% Wrapper to call JitteringBackTex_UniformFieldObj
%
% Divide the screen in object and background.
% Both object and back will be a grating of a given spatial frequency.
% obj will have a low contrast and back will have a higer one.
% Either back and object follow the same random jitter
% or object alone jitters and back stays still.
% The 'randomly' jittering sequences are compossed of -1, 0, 1 pixel jumps
% per frame with equal probability
% The experiment is divided in presentations. Each presentation is defined
% by the length of the presentation, the background sequence and the object
% sequence. Background and object sequences have independent durations.
% If the presentation lasts longer than either background or object sequence
% then they start over.
% In this way I can:
%   1) make repeats of a given object and background.
%   2) make repeats of a given background with several different objects.
%   3) make repeats of a given object with several different background.
%   4) make repeats where the object and background get out of phase.


% Redefine exp time to have an even number of jitters
movieDurationSecs = backSeqN*presentationLength* ...
    floor(movieDurationSecs/(backSeqN*presentationLength));

try
    InitScreen(debugging);
    
    % Redefine stimSize to have an integer number of bars
    stimSize = ceil(stimSize/barsWidth)*barsWidth;

    % make the background texture
    x= 1:2*stimSize;
    bars = ceil(mod(floor(x/barsWidth),2)*2*screen.gray*backContrast...
        + screen.gray*(1-backContrast));
    backTex = Screen('MakeTexture', screen.w, bars);
    
    % make the object texture
    x= 1:2*objSizeH;
    bars = ceil(mod(floor(x/barsWidth),2)*2*screen.gray*objContrast...
        + screen.gray*(1-objContrast));
    objTex = Screen('MakeTexture', screen.w, bars);

    % Define the background Destination Rectangle
    backRect = SetRect(0,0,stimSize, stimSize);
    backRect = CenterRect(backRect, screen.rect);
    
    % Define the obj Destination Rectangle
    objRect = SetRect(0, 0, objSizeH, objSizeV);
    objRect = CenterRect(objRect, screen.rect);
    objRect = OffsetRect(objRect, objCenterXY(1), objCenterXY(2));

    % Define the source rectangles
    backSource = SetRect(stimSize/2,0,3/2*stimSize,1);
    objSource = SetRect(objSizeH/2, 0,3/2*objSizeH,1);

    % Define the PD box
    pd = SetRect(0,0, 100, 100);
    pd = CenterRectOnPoint(pd, screen.rect(3)*.95, screen.rect(4)*.15);
    
    framesPerSec = 60/waitframes;
    objJumpsPerPeriod = round(objJitterPeriod*framesPerSec);

    
    % make the backSeqN random sequences
    stillSeq = zeros(1, objJumpsPerPeriod);
    
    % We run at most 'consPresentationsN' if user doesn't abort via
    % keypress.
    presentationsN = movieDurationSecs/presentationLength;

    % Define some needed variables
    

    framesN = presentationLength*60;

    % Animationloop:
    for presentation = 1:presentationsN
        % get the random sequence of jumps for the object
        objSeq = floor(rand(1, objJumpsPerPeriod)*3)-1;

        rand('seed',objSeed);
        if (mod(presentation, 2))
            backSeq = objSeq;
        else            
            backSeq = stillSeq;
            objSeed = rand('seed');
        end


        JitterBackTex_JitterObjTex(backSeq, objSeq, screen, ...
            waitframes, framesN, backTex, backRect, backSource, objTex, ...
            objRect, objSource, pd, pdStim);
        if (KbCheck)
            break
        end
    end
    
    CreateStimuliLogWrite(p);

catch
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.
    FinishExperiment();
    psychrethrow(psychlasterror);
end %try..catch..
end

function RF(varargin)
    % if you want to change a parameter from its default value you have to
    % type 'paramToChange', newValue, ...
    % List of possible params is:
    % objContrast, objJitterPeriod, objSeed, stimSize, objSizeH, objSizeV,
    % objCenterXY, backContrast, backJitterPeriod, presentationLength,
    % movieDurationSecs, pdStim, debugging, barsWidth, waitframes, vbl

    p=ParseInput(varargin{:});

    objContrast = p.Results.objContrast;
    seed  = p.Results.objSeed;
    movieDurationSecs = p.Results.movieDurationSecs;
    stimSize = p.Results.stimSize;
    pdStim = p.Results.pdStim;
    debugging = p.Results.debugging;
    checkerSize = p.Results.barsWidth;
    waitframes = p.Results.waitframes;
    
    CreateStimuliLogStart()
    global vbl screen
    if isempty(vbl)
        vbl=0;
    end

try
    InitScreen(debugging);

    checkersN_H = ceil(stimSize/checkerSize);
    checkersN_V = checkersN_H;
    
    % Define the obj Destination Rectangle
    objRect = SetRect(0,0, checkersN_H, checkersN_V)*checkerSize;
    objRect = CenterRect(objRect, screen.rect);

    % Define the PD box
    pd = SetRect(0,0, 100, 100);
    pd = CenterRectOnPoint(pd, screen.rect(3)*.95, screen.rect(4)*.15);
    
    % We run at most 'framesN' if user doesn't abort via
    % keypress.
    framesN = movieDurationSecs*60;

    % init random seed generator
    rand('seed', seed);
    
    % Define some needed variables
    
    
    % Animationloop:
    BinaryCheckers(screen, framesN, waitframes, checkersN_H, checkersN_V, objContrast,...
        objRect, pd, pdStim);
    
    
    CreateStimuliLogWrite(p)
 catch
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.
    FinishExperiment();
    psychrethrow(psychlasterror);
end %try..catch..
end



function RandomBackground(varargin)
% Wrapper to call JitteringBackTex_UniformFieldObj
%
% Divide the screen in object and background.
% Object will be a uniform field box of binary flickering intensity.
% Back will be a grating of a giving contrast and spatial frequency.
% Back grating will be randomly jittering.
% The experiment is divided in presentations. Each presentation is defined
% by the length of the presentation, the background sequence and the object
% sequence. Background and object sequences have independent durations.
% If the presentation lasts longer than either background or object sequence
% then they start over.
% In this way I can:
%   1) make repeats of a given object and background.
%   2) make repeats of a given background with several different objects.
%   3) make repeats of a given object with several different background.
%   4) make repeats where the object and background get out of phase.

% if you want to change a parameter from its default value you have to
% type 'paramToChange', newValue, ...
% List of possible params is:
% objContrast, objJitterPeriod, objSeed, stimSize, objSizeH, objSizeV,
% objCenterXY, backContrast, backJitterPeriod, presentationLength,
% movieDurationSecs, pdStim, debugging, barsWidth, waitframes, vbl

p=ParseInput(varargin{:});

objContrast = p.Results.objContrast;
objJitterPeriod = p.Results.objJitterPeriod;
objSeed  = p.Results.objSeed;
objSizeH = p.Results.objSizeH;
objSizeV = p.Results.objSizeV;
objCenterXY = p.Results.objCenterXY;
backSeed = p.Results.backSeed;
backContrast = p.Results.backContrast;
backJitterPeriod = p.Results.backJitterPeriod;
stimSize = p.Results.stimSize;
presentationLength = p.Results.presentationLength;
movieDurationSecs = p.Results.movieDurationSecs;
pdStim = p.Results.pdStim;
debugging = p.Results.debugging;
barsWidth = p.Results.barsWidth;
waitframes = p.Results.waitframes;

CreateStimuliLogStart()
global vbl screen
if isempty(vbl)
    vbl=0;
end

% Redefine exp time to have an even number of jitters
movieDurationSecs = presentationLength* ...
    floor(movieDurationSecs/presentationLength);

LoadHelperFunctions();
try
    InitScreen(debugging);
    
    % make the background texture
    x= 1:stimSize;
    bars = ceil(mod(floor(x/barsWidth),2)*2*screen.gray*backContrast...
        + screen.gray*(1-backContrast));
    backTex = Screen('MakeTexture', screen.w, bars);

    % Define the background Destination Rectangle
    backRect = SetRect(0,0,stimSize, stimSize);
    backRect = CenterRect(backRect, screen.rect);
    
    % Define the obj Destination Rectangle
%    objRect = SetRect(0,0,objSizeH, objSizeV);
%    objRect = CenterRect(objRect, screen.rect);
    objRect = SetRect(0, 0, objSizeH, objSizeV);
    objRect = CenterRect(objRect, screen.rect);
    objRect = OffsetRect(objRect, objCenterXY(1), objCenterXY(2));

    % Define the source rectangles
    backSource = SetRect(0,0,stimSize,1);
    
    % Define the PD box
    pd = SetRect(0,0, 100, 100);
    pd = CenterRectOnPoint(pd, screen.rect(3)*.95, screen.rect(4)*.15);
    

    % start the Random Generator
    rand('seed', backSeed);
    
    framesPerSec = 60/waitframes;
    backJumpsPerPeriod = round(backJitterPeriod*framesPerSec);
    objJumpsPerPeriod = round(objJitterPeriod*framesPerSec);

       
    % We run at most 'consPresentationsN' if user doesn't abort via
    % keypress.
    presentationsN = movieDurationSecs/presentationLength;

    objNextSeed = objSeed;
    backNextSeed = backSeed;
    
    % Define some needed variables
    
        
    % Perform initial Flip to sync us to the VBL and for getting an initial
    % VBL-Timestamp for our "WaitBlanking" emulation:
%    vbl=Wait2Start(screen.w, debugging, ['Recotrd for ', num2str(movieDurationSecs), ' secs']);

    framesN = presentationLength*60;
    
    % Animationloop:
    for presentation = 1:presentationsN

        % get the background random sequence
        rand('seed',backNextSeed);
        backSeq = floor(rand(1, backJumpsPerPeriod)*3)-1;
        backSeq(1, backJumpsPerPeriod) = -sum(backSeq(1, 1:backJumpsPerPeriod-1));
        backNextSeed = rand('seed');
        
        % get the object random sequence
        rand('seed',objNextSeed);
        objSeq = (rand(1, objJumpsPerPeriod)>.5)*2*screen.gray*objContrast+screen.gray*(1-objContrast);
        objNextSeed = rand('seed');

        JitteringBackTex_UniformFieldObj(backSeq, objSeq, screen, ...
            waitframes, framesN, backTex, backRect, backSource, objRect, pd, pdStim)

%        accumPhase = mod(accumPhase + sum(backSeq), 2*barsWidth);
        
        if (KbCheck)
            break
        end
    end
   
    if (presentation == presentationsN)   % if it got here without any key being pressed
        CreateStimuliLogWrite(p);
    end
    
catch
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.
    FinishExperiment();
    psychrethrow(psychlasterror);
end %try..catch..
end


function RandomBackground2(varargin)
% Wrapper to call JitteringBackTex_UniformFieldObj
%
% Divide the screen in object and background.
% Object will be a uniform field box of binary flickering intensity.
% Back will be a grating of a giving contrast and spatial frequency.
% Back grating will be randomly drifting. Each frame the background can
% either jump (always in the same direction) or not.
% The experiment is divided in presentations. Each presentation is defined
% by the length of the presentation, the background sequence and the object
% sequence. Background and object sequences have independent durations.
% If the presentation lasts longer than either background or object sequence
% then they start over.
% In this way I can:
%   1) make repeats of a given object and background.
%   2) make repeats of a given background with several different objects.
%   3) make repeats of a given object with several different background.
%   4) make repeats where the object and background get out of phase.


p=ParseInput(varargin{:});

objContrast = p.Results.objContrast;
objJitterPeriod = p.Results.objJitterPeriod;
objSeed  = p.Results.objSeed;
objSizeH = p.Results.objSizeH;
objSizeV = p.Results.objSizeV;
objCenterXY = p.Results.objCenterXY;
backSeed = p.Results.backSeed;
backContrast = p.Results.backContrast;
backJitterPeriod = p.Results.backJitterPeriod;
stimSize = p.Results.stimSize;
presentationLength = p.Results.presentationLength;
movieDurationSecs = p.Results.movieDurationSecs;
pdStim = p.Results.pdStim;
debugging = p.Results.debugging;
barsWidth = p.Results.barsWidth;
waitframes = p.Results.waitframes;

CreateStimuliLogStart()
global vbl screen
if isempty(vbl)
    vbl=0;
end

% Redefine exp time to have an even number of jitters
movieDurationSecs = presentationLength* ...
    floor(movieDurationSecs/presentationLength);

LoadHelperFunctions();
try
    InitScreen(debugging);
    
    % make the background texture
    x= 1:stimSize;
    bars = ceil(mod(floor(x/barsWidth),2)*2*screen.gray*backContrast...
        + screen.gray*(1-backContrast));
    backTex = Screen('MakeTexture', screen.w, bars);

    % Define the background Destination Rectangle
    backRect = SetRect(0,0,stimSize, stimSize);
    backRect = CenterRect(backRect, screen.rect);
    
    % Define the obj Destination Rectangle
%    objRect = SetRect(0,0,objSizeH, objSizeV);
%    objRect = CenterRect(objRect, screen.rect);
    objRect = SetRect(0, 0, objSizeH, objSizeV);
    objRect = CenterRect(objRect, screen.rect);
    objRect = OffsetRect(objRect, objCenterXY(1), objCenterXY(2));

    % Define the source rectangles
    backSource = SetRect(0,0,stimSize,1);
    
    % Define the PD box
    pd = SetRect(0,0, 100, 100);
    pd = CenterRectOnPoint(pd, screen.rect(3)*.95, screen.rect(4)*.15);
    

    % start the Random Generator
    rand('seed', backSeed);
    
    framesPerSec = 60/waitframes;
    backJumpsPerPeriod = round(backJitterPeriod*framesPerSec);
    objJumpsPerPeriod = round(objJitterPeriod*framesPerSec);

       
    % We run at most 'consPresentationsN' if user doesn't abort via
    % keypress.
    presentationsN = movieDurationSecs/presentationLength;

    objNextSeed = objSeed;
    backNextSeed = backSeed;
    
    % Define some needed variables
    
        
    % Perform initial Flip to sync us to the VBL and for getting an initial
    % VBL-Timestamp for our "WaitBlanking" emulation:
%    vbl=Wait2Start(screen.w, debugging, ['Recotrd for ', num2str(movieDurationSecs), ' secs']);

    framesN = presentationLength*60;
    phase = 0;
    
    % Animationloop:
    for presentation = 1:presentationsN

        % get the background random sequence
        rand('seed',backNextSeed);
        backSeq = double(rand(1, backJumpsPerPeriod)>.5);
        backSeq(1) = backSeq(1)+phase;              % add the initial phase
        % identify when the cummulative phase surpases 2*barsWidth
%        index = logical(diff([0 floor(cumsum(backSeq)/barsWidth/2)]));
%        backSeq(index)=backSeq(index)-2*barsWidth;
        phase = mod(sum(backSeq), 2*barsWidth);
        % mod(cumsum(backSeq), barsWidth)==0 && backSeq==1)=0;

        backNextSeed = rand('seed');
        
        % get the object random sequence
        rand('seed',objNextSeed);
        objSeq = (rand(1, objJumpsPerPeriod)>.5)*2*screen.gray*objContrast+screen.gray*(1-objContrast);
        objNextSeed = rand('seed');

        JitteringBackTex_UniformFieldObj(backSeq, objSeq, screen, ...
            waitframes, framesN, backTex, backRect, backSource, objRect, pd, pdStim)

%        accumPhase = mod(accumPhase + sum(backSeq), 2*barsWidth);
        
        if (KbCheck)
            break
        end
    end
    
    if (presentation == presentationsN)   % if it got here without any key being pressed
        CreateStimuliLogWrite(p);
    end
    
catch
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.
    FinishExperiment();
    psychrethrow(psychlasterror);
end %try..catch..
end


function RandomBackground3(varargin)
% Wrapper to call JitteringBackTex_UniformFieldObj
%
% Divide the screen in object and background.
% Object will be a uniform field box of binary flickering intensity.
% Back will be a grating of a giving contrast and spatial frequency.
% Back grating will be still for a constant time (something like 250ms) 
% and then will jump a number of pixels (between 0 and barsWidth) producing
% instantaneous jumps of different strength which is similar to different
% velocities although jumps are instantaneous.
%
% The experiment is divided in presentations. Each presentation is defined
% by the length of the presentation, the background sequence and the object
% sequence.
% Background and object sequences have independent durations.
% If the presentation lasts longer than either background or object sequence
% then they start over.
% In this way I can:
%   1) make repeats of a given object and background.
%   2) make repeats of a given background with several different objects.
%   3) make repeats of a given object with several different background.
%   4) make repeats where the object and background get out of phase.

p=ParseInput(varargin{:});

objContrast = p.Results.objContrast;
objJitterPeriod = p.Results.objJitterPeriod;
objSeed  = p.Results.objSeed;
objSizeH = p.Results.objSizeH;
objSizeV = p.Results.objSizeV;
objCenterXY = p.Results.objCenterXY;
backSeed = p.Results.backSeed;
backContrast = p.Results.backContrast;
backJitterPeriod = p.Results.backJitterPeriod;
stimSize = p.Results.stimSize;
presentationLength = p.Results.presentationLength;
movieDurationSecs = p.Results.movieDurationSecs;
pdStim = p.Results.pdStim;
debugging = p.Results.debugging;
barsWidth = p.Results.barsWidth;
waitframes = p.Results.waitframes;

CreateStimuliLogStart()
global vbl screen
if isempty(vbl)
    vbl=0;
end


% Redefine exp time to have an even number of jitters
movieDurationSecs = presentationLength* ...
    floor(movieDurationSecs/presentationLength);

LoadHelperFunctions();
try
    InitScreen(debugging);
    
    % make the background texture
    x= 1:stimSize;
    bars = ceil(mod(floor(x/barsWidth),2)*2*screen.gray*backContrast...
        + screen.gray*(1-backContrast));
    backTex = Screen('MakeTexture', screen.w, bars);

    % Define the background Destination Rectangle
    backRect = SetRect(0,0,stimSize, stimSize);
    backRect = CenterRect(backRect, screen.rect);
    
    % Define the obj Destination Rectangle
    objRect = SetRect(0, 0, objSizeH, objSizeV);
    objRect = CenterRect(objRect, screen.rect);
    objRect = OffsetRect(objRect, objCenterXY(1), objCenterXY(2));

    % Define the source rectangles
    backSource = SetRect(0,0,stimSize,1);
    
    % Define the PD box
    pd = SetRect(0,0, 100, 100);
    pd = CenterRectOnPoint(pd, screen.rect(3)*.95, screen.rect(4)*.15);
    
    
    % Some Experimental variables
    framesPerSec = 60/waitframes;
    backJumpsPerPeriod = round(backJitterPeriod*framesPerSec);
    objJumpsPerPeriod = round(objJitterPeriod*framesPerSec);

       
    % We run at most 'consPresentationsN' if user doesn't abort via
    % keypress.
    presentationsN = movieDurationSecs/presentationLength;

    % Define the number of jumps and their sizes
    backJumpsN = log(barsWidth)/log(2)+2;

    % Generate the sequence of jumps for the background.
    % In the way is coded, jumps sizes are powers of 2. There is one jump
    % that corresponds to 2*barsWidth (32 if barsWidth=16) which is
    % equivalent to 0 size but is easier to code a 32 than a 0.
    rand('seed',backSeed);
    backPresentationSeq = mod(randperm(presentationsN), backJumpsN)+1;
    backJumpsSizes = 2.^((1:backJumpsN)-1);
    backFrameSeq = zeros(1, backJumpsPerPeriod);
    framesInBetweenJumps = 60*backJitterPeriod; %backJumpPeriod;
    index2backJumps = 1:framesInBetweenJumps:backJumpsPerPeriod;
    
    % start the Random Generator
    objNextSeeds = ones(1, backJumpsN)*objSeed;

    % Define some needed variables
    
        
    % Perform initial Flip to sync us to the VBL and for getting an initial
    % VBL-Timestamp for our "WaitBlanking" emulation:
%    vbl=Wait2Start(screen.w, debugging, ['Recotrd for ', num2str(movieDurationSecs), ' secs']);

    framesN = presentationLength*60;
    
    % Animationloop:
    for presentation = 1:presentationsN

        background = backPresentationSeq(presentation);        
        
        % get the background random sequence
        backJumpsSeq = ones(1, size(index2backJumps, 2))*backJumpsSizes(background);
        index = logical(diff([0 floor(cumsum(backJumpsSeq)/barsWidth/2)]));
        backJumpsSeq(index) = backJumpsSeq(index)-2*barsWidth;
        backFrameSeq(index2backJumps) = backJumpsSeq;
        %backFrameSeqSum = cumsum(backFrameSeq);

        % get the object random sequence
        rand('seed',objNextSeeds(background));
        objSeq = (rand(1, objJumpsPerPeriod)>.5)*2*screen.gray*objContrast+screen.gray*(1-objContrast);
        objNextSeeds(background) = rand('seed');

        JitteringBackTex_UniformFieldObj(backFrameSeq, objSeq, screen, ...
            waitframes, framesN, backTex, backRect, backSource, objRect, pd, pdStim)
        
        if (KbCheck)
            break
        end
    end
    
    if (presentation == presentationsN)   % if it got here without any key being pressed
        CreateStimuliLogWrite(p);
    end
    
catch
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.
    FinishExperiment();
    psychrethrow(psychlasterror);
end %try..catch..
end


function RandomBackgroundSpeed(varargin)
% Wrapper to call JitteringBackTex_UniformFieldObj
%
% Divide the screen in object and background.
% Object will be a uniform field box of binary flickering intensity.
% Back will be a grating of a giving contrast and spatial frequency.
% Back grating will be randomly drifting. Each frame the background can
% either jump (always in the same direction) or not.
% The experiment is divided in presentations. Each presentation is defined
% by the length of the presentation, the background sequence and the object
% sequence. Background and object sequences have independent durations.
% If the presentation lasts longer than either background or object sequence
% then they start over.
% In this way I can:
%   1) make repeats of a given object and background.
%   2) make repeats of a given background with several different objects.
%   3) make repeats of a given object with several different background.
%   4) make repeats where the object and background get out of phase.
p=ParseInput(varargin{:});

objContrast = p.Results.objContrast;
objJitterPeriod = p.Results.objJitterPeriod;
objSeed  = p.Results.objSeed;
objSizeH = p.Results.objSizeH;
objSizeV = p.Results.objSizeV;
objCenterXY = p.Results.objCenterXY;
backSeed = p.Results.backSeed;
backContrast = p.Results.backContrast;
backJitterPeriod = p.Results.backJitterPeriod;
stimSize = p.Results.stimSize;
presentationLength = p.Results.presentationLength;
movieDurationSecs = p.Results.movieDurationSecs;
pdStim = p.Results.pdStim;
debugging = p.Results.debugging;
barsWidth = p.Results.barsWidth;
waitframes = p.Results.waitframes;

CreateStimuliLogStart()
global vbl screen
if isempty(vbl)
    vbl=0;
end

% Redefine exp time to have an even number of jitters
movieDurationSecs = presentationLength* ...
    floor(movieDurationSecs/presentationLength);

LoadHelperFunctions();
try
    InitScreen(debugging);
    
    % make the background texture
    x= 1:stimSize;
    bars = ceil(mod(floor(x/barsWidth),2)*2*screen.gray*backContrast...
        + screen.gray*(1-backContrast));
    backTex = Screen('MakeTexture', screen.w, bars);

    % Define the background Destination Rectangle
    backRect = SetRect(0,0,stimSize, stimSize);
    backRect = CenterRect(backRect, screen.rect);
    
    % Define the obj Destination Rectangle
%    objRect = SetRect(0,0,objSizeH, objSizeV);
%    objRect = CenterRect(objRect, screen.rect);
    objRect = SetRect(0, 0, objSizeH, objSizeV);
    objRect = CenterRect(objRect, screen.rect);
    objRect = OffsetRect(objRect, objCenterXY(1), objCenterXY(2));

    % Define the source rectangles
    backSource = SetRect(0,0,stimSize,1);
    
    % Define the PD box
    pd = SetRect(0,0, 100, 100);
    pd = CenterRectOnPoint(pd, screen.rect(3)*.95, screen.rect(4)*.15);
    

    % start the Random Generator
    rand('seed', backSeed);
    
    framesPerSec = 60/waitframes;
    backJumpsPerPeriod = round(backJitterPeriod*framesPerSec);
    objJumpsPerPeriod = round(objJitterPeriod*framesPerSec);

       
    % We run at most 'consPresentationsN' if user doesn't abort via
    % keypress.
    presentationsN = movieDurationSecs/presentationLength;

    objNextSeed = objSeed;
    backNextSeed = backSeed;
    
    % Define some needed variables
    
        
    % Perform initial Flip to sync us to the VBL and for getting an initial
    % VBL-Timestamp for our "WaitBlanking" emulation:
%    vbl=Wait2Start(screen.w, debugging, ['Recotrd for ', num2str(movieDurationSecs), ' secs']);

    framesN = presentationLength*60;
    phase = 0;
    
    % Animationloop:
    for presentation = 1:presentationsN

        % get the background random sequence
        rand('seed',backNextSeed);
        backSeq = double(rand(1, backJumpsPerPeriod)>.5);
        backSeq(1) = backSeq(1)+phase;              % add the initial phase
        % identify when the cummulative phase surpases 2*barsWidth
%        index = logical(diff([0 floor(cumsum(backSeq)/barsWidth/2)]));
%        backSeq(index)=backSeq(index)-2*barsWidth;
        phase = mod(sum(backSeq), 2*barsWidth);
        % mod(cumsum(backSeq), barsWidth)==0 && backSeq==1)=0;

        backNextSeed = rand('seed');
        
        % get the object random sequence
        rand('seed',objNextSeed);
        objSeq = (rand(1, objJumpsPerPeriod)>.5)*2*screen.gray*objContrast+screen.gray*(1-objContrast);
        objNextSeed = rand('seed');

        JitteringBackTex_UniformFieldObj(backSeq, objSeq, screen, ...
            waitframes, framesN, backTex, backRect, backSource, objRect, pd, pdStim)

%        accumPhase = mod(accumPhase + sum(backSeq), 2*barsWidth);
        
        if (KbCheck)
            break
        end
    end
    if (presentation == presentationsN)   % if it got here without any key being pressed
        CreateStimuliLogWrite(p);
    end
    
catch
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.
    FinishExperiment();
    psychrethrow(psychlasterror);
end %try..catch..
end


function ShiftEffect_RF3(varargin)
% Wrapper to call JitteringBackTex_UniformFieldObj
%
% Divide the screen in object and background.
% Object will be a uniform field box of binary random intensity.
% Back will be a grating of a giving contrast and spatial frequency.
% Back grating will be following several different sequences.
% Seq 1:    still background (control)
% Seq 2:    jumping background
% Seq3-jitterN:'randomly' jittering following jitterN sequences.
% The 'randomly' jittering sequences are compossed of -1, 0, 1 pixel jumps
% per frame with equal probability
% The experiment is divided in presentations. Each presentation is defined
% by the length of the presentation, the background sequence and the object
% sequence. Background and object sequences have independent durations.
% If the presentation lasts longer than either background or object sequence
% then they start over.
% In this way I can:
%   1) make repeats of a given object and background.
%   2) make repeats of a given background with several different objects.
%   3) make repeats of a given object with several different background.
%   4) make repeats where the object and background get out of phase.


    % if you want to change a parameter from its default value you have to
    % type 'paramToChange', newValue, ...
    % List of possible params is:
    % objContrast, objJitterPeriod, objSeed, stimSize, objSizeH, objSizeV,
    % objCenterXY, backContrast, backJitterPeriod, presentationLength,
    % movieDurationSecs, pdStim, debugging, barsWidth, waitframes, vbl

    p=ParseInput(varargin{:});

    objContrast = p.Results.objContrast;
    objJitterPeriod = p.Results.objJitterPeriod;
    objSeed  = p.Results.objSeed;
    objSizeH = p.Results.objSizeH;
    objSizeV = p.Results.objSizeV;
    objCenterXY = p.Results.objCenterXY;
    backSeed = p.Results.backSeed;
    backContrast = p.Results.backContrast;
    backJitterPeriod = p.Results.backJitterPeriod;
    stimSize = p.Results.stimSize;
    presentationLength = p.Results.presentationLength;
    movieDurationSecs = p.Results.movieDurationSecs;
    pdStim = p.Results.pdStim;
    debugging = p.Results.debugging;
    barsWidth = p.Results.barsWidth;
    waitframes = p.Results.waitframes;
    
    CreateStimuliLogStart()
    global vbl screen
    if isempty(vbl)
        vbl=0;
    end

    backJitterN = 2;                % how many sequences do you want for the background?


% Redefine exp time to have an even number of jitters
movieDurationSecs = backJitterN*presentationLength* ...
    floor(movieDurationSecs/(backJitterN*presentationLength));

LoadHelperFunctions();

try
    InitScreen(debugging);
    
    % make the background texture
    x= 1:2*stimSize;
    bars = ceil(mod(floor(x/barsWidth),2)*2*screen.gray*backContrast...
        + screen.gray*(1-backContrast));
    backTex = Screen('MakeTexture', screen.w, bars);

    % Define the background Destination Rectangle
    backRect = SetRect(0,0,stimSize, stimSize);
    backRect = CenterRect(backRect, screen.rect);
    
    % Define the obj Destination Rectangle
%    objRect = SetRect(0,0,objSizeH, objSizeV);
%    objRect = CenterRect(objRect, screen.rect);
    objRect = SetRect(0, 0, objSizeH, objSizeV);
    objRect = CenterRect(objRect, screen.rect);
    objRect = OffsetRect(objRect, objCenterXY(1), objCenterXY(2));

    % Define the source rectangles
    backSource = SetRect(stimSize/2,0,3/2*stimSize,1);
    
    % Define the PD box
    pd = SetRect(0,0, 100, 100);
    pd = CenterRectOnPoint(pd, screen.rect(3)*.95, screen.rect(4)*.15);
    

    % start the Random Generator
    rand('seed', backSeed);
    
    framesPerSec = 60/waitframes;
    backJumpsPerPeriod = round(backJitterPeriod*framesPerSec);
    objJumpsPerPeriod = round(objJitterPeriod*framesPerSec);

    
    % make the backJitterN random sequences
    jitterSeq(1:2,:)=zeros(2, backJumpsPerPeriod);
%    jitterSeq(2,:)=0;
    jitterSeq(2,0*backJumpsPerPeriod/4+1)=   barsWidth/2;
    jitterSeq(2,1*backJumpsPerPeriod/4+1)=  -barsWidth/2;
    jitterSeq(2,2*backJumpsPerPeriod/4+1)=   barsWidth/2;
    jitterSeq(2,3*backJumpsPerPeriod/4+1)=  -barsWidth/2;
    jitterSeq(3:backJitterN,:) = floor(rand(backJitterN-2, backJumpsPerPeriod)*3)-1;
    % make all the jitter sequences start always with 0 phase.
%    jitterSeq(:,backJumpsPerPeriod) = -sum(jitterSeq(:,1:backJumpsPerPeriod-1), 2);
    
    % We run at most 'consPresentationsN' if user doesn't abort via
    % keypress.
    presentationsN = movieDurationSecs/presentationLength;

    % make the random sequence of background to display
    backSeq = 0:presentationsN-1;%randperm(presentationsN);
    backSeq = mod(backSeq, backJitterN)+1;
    
    nextSeeds = ones(1, backJitterN)*objSeed;
    
    % Define some needed variables
    
        
    % Perform initial Flip to sync us to the VBL and for getting an initial
    % VBL-Timestamp for our "WaitBlanking" emulation:
%    vbl=Wait4Button(screen.w, debugging);
    
    framesN = presentationLength*60;

    % Animationloop:
    for presentation = 1:presentationsN
        % Background Drawing
        % ------------------

        back = backSeq(presentation);
        %back = mod(presentation, 8)
%        if (back==0)
%            back = 8;
%        end
        jitter = jitterSeq(back,:);
        rand('seed',nextSeeds(back));
        objSeq = (rand(1, objJumpsPerPeriod)>.5)*2*screen.gray*objContrast+screen.gray*(1-objContrast);
        JitteringBackTex_UniformFieldObj(jitter, objSeq, screen, ...
            waitframes, framesN, backTex, backRect, backSource, objRect, pd, pdStim)
        nextSeeds(back) = rand('seed');
        if (KbCheck)
            break
        end
    end
    
    if (presentation == presentationsN)   % if it got here without any key being pressed
        CreateStimuliLogWrite(p);
    end
    
catch
    FinishExperiment();
    psychrethrow(psychlasterror);
end %try..catch..
end



function ShiftEffect_RF4(varargin)
    % if you want to change a parameter from its default value you have to
    % type 'paramToChange', newValue, ...
    % List of possible params is:
    % objContrast, objJitterPeriod, objSeed, stimSize, objSizeH, objSizeV,
    % objCenterXY, backContrast, backJitterPeriod, presentationLength,
    % movieDurationSecs, pdStim, debugging, barsWidth, waitframes, vbl

    p=ParseInput(varargin{:});

    objContrast = p.Results.objContrast;
    objJitterPeriod = p.Results.objJitterPeriod;
    objSeed = p.Results.objSeed;
    stimSize = p.Results.stimSize;
    objSizeH = p.Results.objSizeH;
    objSizeV = p.Results.objSizeV;
    objCenterXY = p.Results.objCenterXY;
    backContrast = p.Results.backContrast;
    backJitterPeriod = p.Results.backJitterPeriod;
    presentationLength = p.Results.presentationLength;
    movieDurationSecs = p.Results.movieDurationSecs;
    pdStim = p.Results.pdStim;
    debugging = p.Results.debugging;
    barsWidth = p.Results.barsWidth;
    waitframes = p.Results.waitframes;
%    vbl = p.Results.vbl;
    
    CreateStimuliLogStart()
    global vbl screen
    if isempty(vbl)
        vbl=0;
    end
% debugging     = 0 or 1
% stimSize      = 600    in pixels
% objSizeH/V    = 16*12  in pixels (16 = 100um)
% objCenterXY   = [0 0] for centered object. Is in pixels
% barsWidth     = in pixels, each bar. Period is 2*barsWidth
% backContrast  = between 0 and 1
% objContrast   = between 0 and 1
% vbl           = time of last flip, 0 if none happened yet
% backJitterPeriod = number of seconds the back sequence has to jitter around
% objJitterPeriod  = number of seconds the object sequence has to jitter around
% presentationLength    = number of seconds for each presentation
% objSeed
% waitframes    = probably 1 or 2. How often do you want to 'Flip'?
% movieDurationSecs     = Approximate length of the experiment, will be changed in the code
% varargin      = {screen}
%
% Wrapper to call JitteringBackTex_UniformFieldObj
%
% Divide the screen in object and background.
% Object will be a uniform field box of binary random intensity and a given
% contrast
% Back will be a grating of a giving contrast and spatial frequency.
% Back grating will be reversing at a given frequency
%
% The experiment is divided in presentations. Each presentation is defined
% by the length of the presentation, the background sequence and the object
% sequence. Background and object sequences have independent durations.
% If the presentation lasts longer than either background or object sequence
% then they start over.
% In this way I can:
%   1) make repeats of a given object and background.
%   2) make repeats of a given background with several different objects.
%   3) make repeats of a given object with several different background.
%   4) make repeats where the object and background get out of phase.
%{
debugging=0

stimSize = 600;         % in pixels
objSizeH = 16*12;           % HD is 24;              % in pixels
objSizeV = 16*12;           % HD is 20;              % in pixels
objCenterXY=[0 0];
barsWidth = 7;          % in pixels

objContrast =.2;
vbl =0;
backContrast = 100/100;       %mean is 127

backJitterPeriod = 1;           % how long should each one of the jitterN seq be (in seconds)?
objJitterPeriod = 11;            % how long should each one of the jitterN seq be (in seconds)?
presentationLength = 11*backJitterPeriod;

% Probably you do not want to mess with these
objSeed = 1;
waitframes = 1;
movieDurationSecs=20;  % in seconds
%}

% Redefine exp time to have an even number of jitters
movieDurationSecs = presentationLength* ...
    floor(movieDurationSecs/presentationLength);

% Redefine the stimSize to incorporate an integer number of bars
stimSize = ceil(stimSize/barsWidth)*barsWidth;

CreateStimuliLogWrite(p);
%LoadHelperFunctions();
try    
    InitScreen(debugging);
    
    % make the background texture
    x= 1:stimSize;
    bars = ceil(mod(floor(x/barsWidth),2)*2*screen.gray*backContrast...
        + screen.gray*(1-backContrast));
    backTex = Screen('MakeTexture', screen.w, bars);

    % Define the background Destination Rectangle
    backRect = SetRect(0,0,stimSize, stimSize);
    backRect = CenterRect(backRect, screen.rect);
    
    % Define the obj Destination Rectangle
    objRect = SetRect(0, 0, objSizeH, objSizeV);
    objRect = CenterRect(objRect, screen.rect);
    objRect = OffsetRect(objRect, objCenterXY(1), objCenterXY(2));

    % Define the source rectangles
    backSource = SetRect(0,0,stimSize-1,1);
    
    % Define the PD box
    pd = SetRect(0,0, 100, 100);
    pd = CenterRectOnPoint(pd, screen.rect(3)*.95, screen.rect(4)*.15);
    
    framesPerSec = 60/waitframes;
    backJumpsPerPeriod = round(backJitterPeriod*framesPerSec);
    objJumpsPerPeriod = round(objJitterPeriod*framesPerSec);
    
    % make the backJitterN random sequences
    jitterSeq(1,:)=zeros(1, backJumpsPerPeriod);
    jitterSeq(1,0*backJumpsPerPeriod/2+1)=   barsWidth;
    jitterSeq(1,1*backJumpsPerPeriod/2+1)=  -barsWidth;

    % We run at most 'consPresentationsN' if user doesn't abort via
    % keypress.
    presentationsN = movieDurationSecs/presentationLength;
    

    
    % Define some needed variables
    
        
    framesN = presentationLength*60;

    % Animationloop:
    for presentation = 1:presentationsN
        rand('seed',objSeed);
        objSeq = (rand(1, objJumpsPerPeriod)>.5)*2*screen.gray*objContrast+screen.gray*(1-objContrast);
        JitteringBackTex_UniformFieldObj(jitterSeq, objSeq, screen, ...
            waitframes, framesN, backTex, backRect, backSource, objRect, ...
            pd, pdStim);
        objSeed = rand('seed');
        if (KbCheck)
            break
        end
    end
    
    CreateStimuliLogWrite(p);
    
catch
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.
    FinishExperiment();
    psychrethrow(psychlasterror);
end %try..catch..
end

function StableObject_FixEyeMovements(varargin)

% debugging     = 0 or 1
% stimSize      = 600    in pixels
% objSizeH/V    = 16*12  in pixels (16 = 100um)
% objCenterXY   = [0 0] for centered object. Is in pixels
% barsWidth     = in pixels, each bar. Period is 2*barsWidth
% backContrast  = between 0 and  1
% objIntensities = 1D array of numbers each between 0 and 255;
% vbl           = time of last flip, 0 if none happened yet
% backJitterPeriod  = number of seconds the back sequence has to jitter around
% presentationLength    = number of seconds for each presentation
% waitframes    = probably 1 or 2. How often do you want to 'Flip'?
% movieDurationSecs     = Approximate length of the experiment, will be changed in the code
% seed
% varargin      = {screen}


%
% Wrapper to call JitteringBackTex_UniformFieldObj
%
% Divide the screen in object and background.
% Object will be a uniform field box of a given intensity that will
% change very slowly ~11 secs.
% Back will be a grating of a giving contrast and spatial frequency
% that either is still or random Jittering 
%
% Internally, there are N obj intensities, and I will have a seq of objects
% equal to 2N, first N objs will be for jittering background and last N obj
% will be with still background.

    p=ParseInput(varargin{:});

    objContrast = p.Results.objContrast;
    objJitterPeriod = p.Results.objJitterPeriod;
    objSeed = p.Results.objSeed;
    stimSize = p.Results.stimSize;
    objSizeH = p.Results.objSizeH;
    objSizeV = p.Results.objSizeV;
    objCenterXY = p.Results.objCenterXY;
    backSeed = p.Results.backSeed;
    backContrast = p.Results.backContrast;
    backJitterPeriod = p.Results.backJitterPeriod;
    presentationLength = p.Results.presentationLength;
    movieDurationSecs = p.Results.movieDurationSecs;
    pdStim = p.Results.pdStim;
    debugging = p.Results.debugging;
    barsWidth = p.Results.barsWidth;
    waitframes = p.Results.waitframes;
    
    objIntensities = (1:4)*64;
    objIntensities = objIntensities - mean(objIntensities) + 127;

    CreateStimuliLogStart()
    global vbl screen
    if isempty(vbl)
        vbl=0;
    end
    LoadHelperFunctions();
try
    % Redefine exp time to have an even number of jitters
    movieDurationSecs = presentationLength* ...
        floor(movieDurationSecs/(presentationLength));


    % Redefine stimSize to have an integer number of bars
    stimSize = ceil(stimSize/barsWidth)*barsWidth;
    
    InitScreen(debugging);
    
    % make the background texture
    x= 1:2*stimSize;
    bars = ceil(mod(floor(x/barsWidth),2)*2*screen.gray*backContrast...
        + screen.gray*(1-backContrast));
    backTex = Screen('MakeTexture', screen.w, bars);

    % Define the background Destination Rectangle
    backRect = SetRect(0,0,stimSize, stimSize);
    backRect = CenterRect(backRect, screen.rect);
    
    % Define the obj Destination Rectangle
    objRect = SetRect(0, 0, objSizeH, objSizeV);
    objRect = CenterRect(objRect, screen.rect);
    objRect = OffsetRect(objRect, objCenterXY(1), objCenterXY(2));

    % Define the source rectangles
    backSource = SetRect(stimSize/2,0,3/2*stimSize,1);
    
    % Define the PD box
    pd = SetRect(0,0, 100, 100);
    pd = CenterRectOnPoint(pd, screen.rect(3)*.95, screen.rect(4)*.15);
    

    framesPerSec = 60/waitframes;
    
    % make the backJitter random sequences
    backJumpsPerPeriod = round(backJitterPeriod*framesPerSec);
    jitterSeq(1,:) = zeros(1, backJumpsPerPeriod);
    rand('seed', backSeed);
    jitterSeq(2,:) = floor(rand(1, backJumpsPerPeriod)*3)-1;

    % We run at most 'consPresentationsN' if user doesn't abort via
    % keypress.
    presentationsN = movieDurationSecs/presentationLength;

    % make the random sequence of object intensities to display
    rand('seed', objSeed);
    objSeq = randperm(presentationsN);
    intensitiesN = size(objIntensities,2);
    objSeq = mod(objSeq, intensitiesN*3);     % make objSeq between 0 and 3*intensitiesN-1
    objSeq = mod(objSeq, intensitiesN*2)+1;     % make objSeq between 1 and 2*intensitiesN but
                                                        % first half has
                                                        % doulbe
                                                        % probability
    % Define some needed variables
    
        
    framesN = presentationLength*60;
    
    % Animationloop:
    for presentation = 1:presentationsN

        stim = objSeq(presentation);
        objColor = objIntensities(mod(stim, intensitiesN)+1);
        if (stim>intensitiesN)
            % still background
            backSeq = jitterSeq(1,:);
        else
            backSeq = jitterSeq(2,:);
        end
        
        JitteringBackTex_UniformFieldObj(backSeq, objColor, screen, ...
            waitframes, framesN, backTex, backRect, backSource, objRect, ...
            pd, pdStim);

        if (KbCheck)
            break
        end
    end
    
    if (presentation == presentationsN)   % if it got here without any key being pressed
        CreateStimuliLogWrite(p);
    end
    
catch
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.
    FinishExperiment();
    psychrethrow(psychlasterror);
end %try..catch..
end


function Stable_Object(varargin)
% Wrapper to call JitteringBackTex_UniformFieldObj
%
% Divide the screen in object and background.
% Object will be a uniform field box of a given intensity that will
% change very slowly ~5-10 secs.
% Back will be a grating of a giving contrast and spatial frequency
% that either is still or reverses periodically at 2Hz 
%
% Internally, there are N obj intensities, and I will have a seq of objects
% equal to 2N, first N objs will be with periodic background and last N obj
% will be with still background.

p=ParseInput(varargin{:});

objSeed  = p.Results.objSeed;
objSizeH = p.Results.objSizeH;
objSizeV = p.Results.objSizeV;
objCenterXY = p.Results.objCenterXY;
backContrast = p.Results.backContrast;
backJitterPeriod = p.Results.backJitterPeriod;
stimSize = p.Results.stimSize;
presentationLength = p.Results.presentationLength;
movieDurationSecs = p.Results.movieDurationSecs;
pdStim = p.Results.pdStim;
debugging = p.Results.debugging;
barsWidth = p.Results.barsWidth;
waitframes = p.Results.waitframes;

objIntensities = (1:4)*64;
objIntensities = objIntensities - mean(objIntensities) + 127;

CreateStimuliLogStart()
global vbl screen
if isempty(vbl)
    vbl=0;
end

% Redefine exp time to have an even number of jitters
movieDurationSecs = presentationLength* ...
    floor(movieDurationSecs/(presentationLength));

LoadHelperFunctions();
try
    InitScreen(debugging);
    
    % make the background texture
    x= 1:stimSize;
    bars = ceil(mod(floor(x/barsWidth),2)*2*screen.gray*backContrast...
        + screen.gray*(1-backContrast));
    backTex = Screen('MakeTexture', screen.w, bars);

    % Define the background Destination Rectangle
    backRect = SetRect(0,0,stimSize, stimSize);
    backRect = CenterRect(backRect, screen.rect);
    
    % Define the obj Destination Rectangle
    objRect = SetRect(0,0,objSizeH, objSizeV);
    objRect = CenterRect(objRect, screen.rect);
    objRect = OffsetRect(objRect, objCenterXY(1), objCenterXY(2));

    % Define the source rectangles
    backSource = SetRect(0,0,stimSize,1);
    
    % Define the PD box
    pd = SetRect(0,0, 100, 100);
    pd = CenterRectOnPoint(pd, screen.rect(3)*.95, screen.rect(4)*.15);
    

    framesPerSec = 60/waitframes;
    
    % make the jitterN random sequences
    jumpsPerPeriod = round(backJitterPeriod*framesPerSec);
    jitterSeq = zeros(1, jumpsPerPeriod);
    jitterSeq(1,1) = barsWidth/2;
    jitterSeq(1, jumpsPerPeriod/2+1) = -barsWidth/2;
    jitterStillSeq = zeros(1, jumpsPerPeriod);

    % We run at most 'consPresentationsN' if user doesn't abort via
    % keypress.
    presentationsN = movieDurationSecs/presentationLength;

    % make the random sequence of object intensities to display
    rand('seed', objSeed);
    objSeq = randperm(presentationsN);
    intensitiesN = size(objIntensities,2);
    objSeq = mod(objSeq, intensitiesN*3);     % make objSeq between 0 and 3*intensitiesN-1
    objSeq = mod(objSeq, intensitiesN*2)+1;     % make objSeq between 1 and 2*intensitiesN but
                                                        % first half has
                                                        % doulbe
                                                        % probability
    % Define some needed variables
    
        
    % Perform initial Flip to sync us to the VBL and for getting an initial
    % VBL-Timestamp for our "WaitBlanking" emulation:
%    vbl = Wait2Start(screen.w, debugging, ['Recotrd for ', num2str(movieDurationSecs+RFlength), ' secs']);
    framesN = presentationLength*60;
    
    % Animationloop:
    for presentation = 1:presentationsN
        stim = objSeq(presentation);
        objColor = objIntensities(mod(stim, intensitiesN)+1);
        if (stim>intensitiesN)
            % still background
            backSeq = jitterStillSeq;
        else
            backSeq = jitterSeq;
        end
        
        JitteringBackTex_UniformFieldObj(backSeq, objColor, screen, ...
            waitframes, framesN, backTex, backRect, backSource, objRect, pd, pdStim)

        if (KbCheck)
            break
        end
    end
    
    if (presentation == presentationsN)   % if it got here without any key being pressed
        CreateStimuliLogWrite(p);
    end
    
catch
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.
    FinishExperiment();
    psychrethrow(psychlasterror);
end %try..catch..
end


function VariableSpeedJumpsInBackground(varargin)
% Wrapper to call JitteringBackTex_UniformFieldObj
%
% Divide the screen in object and background.
% Object will be a uniform field box of binary flickering intensity.
% Back will be a grating of a giving contrast and spatial frequency.
% Back grating will be still for a constant time (something like 500ms) 
% and then will jump a number of pixels (between 0 and barsWidth) producing
% instantaneous jumps of different strength which is similar to different
% velocities although jumps are instantaneous.
%
% The experiment is divided in presentations. Each presentation is defined
% by the length of the presentation, the background sequence and the object
% sequence.
% Background and object sequences have independent durations.
% If the presentation lasts longer than either background or object sequence
% then they start over.
% In this way I can:
%   1) make repeats of a given object and background.
%   2) make repeats of a given background with several different objects.
%   3) make repeats of a given object with several different background.
%   4) make repeats where the object and background get out of phase.



    p=ParseInput(varargin{:});

    objContrast = p.Results.objContrast;
    objJitterPeriod = p.Results.objJitterPeriod;
    objSeed = p.Results.objSeed;
    stimSize = p.Results.stimSize;
    objSizeH = p.Results.objSizeH;
    objSizeV = p.Results.objSizeV;
    objCenterXY = p.Results.objCenterXY;
    backSeed = p.Results.backSeed;
    backContrast = p.Results.backContrast;
    backJitterPeriod = p.Results.backJitterPeriod;
    presentationLength = p.Results.presentationLength;
    movieDurationSecs = p.Results.movieDurationSecs;
    pdStim = p.Results.pdStim;
    debugging = p.Results.debugging;
    barsWidth = p.Results.barsWidth;
    waitframes = p.Results.waitframes;
    
    objIntensities = (1:4)*64;
    objIntensities = objIntensities - mean(objIntensities) + 127;

    CreateStimuliLogStart()
    global vbl screen
    if isempty(vbl)
        vbl=0;
    end

% Redefine exp time to have an even number of jitters
movieDurationSecs = presentationLength* ...
    floor(movieDurationSecs/presentationLength);

LoadHelperFunctions();
try
    InitScreen(debugging);
    
    % make the background texture
    x= 1:stimSize;
    bars = ceil(mod(floor(x/barsWidth),2)*2*screen.gray*backContrast...
        + screen.gray*(1-backContrast));
    backTex = Screen('MakeTexture', screen.w, bars);

    % Define the background Destination Rectangle
    backRect = SetRect(0,0,stimSize, stimSize);
    backRect = CenterRect(backRect, screen.rect);
    
    % Define the obj Destination Rectangle
    objRect = SetRect(0, 0, objSizeH, objSizeV);
    objRect = CenterRect(objRect, screen.rect);
    objRect = OffsetRect(objRect, objCenterXY(1), objCenterXY(2));

    % Define the source rectangles
    backSource = SetRect(0,0,stimSize,1);
    
    % Define the PD box
    pd = SetRect(0,0, 100, 100);
    pd = CenterRectOnPoint(pd, screen.rect(3)*.95, screen.rect(4)*.15);
    
    
    % Some Experimental variables
    framesPerSec = 60/waitframes;
    backJumpsPerPeriod = round(backJitterPeriod*framesPerSec);
    objJumpsPerPeriod = round(objJitterPeriod*framesPerSec);

       
    % We run at most 'consPresentationsN' if user doesn't abort via
    % keypress.
    presentationsN = movieDurationSecs/presentationLength;

    % Define the number of jumps and their sizes
    backJumpsN = log(barsWidth)/log(2)+2;

    % Generate the sequence of jumps for the background.
    % In the way is coded, jumps sizes are powers of 2. There is one jump
    % that corresponds to 2*barsWidth (32 if barsWidth=16) which is
    % equivalent to 0 size but is easier to code a 32 than a 0.
    rand('seed',backSeed);
    backPresentationSeq = mod(randperm(presentationsN), backJumpsN)+1;
    backJumpsSizes = 2.^((1:backJumpsN)-1);
    backFrameSeq = zeros(1, backJumpsPerPeriod);
    framesInBetweenJumps = 60*backJitterPeriod;
    index2backJumps = 1:framesInBetweenJumps:backJumpsPerPeriod;
    
    % start the Random Generator
    objNextSeeds = ones(1, backJumpsN)*objSeed;

    % Define some needed variables
    
    framesN = presentationLength*60;
    
    % Animationloop:
    for presentation = 1:presentationsN

        background = backPresentationSeq(presentation);        
        
        % get the background random sequence
        backJumpsSeq = ones(1, size(index2backJumps, 2))*backJumpsSizes(background);
        index = logical(diff([0 floor(cumsum(backJumpsSeq)/barsWidth/2)]));
        backJumpsSeq(index) = backJumpsSeq(index)-2*barsWidth;
        backFrameSeq(index2backJumps) = backJumpsSeq;
        %backFrameSeqSum = cumsum(backFrameSeq);

        % get the object random sequence
        rand('seed',objNextSeeds(background));
        objSeq = (rand(1, objJumpsPerPeriod)>.5)*2*screen.gray*objContrast+screen.gray*(1-objContrast);
        objNextSeeds(background) = rand('seed');

        JitteringBackTex_UniformFieldObj(backFrameSeq, objSeq, screen, ...
            waitframes, framesN, backTex, backRect, backSource, objRect, pd, pdStim)
        
        if (KbCheck)
            break
        end
    end
    
    if (presentation == presentationsN)   % if it got here without any key being pressed
        CreateStimuliLogWrite(p);
    end
    
catch
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.
    FinishExperiment();
    psychrethrow(psychlasterror);
end %try..catch..
end

