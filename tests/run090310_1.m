% File executed on: 03-Sep-2010 15:10:03
% List of default arguments:
% backContrast = 1
% backJitterPeriod = 11
% backReverseFreq = 1
% backSeed = 2
% barsWidth = 8
% debugging = 0
% movieDurationSecs = 1600
% objCenterXY = 0  0
% objContrast = 0.05
% objJitterPeriod = 11
% objSeed = 1
% objSizeH = 192
% objSizeV = 192
% pdStim = 1
% presentationLength = 11
% repeatBackSeq = 0
% stimSize = 512
% vbl = 0
% waitframes = 1
function run090310()
CreateStimuliLogStart();

Wait2Start()

% start with some RF
pdStim=0;
%RF('movieDurationSecs', 572, ...
%   'barsWidth',16, ...
%   'objContrast',1, ...
%   'pdStim', pdStim, ...
%   'waitFrames', 2 ...
%   );

pdStim=pdStim+1;
%StableObject_xxF( ...
%    'backContrast', 1, ...
%    'repeatBackSeq', 1, ...
%    'movieDurationSecs', 440 ...
%);          % lasts 440 secs, 4 intensities * 11 secs *10 repeats.

% 572+440 = 1012 secs
% 660+352 = 1012 secs
% record for 1012*6 = 6072

for i=0:4
    objContrast = 3*2^i/100;
    pdStim=pdStim+1;
    UFlickerObj_SSF( ...
        'objContrast', objContrast, ...
        'backContrast', 1, ...
        'movieDurationSecs', 660, ...
        'pdStim', pdStim, ...
        'objSeed',i, ...
        'backSeed',i+1 ...
    );

    pdStim=pdStim+1;    
    FixedObjPhases_SSx( ...
        'objContrast', objContrast, ...
        'backContrast', 1 ...
);          % lasts 352 secs
end

CreateStimuliLogWrite();
end


function [exitFlag] = BinaryCheckers(framesN, waitframes, checkersV, checkersH, objContrast)
    exitFlag = -1;
    frame = 0;
    global vbl screen objRect pd pdStim
    
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

    clear Screen
    saveLog = questdlg('Do you want to save the log file', '', 'Yes', 'No', 'Yes');
    if (strcmp(saveLog, 'Yes'))
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
        if (nargin==0)
            % get default values
            p=ParseInput();
            fprintf(fid, '%% List of default arguments:\n');
        else
            fprintf(fid, '%% List of all arguments:\n');
        end

        fieldNames = fieldnames(p.Results);
        for i=1:length(fieldNames)
            fprintf(fid, ['%% ', char(fieldNames(i)), ' = ', num2str(p.Results.(char(fieldNames(i)))), '\n']);
        end
        fprintf(fid, '\n');
    
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
    end
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

function JitterBackTex_JitterObjTex(backSeq, objSeq, ...
    waitframes, framesN, backTex, objTex)
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
    global vbl screen backRect backSource objRect objSource pd pdStim
    
    % init the frame counter
    frame = 0;
    
%    backShiftRect = [0 0 0 0];
%    objShiftRect = [0 0 0 0];
    
    backSeqN = size(backSeq,2);
    objSeqN = size(objSeq, 2);
    
    while (frame < framesN) & ~KbCheck %#ok<AND2>
        % Background Drawing
        % ---------- -------
        backIndex = mod(frame/waitframes, backSeqN)+1;
        backSource = backSource + backSeq(backIndex)*[1 0 1 0];

        Screen('DrawTexture', screen.w, backTex, backSource, backRect, 0,0);

        % Object Drawing
        % --------------
        objIndex = mod(frame/waitframes, objSeqN)+1;
%        objShiftRect = objShiftRect + objSeq(objIndex)*[1 0 1 0];
        objSource = objSource + objSeq(objIndex)*[1 0 1 0];

%        Screen('DrawTexture', screen.w, objTex, objSource + objShiftRect, objRect, 0,0);
        Screen('DrawTexture', screen.w, objTex, objSource, objRect, 0,0);
        

        % Photodiode box
        % --------------
        DisplayStimInPD2(pdStim, pd, frame, 60, screen)

        % Flip 'waitframes' monitor refresh intervals after last redraw.
        vbl = Screen('Flip', screen.w, vbl + (waitframes - 0.5) * screen.ifi);
        frame = frame + waitframes;

    end
    
end

function JitteringBackTex_UniformFieldObj(jitterSeq, objSeq, ...
    waitframes, framesN, backTex)
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

    global vbl screen backRect backSource objRect pd pdStim
    
    % init the frame counter
    frame = 0;
    
    jumpsN = size(jitterSeq,2);
    objSeqN = size(objSeq, 2);
    
    while (frame < framesN) & ~KbCheck %#ok<AND2>
        
        backIndex = mod(frame/waitframes, jumpsN)+1;
        backSource = backSource + jitterSeq(backIndex)*[1 0 1 0];

        Screen('DrawTexture', screen.w, backTex, backSource, backRect, 0,0)

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
    p.addParamValue('objContrast', .05, @(x)x>=0 && x<=1);
    p.addParamValue('objJitterPeriod', 11, @(x)x>0 );
    p.addParamValue('objSeed', 1, @(x)isnumeric(x));
    p.addParamValue('objSizeH', 16*12, @(x)x>0);
    p.addParamValue('objSizeV', 16*12, @(x)x>0);
    p.addParamValue('objCenterXY', [0 0], @(x)size(x,2)==2);
    
    % Background related
    p.addParamValue('backSeed', 2, @(x)isnumeric(x));
    p.addParamValue('backContrast', 1, @(x)x>=0 && x<=1);
    p.addParamValue('backJitterPeriod', 11, @(x)x>0);
    p.addParamValue('backReverseFreq', 1, @(x) x>0);
    p.addParamValue('repeatBackSeq',0,@(x) x==0 || x==1);
    
        % General
    p.addParamValue('stimSize', 16*32, @(x)x>0);
    p.addParamValue('presentationLength', 11, @(x)x>0);
    p.addParamValue('movieDurationSecs', 1600, @(x)x>0);
    p.addParamValue('pdStim', 1, @(x)x>=0 && x<256);
    p.addParamValue('debugging', 0, @(x)x>=0 && x <=1);
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

function Wait2Start(varargin)
    global vbl screen
    if isempty(vbl)
        vbl=0;
    end

    LoadHelperFunctions();

    p=ParseInput(varargin{:});
    debugging = p.Results.debugging;
    

    InitScreen(debugging);
 
    KbName('UnifyKeyNames');
    
    while ~debugging
        Screen('FillRect', screen.w, 128);
        Screen(screen.w,'TextSize', 24);
        text = 'Press any key to start stimulus';
        
        Screen(screen.w, 'DrawText', text ,30,30, 0 );
        vbl = Screen('Flip',screen.w);

        if (max(Screen('Screens'))==0)
            WaitForRec();
            break;
        elseif KbWait
            pause(0.2);
            break;
        end
    end
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

function FixedObjPhases_SSx(varargin)
%   Stimulus is divided in object and background. Each one with its own
%   contrast. Spatialy, both are going to be gratings of a given barsWidth.
%   Temporally, background can either be still or reversing at
%   backReverseFreq. The object will be changing between 4 different phases
%   at backReverseFreq. All possible combinations of 4 phases are
%   considering giving a total of 16 different jumps. There is nothing
%   random in this experiment.

   global vbl screen backRect backSource objRect objSource pd
 


    p=ParseInput(varargin{:});

    objContrast = p.Results.objContrast;
    debugging = p.Results.debugging;
    objSizeH = p.Results.objSizeH;
    objSizeV = p.Results.objSizeV;
    objCenterXY = p.Results.objCenterXY;
    backReverseFreq = p.Results.backReverseFreq;
    stimSize = p.Results.stimSize;
    barsWidth = p.Results.barsWidth;
    backContrast = p.Results.backContrast;
    waitframes = p.Results.waitframes;
    
    CreateStimuliLogStart()
    if isempty(vbl)
        vbl=0;
    end

    phasesN = 4;
    presentationLength = 1/backReverseFreq/2;
    repeats = 11;
    globalRepeats = 4;
    movieDurationSecs = globalRepeats*presentationLength*repeats*phasesN^2;
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
    backSourceOri = backSource;
    objSourceOri = objSource;

    % Define the PD box
    pd = SetRect(0,0, 100, 100);
    pd = CenterRectOnPoint(pd, screen.rect(3)*.95, screen.rect(4)*.15);
    
    framesPerSec = 60/waitframes;
    objSeqFramesN = presentationLength*framesPerSec;
    
    % make the back sequences (one still, one saccade like)
    backSeq(1,:) = zeros(1, objSeqFramesN);
    backSeq(2,1) = barsWidth/2;

    % make the object sequence of jumps. Jumps are separeted every
    % saccadeFrames.
    %phaseSequence = [0 1 1 2 3 0 0 2 1 0 3 3 1 3 2 2];
    objSeq = zeros(1, objSeqFramesN);
    objJumpsSeq=[2 1 0 1 1 1 0 2 -1 -1 -1 0 2 2 -1 0]*barsWidth/2;

    % We run at most 'consPresentationsN' if user doesn't abort via
    % keypress.
    presentationsN = movieDurationSecs/presentationLength;

    % Define some needed variables
    

    framesN = presentationLength*60;
    
    % Animationloop:
    for presentation = 0:presentationsN-1
        background = mod(floor(presentation/phasesN^2/repeats), 2)+1;
        objSeq(1) = objJumpsSeq(mod(presentation, phasesN^2)+1);
        
        JitterBackTex_JitterObjTex(backSeq(background,:), objSeq, ...
            waitframes, framesN, backTex, objTex);

        % Previous function DID modify backSource. Recenter it to prevent
        % too much sliding of the texture.
        % Is not perfect and sliding will still take place but will be
        % slower and hopefully will be ok
        backSource = mod(backSource, 2*barsWidth)+backSourceOri.*[1 0 1 0];
        objSource = mod(objSource, 2*barsWidth)+objSourceOri.*[1 0 1 0];

        if (KbCheck)
            break
        end
    end
    
    if (~debugging)
        CreateStimuliLogWrite(p);
    end

catch
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.
    FinishExperiment();
    psychrethrow(psychlasterror);
end %try..catch..
end

function LoadHelperFunctions()
    % load Helper functions
    oldDir = pwd;
    cd ..
    cd('HelperFunctions');
    addpath(genpath(pwd));
    cd(oldDir)
end
function LowContrastObj_SSF(varargin)



    CreateStimuliLogStart()
    global vbl screen backRect backSource objRect objSource pd pdStim
    if isempty(vbl)
        vbl=0;
    end

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
    backReverseFreq = p.Results.backReverseFreq;
    waitframes = p.Results.waitframes;
    pdStim = p.Results.pdStim;

    backSeqN = 3;       % there are only two backgrounds, the random one and a still one.

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
    x= 1:3*objSizeH;
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
    backSourceOri = backSource;
    objSourceOri = objSource;
    
    % Define the PD box
    pd = SetRect(0,0, 100, 100);
    pd = CenterRectOnPoint(pd, screen.rect(3)*.95, screen.rect(4)*.15);
    
    framesPerSec = 60/waitframes;
    objJumpsPerPeriod = round(objJitterPeriod*framesPerSec);

    %when background is reversing (jumping) how many frames is the period
    %of the reversing?
    backReverseFrames = round(framesPerSec/backReverseFreq);
    
    % make the back still and reversing sequences
    stillSeq = zeros(1, objJumpsPerPeriod);
    
    
    reverseSeq = zeros(1, objJumpsPerPeriod);
    ForwardFrames = 1:backReverseFrames:objJumpsPerPeriod;
    reverseSeq(1,ForwardFrames)=   barsWidth;
    reverseSeq(1,ForwardFrames + backReverseFrames/2)=  -barsWidth;

    
    % We run at most 'consPresentationsN' if user doesn't abort via
    % keypress.
    presentationsN = movieDurationSecs/presentationLength;

    % Define some needed variables
    

    framesN = presentationLength*60;
    rand('seed', objSeed);

    % Animationloop:
    for presentation = 0:presentationsN-1
        switch (mod(presentation, 3))
            case 0
                backSeq = stillSeq;
                %objSeed = rand('seed');
                % get the random sequence of jumps for the object
                objSeq = floor(rand(1, objJumpsPerPeriod)*3)-1;

            case 1
                backSeq = reverseSeq;
                %rand('seed', objSeed);
            case 2
                % somewhat anelegant coding. Setting backSeq to the
                % objSeq used in the previuos presentation. Ends up working
                % ok because the objSeq of this presentation will be
                % identical.
                backSeq = objSeq;
                %rand('seed', objSeed);
        end


        JitterBackTex_JitterObjTex(backSeq, objSeq, waitframes, framesN, ...
            backTex, objTex)

        % Previous function DID modify backSource and objSource.
        % Recenter backSource to prevent too much sliding of the texture.
        % objSource has to be reinitialize so that all 3 sequences will
        % have the same phase.
        backSource = mod(backSource, 2*barsWidth)+backSourceOri.*[1 0 1 0];
        objSource = objSourceOri;

        if (KbCheck)
            break
        end
    end
    
    if (~debugging)
        CreateStimuliLogWrite(p);
    end

catch
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.
    FinishExperiment();
    psychrethrow(psychlasterror);
end %try..catch..
end

function LowContrastObj_SxF(varargin)
%   
   global vbl screen backRect backSource objRect objSource pd pdStim
 


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
    backSourceOri = backSource;
    objSourceOri = objSource;

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
    rand('seed', objSeed);
    
    % Animationloop:
    for presentation = 1:presentationsN
        % get the random sequence of jumps for the object
        objSeq = floor(rand(1, objJumpsPerPeriod)*3)-1;

        if (mod(presentation, 2))
            % Global Motion
            backSeq = objSeq;
            rand('seed', objSeed);
        else            
            % Differential Motion
            backSeq = stillSeq;
           objSeed = rand('seed');
        end

        JitterBackTex_JitterObjTex(backSeq, objSeq, ...
            waitframes, framesN, backTex, objTex);

        % Previous function DID modify backSource. Recenter it to prevent
        % too much sliding of the texture.
        % Is not perfect and sliding will still take place but will be
        % slower and hopefully will be ok
        backSource = mod(backSource, 2*barsWidth)+backSourceOri.*[1 0 1 0];
        objSource = mod(objSource, 2*barsWidth)+objSourceOri.*[1 0 1 0];

        if (KbCheck)
            break
        end
    end
    
    if (~debugging)
        CreateStimuliLogWrite(p);
    end

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

    CreateStimuliLogStart()
    global vbl screen objRect pd pdStim
    if isempty(vbl)
        vbl=0;
    end

    p=ParseInput(varargin{:});

    objContrast = p.Results.objContrast;
    seed  = p.Results.objSeed;
    movieDurationSecs = p.Results.movieDurationSecs;
    stimSize = p.Results.stimSize;
    pdStim = p.Results.pdStim;
    debugging = p.Results.debugging;
    checkerSize = p.Results.barsWidth;
    waitframes = p.Results.waitframes;
    objCenterXY = p.Results.objCenterXY;
    

try
    InitScreen(debugging);

    checkersN_H = ceil(stimSize/checkerSize);
    checkersN_V = checkersN_H;
    
    % Define the obj Destination Rectangle
    objRect = SetRect(0,0, checkersN_H, checkersN_V)*checkerSize;
    objRect = CenterRect(objRect, screen.rect);
    objRect = OffsetRect(objRect, objCenterXY(1), objCenterXY(2));

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
    BinaryCheckers(framesN, waitframes, checkersN_V, checkersN_H, objContrast);
    
    if (~debugging)
        CreateStimuliLogWrite(p);
    end
catch
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.
    FinishExperiment();
    psychrethrow(psychlasterror);
end %try..catch..
end



function StableObject_SSF(varargin)
% Wrapper to call JitteringBackTex_UniformFieldObj
%
% Divide the screen in object and background.
% Object will be a uniform field box of a given intensity that will
% change very slowly ~5-10 secs.
% Back will be a grating of a giving contrast and spatial frequency
% that either is still, reverses periodically at backReverseFreq of follows
% random jitter.
%
% Internally, there are N obj intensities, and I will have a seq of objects
% equal to 2N, first N objs will be with periodic background and last N obj
% will be with still background.

CreateStimuliLogStart()
global vbl screen backRect backSource objRect pd pdStim
if isempty(vbl)
    vbl=0;
end

p=ParseInput(varargin{:});

objSeed  = p.Results.objSeed;
objSizeH = p.Results.objSizeH;
objSizeV = p.Results.objSizeV;
objCenterXY = p.Results.objCenterXY;
backSeed  = p.Results.backSeed;
backContrast = p.Results.backContrast;
backJitterPeriod = p.Results.backJitterPeriod;
backReverseFreq = p.Results.backReverseFreq;
repeatBackSeq = p.Results.repeatBackSeq;

stimSize = p.Results.stimSize;
presentationLength = p.Results.presentationLength;
movieDurationSecs = p.Results.movieDurationSecs;
pdStim = p.Results.pdStim;
debugging = p.Results.debugging;
barsWidth = p.Results.barsWidth;
waitframes = p.Results.waitframes;

objIntensities = (1:4)*64;
objIntensities = objIntensities - mean(objIntensities) + 127;


% Redefine exp time to have an even number of jitters
movieDurationSecs = presentationLength* ...
    floor(movieDurationSecs/(presentationLength));

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
    objRect = SetRect(0,0,objSizeH, objSizeV);
    objRect = CenterRect(objRect, screen.rect);
    objRect = OffsetRect(objRect, objCenterXY(1), objCenterXY(2));

    % Define the source rectangles
    backSource = SetRect(stimSize/2,0,3/2*stimSize,1);
    backSourceOri = backSource;
    
    % Define the PD box
    pd = SetRect(0,0, 100, 100);
    pd = CenterRectOnPoint(pd, screen.rect(3)*.95, screen.rect(4)*.15);
    

    framesPerSec = 60/waitframes;
    
    % make the jitterSeq corresponding to still, saccades and FEM (the one
    % corresponding to FEM will only be used if repeatBackSeq==1)
    jumpsPerPeriod = round(backJitterPeriod*framesPerSec);
    saccadeFrames = 1:framesPerSec/backReverseFreq/2:jumpsPerPeriod;
    jitterSeq(1:2,:) = zeros(2, jumpsPerPeriod);
    jitterSeq(2,saccadeFrames) = barsWidth;
    rand('seed', backSeed);
    jitterSeq(3,:) = floor(rand(1, jumpsPerPeriod)*3)-1;

    % We run at most 'consPresentationsN' if user doesn't abort via
    % keypress.
    presentationsN = movieDurationSecs/presentationLength;

    % make the random sequence of object intensities to display
    rand('seed', objSeed);
    stimSeq = randperm(presentationsN);
    intensitiesN = size(objIntensities,2);
    stimSeq = mod(stimSeq, 3*intensitiesN);     % make stimSeq between 0 and 3*intensitiesN-1

    objSeq = mod(stimSeq, intensitiesN)+1;     % make objSeq between 1 and 3*intensitiesN
    backStimSeq = floor(stimSeq/intensitiesN)+1;
    
        
    % Perform initial Flip to sync us to the VBL and for getting an initial
    % VBL-Timestamp for our "WaitBlanking" emulation:
    framesN = presentationLength*60;
    
    rand('seed', backSeed);

    % Animationloop:
    for presentation = 1:presentationsN
        objColor = objIntensities(objSeq(presentation));
        backStim = backStimSeq(presentation);
        if (backStim == 3 && ~repeatBackSeq)
            backSeq = floor(rand(1, jumpsPerPeriod)*3)-1;
        else
            backSeq = jitterSeq(backStim, :);
        end
%backSeq(1:10)
        JitteringBackTex_UniformFieldObj(backSeq, objColor, ...
            waitframes, framesN, backTex)

        % Recenter backSource to prevent too much sliding of the texture.
        % Is not perfect and sliding will still take place but will be
        % slower and hopefully will be ok
        backSource = mod(backSource, 2*barsWidth)+backSourceOri;

        if (KbCheck)
            break
        end
    end
    
    if (~debugging)
        CreateStimuliLogWrite(p);
    end
    
catch
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.
    FinishExperiment();
    psychrethrow(psychlasterror);
end %try..catch..
end


function StableObject_SSx(varargin)
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

CreateStimuliLogStart()
global vbl screen backRect backSource objRect pd pdStim
if isempty(vbl)
    vbl=0;
end

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
    jitterSeq(1:2,:) = zeros(2, jumpsPerPeriod);
    jitterSeq(2,1) = barsWidth/2;
    jitterSeq(2, jumpsPerPeriod/2+1) = -barsWidth/2;

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
            backSeq = jitterSeq(1,:);
        else
            backSeq = jitterSeq(2,:);
        end

        
        JitteringBackTex_UniformFieldObj(backSeq, objColor, ...
            waitframes, framesN, backTex)
        

        if (KbCheck)
            break
        end
    end
    
    if (~debugging)
        CreateStimuliLogWrite(p);
    end
    
catch
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.
    FinishExperiment();
    psychrethrow(psychlasterror);
end %try..catch..
end


function StableObject_SxF(varargin)

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
    CreateStimuliLogStart()
    global vbl screen backRect backSource objRect pd pdStim
    if isempty(vbl)
        vbl=0;
    end
    LoadHelperFunctions();

    p=ParseInput(varargin{:});

    %objContrast = p.Results.objContrast;
    %objJitterPeriod = p.Results.objJitterPeriod;
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
    backSourceOri = backSource;
    
    % Define the PD box
    pd = SetRect(0,0, 100, 100);
    pd = CenterRectOnPoint(pd, screen.rect(3)*.95, screen.rect(4)*.15);
    

    framesPerSec = 60/waitframes;
    
    % make the background Jitter random sequences
    backJumpsPerPeriod = round(backJitterPeriod*framesPerSec);
    jitterSeq(1,:) = zeros(1, backJumpsPerPeriod);
    rand('seed', backSeed);
    jitterSeq(2,:) = floor(rand(1, backJumpsPerPeriod)*3)-1;
 %   jitterShift = 0;
 %   jitterShiftPerPeriod = sum(jitterSeq(2,:));
    
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
        
        JitteringBackTex_UniformFieldObj(backSeq, objColor, ...
            waitframes, framesN, backTex)

        % Recenter backSource to prevent too much sliding of the texture.
        % Is not perfect and sliding will still take place but will be
        % slower and hopefully will be ok
        backSource = mod(backSource, 2*barsWidth)+backSourceOri;

        if (KbCheck)
            break
        end
    end
    
    if (~debugging)
        CreateStimuliLogWrite(p);
    end
catch
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.
    FinishExperiment();
    psychrethrow(psychlasterror);
end %try..catch..
end


function StableObject_xxF(varargin)
% Wrapper to call JitteringBackTex_UniformFieldObj
%
% Divide the screen in object and background.
% Object will be a uniform field box of a given intensity that will
% change very slowly ~5-10 secs.
% Back will be a grating of a giving contrast and spatial frequency
% that will follow random jitter.
%
% Internally, there are N obj intensities, and I will have a seq of objects
% equal to 2N, first N objs will be with periodic background and last N obj
% will be with still background.

CreateStimuliLogStart()
global vbl screen backRect backSource objRect pd pdStim
if isempty(vbl)
    vbl=0;
end

p=ParseInput(varargin{:});

objSeed  = p.Results.objSeed;
objSizeH = p.Results.objSizeH;
objSizeV = p.Results.objSizeV;
objCenterXY = p.Results.objCenterXY;
backSeed  = p.Results.backSeed;
backContrast = p.Results.backContrast;
backJitterPeriod = p.Results.backJitterPeriod;
repeatBackSeq = p.Results.repeatBackSeq;

stimSize = p.Results.stimSize;
presentationLength = p.Results.presentationLength;
movieDurationSecs = p.Results.movieDurationSecs;
pdStim = p.Results.pdStim;
debugging = p.Results.debugging;
barsWidth = p.Results.barsWidth;
waitframes = p.Results.waitframes;

objIntensities = (1:4)*64;
objIntensities = objIntensities - mean(objIntensities) + 127;


% Redefine exp time to have an even number of jitters
movieDurationSecs = presentationLength* ...
    floor(movieDurationSecs/(presentationLength));

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
    objRect = SetRect(0,0,objSizeH, objSizeV);
    objRect = CenterRect(objRect, screen.rect);
    objRect = OffsetRect(objRect, objCenterXY(1), objCenterXY(2));

    % Define the source rectangles
    backSource = SetRect(stimSize/2,0,3/2*stimSize,1);
    backSourceOri = backSource;
    
    % Define the PD box
    pd = SetRect(0,0, 100, 100);
    pd = CenterRectOnPoint(pd, screen.rect(3)*.95, screen.rect(4)*.15);
    

    framesPerSec = 60/waitframes;
    
    % make the jitterSeq corresponding to FEM (will only be used if repeatBackSeq==1)
    jumpsPerPeriod = round(backJitterPeriod*framesPerSec);
    rand('seed', backSeed);
    jitterSeq = floor(rand(1, jumpsPerPeriod)*3)-1;

    % We run at most 'consPresentationsN' if user doesn't abort via
    % keypress.
    presentationsN = movieDurationSecs/presentationLength;

    % make the random sequence of object intensities to display
    rand('seed', objSeed);
    intensitiesN = size(objIntensities,2);
    objSeq = floor((0:presentationsN-1)/(presentationsN/intensitiesN))+1;
%    objSeq = mod(stimSeq, intensitiesN) + 1;     % make stimSeq between 1 and intensitiesN    
        
    % Perform initial Flip to sync us to the VBL and for getting an initial
    % VBL-Timestamp for our "WaitBlanking" emulation:
    framesN = presentationLength*60;
    
    rand('seed', backSeed);

    % Animationloop:
    for presentation = 1:presentationsN
        objColor = objIntensities(objSeq(presentation));
        if (~repeatBackSeq)
            jitterSeq = floor(rand(1, jumpsPerPeriod)*3)-1;
        end
%jitterSeq(1:10)
        JitteringBackTex_UniformFieldObj(jitterSeq, objColor, ...
            waitframes, framesN, backTex)

        % Recenter backSource to prevent too much sliding of the texture.
        % Is not perfect and sliding will still take place but will be
        % slower and hopefully will be ok
        backSource = mod(backSource, 2*barsWidth)+backSourceOri;

        if (KbCheck)
            break
        end
    end
    
    if (~debugging)
        CreateStimuliLogWrite(p);
    end
    
catch
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.
    FinishExperiment();
    psychrethrow(psychlasterror);
end %try..catch..
end


function UFlickerObj_SSF(varargin)
% Wrapper to call JitteringBackTex_UniformFieldObj
%
% Divide the screen in object and background.
% Object will be a uniform field box of gaussian random intensity.
% Back will be a grating of a giving contrast and spatial frequency.
% Back grating will be following several different sequences.
% Seq 1:    still background (control)
% Seq 2:    jumping background
% Seq 3:    'randomly' jittering
% The 'randomly' jittering sequence is compossed of -1, 0, 1 pixel jumps
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
%
% The random background sequence is different across presentations.
% The object random sequence is different for every presentation but is the
% same across backgrounds. Meaning that for a given presentation background
% 1 has the same object as background 2 and 3, but the nth presentation has
% a different object than the mth presentation.

    % if you want to change a parameter from its default value you have to
    % type 'paramToChange', newValue, ...
    % List of possible params is:
    % objContrast, objJitterPeriod, objSeed, stimSize, objSizeH, objSizeV,
    % objCenterXY, backContrast, backJitterPeriod, presentationLength,
    % movieDurationSecs, pdStim, debugging, barsWidth, waitframes, vbl
    CreateStimuliLogStart()
    global vbl screen backRect backSource objRect pd pdStim
    if isempty(vbl)
        vbl=0;
    end

    p=ParseInput(varargin{:});

    objContrast = p.Results.objContrast;
    objJitterPeriod = p.Results.objJitterPeriod;
    objSeed  = p.Results.objSeed;
    objSizeH = p.Results.objSizeH;
    objSizeV = p.Results.objSizeV;
    objCenterXY = p.Results.objCenterXY;
    backSeed = p.Results.backSeed;
    backContrast = p.Results.backContrast;
    backJitterPeriod = p.Results.backJitterPeriod;      % for random jittering
    backReverseFreq = p.Results.backReverseFreq;        % for reversing
    stimSize = p.Results.stimSize;
    presentationLength = p.Results.presentationLength;
    movieDurationSecs = p.Results.movieDurationSecs;
    pdStim = p.Results.pdStim;
    debugging = p.Results.debugging;
    barsWidth = p.Results.barsWidth;
    waitframes = p.Results.waitframes;
    
    backJitterN = 3;
    

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
    backSourceOri = backSource;
    
    % Define the PD box
    pd = SetRect(0,0, 100, 100);
    pd = CenterRectOnPoint(pd, screen.rect(3)*.95, screen.rect(4)*.15);
    

    % start the Random Generator
%    rand('seed', backSeed);
    
    framesPerSec = 60/waitframes;
    backJumpsPerPeriod = round(backJitterPeriod*framesPerSec);
    objJumpsPerPeriod = round(objJitterPeriod*framesPerSec);
    backReverseFrames = round(framesPerSec/backReverseFreq);
    
    % make the Still and the Saccade background sequences
    jitterSeq(1:2,:)=zeros(2, backJumpsPerPeriod);
    ForwardFrames = 1:backReverseFrames:backJumpsPerPeriod;
    jitterSeq(2,ForwardFrames)=   barsWidth;
    jitterSeq(2,ForwardFrames + backReverseFrames/2)=  -barsWidth;
    
    % We run at most 'consPresentationsN' if user doesn't abort via
    % keypress.
    presentationsN = movieDurationSecs/presentationLength;
    
    % random seeds for the object sequence (one per background)
    randn('seed',objSeed);
    rand('seed', backSeed);

    framesN = presentationLength*60;

    % Animationloop:
    for presentation = 1:presentationsN
        % Background Drawing
        % ------------------

        % back = 1: still
        % back = 2: reversing
        % back = 3: random
        back = mod(presentation-1, backJitterN)+1;  

        if (back==1)
            % Sets the objSeq that will be used in the next 3 presentations
            % no need to keep track of seed since rand and randn are
            % independent
            objSeq = uint8(randn(1, objJumpsPerPeriod)*screen.gray*objContrast+screen.gray);
        elseif (back==3)    
            % sets the randomly jittering background.
            % again randn and rand are independent. No need to keep track
            % of seeds
            jitterSeq(3,:) = floor(rand(1, backJumpsPerPeriod)*3)-1;
        end
        jitter = jitterSeq(back,:);

        JitteringBackTex_UniformFieldObj(jitter, objSeq, ...
            waitframes, framesN, backTex)
        
        % Previous function DID modify backSource. Recenter it to prevent
        % too much sliding of the texture.
        % Is not perfect and sliding will still take place but will be
        % slower and hopefully will be ok
        backSource = mod(backSource, 2*barsWidth)+backSourceOri.*[1 0 1 0];

        if (KbCheck)
            break
        end
    end
    
    if (~debugging)
        CreateStimuliLogWrite(p);
    end
    
catch
    FinishExperiment();
    psychrethrow(psychlasterror);
end %try..catch..
end



function UFlickerObj_xSx(varargin)
    % if you want to change a parameter from its default value you have to
    % type 'paramToChange', newValue, ...
    % List of possible params is:
    % objContrast, objJitterPeriod, objSeed, stimSize, objSizeH, objSizeV,
    % objCenterXY, backContrast, backReverseFreq, presentationLength,
    % movieDurationSecs, pdStim, debugging, barsWidth, waitframes, vbl
    CreateStimuliLogStart()
    global vbl screen backRect backSource objRect pd pdStim
    if isempty(vbl)
        vbl=0;
    end

    p=ParseInput(varargin{:});

    objContrast = p.Results.objContrast;
    objJitterPeriod = p.Results.objJitterPeriod;
    objSeed = p.Results.objSeed;
    stimSize = p.Results.stimSize;
    objSizeH = p.Results.objSizeH;
    objSizeV = p.Results.objSizeV;
    objCenterXY = p.Results.objCenterXY;
    backContrast = p.Results.backContrast;
    backReverseFreq = p.Results.backReverseFreq;
    presentationLength = p.Results.presentationLength;
    movieDurationSecs = p.Results.movieDurationSecs;
    pdStim = p.Results.pdStim;
    debugging = p.Results.debugging;
    barsWidth = p.Results.barsWidth;
    waitframes = p.Results.waitframes;
%    vbl = p.Results.vbl;
    
% debugging     = 0 or 1
% stimSize      = 600    in pixels
% objSizeH/V    = 16*12  in pixels (16 = 100um)
% objCenterXY   = [0 0] for centered object. Is in pixels
% barsWidth     = in pixels, each bar. Period is 2*barsWidth
% backContrast  = between 0 and 1
% objContrast   = between 0 and 1
% vbl           = time of last flip, 0 if none happened yet
% backReverseFreq = number of seconds the back sequence has to jitter around
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
% Object will be a uniform field box of gaussian random intensity and a given
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

backReverseFreq = 1;           % how long should each one of the jitterN seq be (in seconds)?
objJitterPeriod = 11;            % how long should each one of the jitterN seq be (in seconds)?
presentationLength = 11*backReverseFreq;

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

%LoadHelperFunctions();
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
    objRect = SetRect(0, 0, objSizeH, objSizeV);
    objRect = CenterRect(objRect, screen.rect);
    objRect = OffsetRect(objRect, objCenterXY(1), objCenterXY(2));

    % Define the source rectangles
    backSource = SetRect(stimSize/2,0,3*stimSize/2,1);
    backSourceOri = backSource;
    
    % Define the PD box
    pd = SetRect(0,0, 100, 100);
    pd = CenterRectOnPoint(pd, screen.rect(3)*.95, screen.rect(4)*.15);
    
    framesPerSec = 60/waitframes;
    backJumpsPerPeriod = round(backReverseFreq*framesPerSec);
    objJumpsPerPeriod = round(objJitterPeriod*framesPerSec);
    
    % make the Saccading like background sequence
    jitterSeq(1,:)=zeros(1, backJumpsPerPeriod);
    jitterSeq(1,0*backJumpsPerPeriod/2+1)=   barsWidth;
    jitterSeq(1,1*backJumpsPerPeriod/2+1)=  -barsWidth;

    % We run at most 'consPresentationsN' if user doesn't abort via
    % keypress.
    presentationsN = movieDurationSecs/presentationLength;
            
    framesN = presentationLength*60;
    randn('seed',objSeed);

    % Animationloop:
    for presentation = 1:presentationsN
        objSeq = uint8(randn(1, objJumpsPerPeriod)*screen.gray*objContrast+screen.gray);
        
        JitteringBackTex_UniformFieldObj(jitterSeq, objSeq, ...
            waitframes, framesN, backTex)

        % Previous function DID modify backSource. Recenter it to prevent
        % too much sliding of the texture.
        % Is not perfect and sliding will still take place but will be
        % slower and hopefully will be ok
        backSource = mod(backSource, 2*barsWidth)+backSourceOri.*[1 0 1 0];

        if (KbCheck)
            break
        end
    end
    
    if (~debugging)
        CreateStimuliLogWrite(p);
    end
    
catch
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.
    FinishExperiment();
    psychrethrow(psychlasterror);
end %try..catch..
end

function contrastRamp()

    duration = 15;
    pLength = 1;
    CreateStimuliLogStart()
    UFlickerObj_SSF('objContrast', .05, 'movieDurationSecs', duration, 'presentationLength',pLength);
    UFlickerObj_SSF('objContrast', .10, 'movieDurationSecs', duration, 'presentationLength',pLength);
    UFlickerObj_SSF('objContrast', .15, 'movieDurationSecs', duration, 'presentationLength',pLength);
    UFlickerObj_SSF('objContrast', .20, 'movieDurationSecs', duration, 'presentationLength',pLength);
    UFlickerObj_SSF('objContrast', .25, 'movieDurationSecs', duration, 'presentationLength',pLength);
    UFlickerObj_SSF('objContrast', .30, 'movieDurationSecs', duration, 'presentationLength',pLength);
    UFlickerObj_SSF('objContrast', .35, 'movieDurationSecs', duration, 'presentationLength',pLength);

    CreateStimuliLogWrite();
end

