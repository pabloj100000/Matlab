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
    presentationsN = uint32(movieDurationSecs/presentationLength);
            
    framesN = uint32(presentationLength*60);
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
%    p.addParamValue('pdStim', 1, @(x)x>=0 && x<256);
    p.addParamValue('debugging', 0, @(x)x>=0 && x <=1);
    p.addParamValue('barsWidth', 8, @(x)x>0);
    p.addParamValue('waitframes', 1, @(x)isnumeric(x)); 
    p.addParamValue('vbl', 0, @(x)x>0);

    

    % Call the parse method of the object to read and validate each argument in the schema:
    p.parse(varargin{:});
    
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
    
    if (isempty(pdStim))
        pdStim=1;
    end

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

        % 1. get into every Folder that is not of the form '.', '..', 
        %   'Backup*', 'Run'
        % 2. make a pseudo code file of every .m file.
        % 3. cat those at the end of fileOut
        % 4. remove .p file
        for i=3:size(dirList,1) % 1 & 2 correspond to '.' and '..'
            if (dirList(i).isdir && ...
                    isempty(findstr(dirList(i).name, 'BackUp')) && ...
                    isempty(findstr(dirList(i).name, 'test')) && ...
                    isempty(findstr(dirList(i).name, 'Run')))
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

