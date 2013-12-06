% File executed on: 06-May-2010 10:41:00
function fillingRF()
% Obj Parameters
stimSize = 640;     % will be ceiled to accomodate an integer number of checkers
objChecker = 16;
objContrast = 1%.25;
backContrast = 0;

% Back Parameters
backLinesWidth = 2*objChecker;

% Gray Rectangles parameters
%                                2 Pads          1 Pad
padSizeV = 140;                  %60;             140
padSizeH = 140;                  %43;             140
objPadN = 1;                     %2;              1
objPadsDist = 0;                 %92;             0
deltaY = 0;
deltaX = 0;

seed = 1;
waitframes = 2;
movieDurationSecs=1600; % Abort demo after 20 seconds.
switchingTime = movieDurationSecs/4;
backFrames = 30;

LoadHelperFunctions();
try
    AssertOpenGL;

    % Get the list of screens and choose the one with the highest screen number.
    screenNumber=max(Screen('Screens'));

    % Find the color values which correspond to white and black.
    white=WhiteIndex(screenNumber);
    black=BlackIndex(screenNumber);

    % Round gray to integral number, to avoid roundoff artifacts with some
    % graphics cards:
	gray=floor((white+black)/2);

    % This makes sure that on floating point framebuffers we still get a
    % well defined gray. It isn't strictly neccessary in this demo:
    if gray == white
		gray=white / 2;
    end

    % Open a double buffered fullscreen window with a gray background:
    if (screenNumber == 0)
        [w screenRect]=Screen('OpenWindow',screenNumber, gray);
%        [w screenRect]=Screen('OpenWindow',screenNumber, gray, [0 0 400 400]);
        HideCursor();
        Priority(1);
    else
%        switchingTime = 5;
        [w screenRect]=Screen('OpenWindow',screenNumber, gray);
    end

    % Before defining the parameters for the object and background textures
    % I want to make sure that obj squares are aligned with background
    % lines. In order to do that I need an integer and even number of lines
    % to fit in the backRect. Since lines width = 2*objChecker that means
    % that there is also an even number of checkers in the window.
    backLinesN = ceil(stimSize/backLinesWidth);
    backLinesN = backLinesN + mod(backLinesN, 2);   % makes backSize even
    stimSize = backLinesN * backLinesWidth;
    % make the back texture
    x=1:backLinesN;
%    backColor1 = mod(x,2)*gray*backContrast+gray*(1-backContrast)
%    backColor2 = mod(x+1,2)*gray*backContrast+gray*(1-backContrast)
    backColor1 = mod(x,2)*2*backContrast*gray;
    backColor2 = 2*backContrast*gray-backColor1;
    backTex1  = Screen('MakeTexture', w, backColor1);
    backTex2  = Screen('MakeTexture', w, backColor2);
    
    % Define object texture parameters. I am changing the obj size to
    % incorporate an integer number of squares.
    objSize = stimSize;
    objRect = SetRect(0,0,objSize, objSize);
    objRect = CenterRect(objRect, screenRect);
    objPixels = objSize/objChecker;

    % Define Back texture parameters. I am changing the back size to
    % incorporate an integer number of squares.
    backSize = stimSize;
    backRect = SetRect(0,0,backSize, backSize);
    backRect = CenterRect(backRect, screenRect);
    backLinesN = backSize/backLinesWidth;

    % Define the PD box
    pd = SetRect(0,0, 100, 100);
    pd = CenterRectOnPoint(pd, screenRect(3)*.95, screenRect(4)*.15);
    
    % Define the gray object squares to mask the background.
    padSizeH = ceil(padSizeH/objChecker)*objChecker;
    padSizeV = ceil(padSizeV/objChecker)*objChecker;    
    left = objRect(1);
    top = objRect(2);
    %RectCentered(backRect);
    for i=1:objPadN
        objPads(i,:) = SetRect(0,0,padSizeV, padSizeH);
        objPads(i,:) = CenterRect(objPads(i,:), screenRect);
        objPads(i,:) = OffsetRect(objPads(i,:), 0,round(objPadsDist/2)*(-1)^i);
        % Align the pads with the squares
        shiftX = -mod(objPads(i, 1)-left, objChecker+deltaX);
        shiftY = -mod(objPads(i, 2)-top, objChecker)+deltaY;
        objPads(i,:) = OffsetREct(objPads(i,:), shiftX, shiftY);
    end
    
    % Query duration of monitor refresh interval:
    ifi=Screen('GetFlipInterval', w);

    % Start the random generator
    rand('seed', seed);
    
    % Define some needed variables
    frame = 0;

    % We run at most 'framesN' frames if user doesn't abort via
    % keypress.
    framesN = ceil(movieDurationSecs/ifi);

    % background will be changing every 'switchingFrame' frames
    switchingFrame = 60*switchingTime;
    
    % Perform initial Flip to sync us to the VBL and for getting an initial
    % VBL-Timestamp for our "WaitBlanking" emulation:
    vbl=Wait4Button2(w);
%{    
    % Generate the arrays that will be exported into Igor
    backSeq = ones(backLinesN, framesN/waitframes,'uint8');
    checkerSeq = ones(objPixels, objPixels, framesN/waitframes,'uint8');
    index = 1;
%}
backRect=(backRect+[0 100 0 100])*.8    
objRect=(objRect+[0 100 0 100])*.8    
objPads(1,:) = (objPads(1,:)+[0 100 0 100])*.8

% Animationloop:
    while (frame < framesN) & ~KbCheck %#ok<AND2>

        % Display back texture
        angle = 90*mod(floor(frame/switchingFrame), 2);
        mod(floor(frame/backFrames),2)
        if (mod(floor(frame/backFrames),2))
            Screen('DrawTexture', w, backTex1, [], backRect, angle, 0);
        else
            Screen('DrawTexture', w, backTex2, [], backRect, angle, 0);
        end
        
        % Draw the gray pads over the electrodes
        for i=1:objPadN
            Screen('FIllRect', w, [gray gray gray], objPads(i,:));
        end
        
        % Disable alpha-blending, restrict following drawing to alpha channel:
        Screen('Blendfunction', w, GL_ONE, GL_ZERO, [0 0 0 1]);
        
        % Fill whole objRect with an alpha value of 127 (gray):
        Screen('FillRect', w, [0 0 0 gray], objRect);
        
        % Enable DeSTination alpha blending and reenalbe drawing to all
        % color channels. Following drawing commands will only draw there
        % the alpha value in the framebuffer is greater than zero, ie., in
        % our case, inside the circular 'dst2Rect' aperture where alpha has
        % been set to 255 by our 'FillOval' command:
        Screen('Blendfunction', w, GL_DST_ALPHA, GL_ONE_MINUS_DST_ALPHA, [1 1 1 1]);

        % Make and display obj texture
        objColor = (rand(objPixels)<.5)*2*gray*objContrast+gray*(1-objContrast);
%objColor(9,:)=0;
%objColor(18,:)=0;
%objColor(:,18)=0;
        objTex  = Screen('MakeTexture', w, objColor);
        Screen('DrawTexture', w, objTex, [], objRect, 0, 0);

        % After drawing, we can discard the noise checkTexture.
        Screen('Close', objTex);
        
        % Restore alpha blending mode for next draw iteration:
        Screen('Blendfunction', w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

        % Draw the PD box
        if (mod(frame, 60)==0)
            Screen('FillRect', w, white, pd);
        else
            Screen('FillRect', w, gray, pd);
        end
        
        % Flip 'waitframes' monitor refresh intervals after last redraw.
        vbl = Screen('Flip', w, vbl + (waitframes - 0.5) * ifi);
        frame = frame + waitframes;
%{
**************************
Comment following lines in real experiment
backSeq(:, index) = backColor > gray;
checkerSeq(:,:,index) = objColor(:,:) > gray;
index = index + 1;
%}
    end;

    Priority(0);
    ShowCursor();
    Screen('CloseAll');

    if (exist('checkerSeq'))
        ['Saving seq to memory']
        SaveBinary(checkerSeq, 'uint8');
        SaveBinary(backSeq, 'uint8');
    end
    
    if (frame >= framesN)   % if it got here without any key being pressed
        empty=[];
        CreateStimuliLog(empty, mfilename);
    end
    
catch
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.
    clear Screen
    Screen('CloseAll');
    Priority(0);
    ShowCursor();
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

function DisplayStimInPD(stim, pd, frame, framesPerCode, screen)
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
    % There are 2 photodiode boxes. pd.photodiodeBox1/2
    % Stimulus is always coded in pd.photodiodeBox1 and pd.photodiodeBox2
    % is always black. During the adapting period the actual PD will be on
    % top of pd.photodiodebox2 but during the recording they switch places
    % and the one under the PD is box1.
    %
    % Bit is   Intensity
    %   0           60
    %   1           120
    %   2           180
    %   3           240
    %   -           30      in between coding frames
    %   -           255     1st frame of code
    
    AlmostBlack = 30;       
    % Change stim into the colors needed for the pd
    pdColors = stim2pdColors(stim);    % stim = pdColor(1)*4^0 + pdColor(2)*4^1 + pdColor(2)*4^2 + pdColor(3)*4^3

    temp=mod(frame, framesPerCode);
    if (temp==1)           % display white on 1st frame
        Screen('FillRect', screen.mywindow, screen.white, pd.photodiodeBox1);
    elseif (temp==pd.frame1)    % display bit0
        Screen('FillRect', screen.mywindow, pdColors(1), pd.photodiodeBox1);
    elseif (temp==pd.frame2)   % display bit1
        Screen('FillRect', screen.mywindow, pdColors(2), pd.photodiodeBox1);
    elseif (temp==pd.frame3)   % display bit2
        Screen('FillRect', screen.mywindow, pdColors(3), pd.photodiodeBox1);
    elseif (temp==pd.frame4)   % display bit3
        Screen('FillRect', screen.mywindow, pdColors(4), pd.photodiodeBox1);
    else
        Screen('FillRect', screen.mywindow, AlmostBlack, pd.photodiodeBox1);
    end

    Screen('FillRect', screen.mywindow, AlmostBlack, pd.photodiodeBox2);
    
end

function seq = GaussianJitter(length, seed, mean, sigma, P, direction)
%   Generates and returns seq, a random distribution of jumps (jitter).
%   It has a probability P of making a jump on any
%   given frame and the distribution of the jumps follows a Gaussian
%   distribution with mean and sigma.
%   direction is the probability of making a jump in the right direction,
%   giving that we are making a jump. If direction = 1, jumps are always to
%   the right, if direction = 0 jumps are always to the left and if
%   direction = 0 jumps are equally likely.
%   Mean drift velocity in px/frame is given by: P*mean*direction
%    P = .25;        probability of jump per frame
%    sigma = 1;      std of jumps
%    mean = 3;       mean jump in pixels
%    seed = 1000;    
%    length = 1000  length in frames of jitter sequence.
%    direction =  0     : jumps are always to the left
%                 0.5   : jumps are in both directions with equal proba
%                 1     : jumps are always to the right
%                 -1    : jumps have alternating signs
%                 >1    : means alternating direction after "direction"
%                 frames
    % make a vector with 1s where the jumps are going to take place
    rand('state',seed);      %set random seed
    temp1 = rand(length,1) < P;
    
    % make a vector with 1s when jumps to the right and -1s when jumps to
    % the left, according to direction
    if (direction == -1)
        index = 0:length-1;
        temp2 = (mod(index', 2)-0.5)*2;
    elseif (direction > 1)
        index = 0:length-1;
        temp2 = (mod(floor(index'/abs(direction)), 2)-0.5)*2;
    else
        temp2 = (rand(length,1) < direction)*2-1;
    end
    
    % make a vector with jump amplitudes following the gaussian
    % distribution
    randn('state',seed);      %set random seed
    temp3 = round(randn(length,1)*sigma + mean);
    
    seq = temp1.*temp2.*temp3;
end

function k = InitScreen()

    % This script calls Psychtoolbox commands available only in OpenGL-based 
    % versions of the Psychtoolbox. The Psychtoolbox command AssertPsychOpenGL will issue
    % an error message if someone tries to execute this script on a computer without
    % an OpenGL Psychtoolbox.
    AssertOpenGL;

    % Get the list of screens and choose the one with the highest screen number.
    % Screen 0 is, by definition, the display with the menu bar. Often when 
    % two monitors are connected the one without the menu bar is used as 
    % the stimulus display.  Chosing the display with the highest dislay number is 
    % a best guess about where you want the stimulus displayed.  
    screens=Screen('Screens');
    k.screenNumber=max(screens);

    % Find the color values which correspond to white and black.  Though on OS
    % X we currently only support true color and thus, for scalar color
    % arguments, black is always 0 and white 255, this rule is not necessarily
    % true on other platforms and will not remain true after we add other color depth modes.  
    k.white=WhiteIndex(k.screenNumber);
    k.black=BlackIndex(k.screenNumber);
    k.gray=(k.white+k.black)/2;
    if round(k.gray)==k.white
        k.gray=k.black;
    end

    % Open a double buffered fullscreen window and draw a gray background
    % to front and back buffers:
    [k.mywindow k.screenBox]=Screen('OpenWindow',k.screenNumber, k.black);

    % If only one monitor hooked up hide the cursor and assign MaxPriority
    if (k.screenNumber == 0)
        HideCursor
        Priority(MaxPriority(k.mywindow));
    end
    
    % Query duration of monitor refresh interval:
    k.ifi=Screen('GetFlipInterval', k.mywindow);    
end

function flag = PromptForFlag(k)
    KbName('UnifyKeyNames');
    Screen('FillRect', k.mywindow, k.black);
    Screen(k.mywindow,'TextSize', 36);
    Screen(k.mywindow, 'DrawText', 'What do you want to do? (1-4)'...
        ,200,200, k.gray );
    Screen(k.mywindow, 'DrawText', '1: Save nothing.'...
        ,200,300, k.gray );
    Screen(k.mywindow, 'DrawText', '2: Save only log file.'...
        ,200,400, k.gray );
    Screen(k.mywindow, 'DrawText', '3: Save only random sequence.'...
        ,200,500, k.gray );
    Screen(k.mywindow, 'DrawText', '4: Save log file and random sequence.'...
        ,200,600, k.gray );
    Screen('Flip',k.mywindow);

    while 1
        flag = input('');
        pause(0.2);
        if ( flag==1 || flag==2 || flag==3|| flag==4 )
            break;
        end
    end
end

function stimuliSeq = RandomStimuli(repeatsN, stimN, seed)
% Generate a 2D array of size repeatsN x stimN.
% Each raw has numbers between 1:stimN in random order.
% Each column has elements (i-1)*phasesN+1:i*phasesN equal to 1:stimN in
% random order
%
% The algorithm works generating one square matrix (stimN, stimN) at a time
% and then cats them toghether at the end.
% As a final step I remove any rows that exceed from repeatsN

    rand('state', seed);
        
    % Decide how many square matrices to generate
    matrixN = ceil(repeatsN/stimN);

    stimuliSeq = zeros(matrixN*stimN, stimN);
    for i=1:matrixN
        tempMatrix = zeros(stimN);

        % decide the order of the 1st row
        tempRow = randperm(stimN);
        
        % decide the order of the 1st column, only restriction is that 1st
        % elements is equal to 1st element of tempMatrix (I'll take care
        % of this latter on, in the for loop).
        col1 = randperm(stimN);
        
        % populate tempMatrix by shifting tempRow until 1st element of
        % tempRow matches the corresponding 1st element in col1
        for j=1:stimN
            while (col1(j) ~= tempRow(1))
                tempRow = circshift(tempRow, [1 1]);
            end
            tempMatrix(j,:) = tempRow;
        end
        stimuliSeq(1+(i-1)*stimN:i*stimN,:) = tempMatrix;
    end
    stimuliSeq = stimuliSeq(1:repeatsN, :);
end

function SaveBinary(obj, varargin)
    nameout = [inputname(1), '.bin'];
    fid = fopen(nameout, 'w');
    fwrite(fid, obj, char(varargin{1}));
    fclose(fid);
end

function SaveMatrix(jitter, name)

    basename = [name,'_'];
    ext = '.bin';
    i=1;   
    name = [basename,num2str(i),ext];
    
    % check if file exists in current directory
    while ( exist([pwd, '/', name],'file') )
        % append a number to it.
        i = i+1;
        name = [basename,num2str(i),ext];
    end

    jitter = int8(jitter);

    % Open the file and write jitter
    fid = fopen([pwd, '/',name], 'w');
    fwrite(fid, jitter);
    fclose(fid);
end

function [structIndex, fieldNames, values] = StructList2cellList(varargin)
    % These function will convert a series of arrays/structs into
    % 3 cell arrays where each field of the original structs becomes one
    % cell identified by...
    %
    % varargin{cell2mat(structIndex(paramN))}.(char(fieldNames(paramN)))=New_Value
    %
    % The original value of that field is values{cell2mat(paramN)}
    %
    numvarargs = nargin;
    structIndex = {};
    fieldNames = {};
    values = {};
    for i=1:numvarargs
        s = varargin{i};
        if isstruct(s)
            index = cell(length(fieldnames(s)), 1);
            index(:,:) = {i};
            structIndex = [structIndex; index];
            fieldNames = [fieldNames; fieldnames(s)];
            values = [values; struct2cell(s)];
        else
            structIndex = [structIndex; {i}];
            fieldNames = [fieldNames; inputname(i)];
            values = [values; s];
        end
    end
endfunction [resp time] = TestRecStarted()
    resp=zeros(1000,1);
    tic
    for i=1:1000
        resp(i) = RecStarted();
    end
    time = toc
endfunction vbl = Wait4Button(k, varargin)
    KbName('UnifyKeyNames');
    while 1
        Screen('FillRect', k.mywindow, k.gray);
        Screen(k.mywindow,'TextSize', 24);
        if (nargin > 1)
            text = varargin{:};
            Screen(k.mywindow, 'DrawText', text ,30,60, k.black );
        end
        text = 'Press any key to start stimulus';
        
        Screen(k.mywindow, 'DrawText', text ,30,30, k.black );
        vbl = Screen('Flip',k.mywindow);

        
        if KbWait
            pause(0.2);
            break;
        end
    end
end

function vbl = Wait4Button2(mywindow, varargin)
    KbName('UnifyKeyNames');
    while 1
        Screen('FillRect', mywindow, 128);
        Screen(mywindow,'TextSize', 24);
        if (nargin > 1)
            text = varargin{:};
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

function vbl = WaitForRecComp(k, varargin)
        Screen('FillRect', k.mywindow, k.black);
        Screen(k.mywindow,'TextSize', 36);
        Screen(k.mywindow, 'DrawText', 'Waiting for rec computer',200,200, k.gray );
        if (nargin>0)
            Screen(k.mywindow, 'DrawText', ['(Record for a bit more than ',...
                num2str(varargin{1}), ' secs)'],250,300, k.gray );
        end
        
        vbl = Screen('Flip',k.mywindow);
        
        WaitForRec();
end

function prepareGroupCW(date, filesN)
    fid = fopen('~/Desktop/groupwcText.txt', 'w');
    
    for i=1:filesN
        fprintf(fid, [date,'_',num2str(i), '{0 16000000}\n']);
    end
    fprintf(fid, '\n');
    
    for i=1:filesN
        fprintf(fid, [date,'_',num2str(i), '{}\n']);
    end
    fprintf(fid, '\n');
    
    bins='';
    ssnp='';
    for i=1:filesN
        bins=[bins, date, '_', num2str(i), '.bin, '];
        ssnp=[ssnp, date, '_', num2str(i), '.ssnp, '];
    end
    
    binsSize = size(bins, 2);
    bins(binsSize-1:binsSize)='';
    ssnpSize = size(ssnp, 2);
    ssnp(ssnpSize-1:ssnpSize)='';
    
    fprintf(fid, ['groupcw(''', date, '.mat'', {''',bins, '''}, {''', ssnp, '''}, {''', ...
        date, '_1rsnp''})']);
    fclose(fid);
end
function [flag] = startAndGetFlag(k, varargin)
    KbName('UnifyKeyNames');
    if (k.screenNumber == 0)    %only one screen, probably real experiment
        while (1)
            flag = PromptForFlag(k);
            if (flag == 2 || flag == 3 || flag == 4)
                WaitForRecComp(k, varargin{1});
                break
            elseif (flag == 1)
                Wait4Button(k);
                break
            end
            Priority(MaxPriority(k.mywindow));
        end
        HideCursor;
    else                        % 2 monitors, probably debugging on my desk
        flag = 0;               % do not save the file if debugging
        Wait4Button(k);
    end
end

function [vbl] = startPD(screen, pd)
    vbl = 0;
    for frame=1:10       % k.framesN has to refer to 1 repeat
       Screen('FillRect', screen.mywindow, screen.black);
       Screen('FillRect', screen.mywindow, screen.white, pd.photodiodeBox);
       vbl = Screen('Flip', screen.mywindow, vbl + screen.FlipDelay);
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

