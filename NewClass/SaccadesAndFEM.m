function SaccadesAndFEM(varargin)
    % A texture made out of a natural scene is jittered according to FEM
    % and saccades.
    % FEM + Saccades sequence is repeated continuously but presentations
    % are alternated between 0 and full contrast in the periphery to test
    % whether we see gating of infomration with a natural scene.
    % Texture is divided into objects and periphery. Many objects at
    % different centers, sizes, contrasts can be defined
    %
    % parameters:
    % image_num: images are named image#
    % obj_centers
    % obj_sizes
    % obj_contrasts
    % rwStepSize
    % saccadeSize
    % FEM_period
    % saccades_period
    % refresh_period: how often monitor changes, one step into FEM sequence
    % seed
    
global screen
try    

    p=ParseInput(varargin{:});
    Add2StimLogList;
    
    image_num = p.Results.image_num;
    obj_centers = p.Results.obj_centers;
    obj_sizes = p.Results.obj_sizes;            % in degrees
    obj_contrasts = p.Results.obj_contrasts;
    rwStepSize = p.Results.rwStepSize;          % in degrees
    saccadeSize = p.Results.saccadeSize;        % in degrees
    FEM_period = p.Results.FEM_period;
    saccades_period = p.Results.saccades_period;
    refresh_period = p.Results.refresh_period;
    repeats = p.Results.repeats;
    seed = p.Results.seed;
    species = p.Results.species;
    pd_scale = p.Results.pd_scale;
    
    InitScreen(0);
    %{
    % Open onscreen window on screen with maximum id:
    screenid=max(Screen('Screens'));
    
    % Open onscreen window: We request a 32 bit per color component
    % floating point framebuffer if it supports alpha-blendig. Otherwise
    % the system shall fall back to a 16 bit per color component
    % framebuffer:
    PsychImaging('PrepareConfiguration');
    PsychImaging('AddTask', 'General', 'FloatingPoint32BitIfPossible');
    [win, winRect] = PsychImaging('OpenWindow', screenid);
    %}
    
    % We use a normalized color range from now on. All color values are
    % specified as numbers between 0.0 and 1.0, instead of the usual 0 to
    % 255 range. This is more intuitive:
    Screen('ColorRange', screen.w, 1, 0);
    
    
    % Generate the natural scene textures.
    folder = '/Users/jadz/Documents/Notebook/Matlab/Stimuli/Images/'; % my laptop's path
    if (~isdir(folder))
        folder = '/Users/baccuslab/Desktop/stimuli/Pablo/Images/'; % D239 stimulus desktop's path
    end
    
    objectIm = imread([folder, 'image', num2str(image_num), '.jpg']);
    
    texture = Screen('MakeTexture', screen.w, objectIm);
        
    % init random seed generator
    randStream = RandStream('mcg16807', 'Seed', seed);
    
    % generate colors for contrast mask, I need a 4 row vector with obj
    % contrasts in the last row. Colors in the 1st three rows will be
    % overwritten by Screen('Drawtexture', screen.w, texture)
    fg_contrasts = ones(4, length(obj_contrasts))*0.5;
    fg_contrasts(4,:) = obj_contrasts;
    
    % change obj_sizes from degrees to pixels
    obj_sizes = obj_sizes * MICRONS_PER_DEGREE(species) * PIXELS_PER_100_MICRONS/100;
    
    % Generate rects from centers and diameters
    obj_rects = GetRects(obj_sizes, obj_centers);
%{
    % compute the number of frames in the sequence
    framesN = round(FEM_period/refresh_period);
    
    % generate the FEM sequence, a 2D gaussian seq with 0 mean and
    % rwStepSize standard deviation
    FEM_seq = round(randn(randStream, framesN, 2)*rwStepSize*MICRONS_PER_DEGREE(species)*PIXELS_PER_100_MICRONS/100);
    FEM_seq = cumsum(FEM_seq, 1);
    
    % add saccades at random times of random sizes
    frames_per_fixation = round(saccades_period/refresh_period);
    SaccadesN = length(Sacc_frames);
    Sacc_seq = zeros(framesN,2);
    Sacc_seq(Sacc_frames,:) = randi([-10,10], SaccadesN, 2)%[mod((1:Sacc_number),Sacc_rows)==1; ones(1, Sacc_number)]'

    Sacc_seq = cumsum(Sacc_seq, 1);
%    Sacc_seq = Sacc_seq * saccadeSize * MICRONS_PER_DEGREE(species) * PIXELS_PER_100_MICRONS/100;
    % }

    eye_movements = 0*FEM_seq + 5*Sacc_seq;
    %}
    pd = DefinePD;

    framesN = 100
    frames_per_fixation = round(saccades_period/refresh_period);
    Sacc_frames = 1:frames_per_fixation:framesN;
    for repeat = 0:repeats
        if mod(repeat,2)==0
            bg_contrast = 1;
        else
            bg_contrast = 0;
        end
        
        for frame=1:framesN
            if any(Sacc_frames==frame)
                % saccade taking place,
                color = 255;
            else
                color = 127;% screen.gray + pd_scale * FEM_seq(frame+1, 1);
            end
            
            
            % Fill the whole onscreen window with a neutral 50% intensity
            % background color and an alpha channel value of 'bgcontrast'.
            % This becomes the clear color. After each Screen('Flip'), the
            % backbuffer will be cleared to this neutral 50% intensity gray
            % and a default 'bgcontrast' background noise contrast level:
            Screen('FillRect', screen.w, [0.5 0.5 0.5 bg_contrast]);
            
            % Disable alpha-blending, so we can just overwrite the framebuffer
            % with our new pixels:
            Screen('Blendfunction', screen.w, GL_ONE, GL_ZERO);
            
            % Now we overdraw some regions of the onscreen windows alpha-channel
            % with our "modulation" image - a image that contains alpha values
            % which encode a different contrast 'fgcontrast'. After this drawing op,
            % the alpha-channel will contain the final "contrast modulation landscape":
            %Screen('DrawDots', screen.w, obj_centers , obj_sizes, fg_contrasts, [], 1);
            Screen('FillOval', screen.w, fg_contrasts, obj_rects);

            
            % Now we draw the noise texture and use alpha-blending of
            % the drawn noise color pixels with the destination alpha-channel,
            % thereby multiplying the incoming color values with the stored
            % alpha values -- effectively a contrast modulation. The GL_ONE
            % means that we add the final contrast modulated noise pixels to
            % the current content of the window == the neutral gray background.
            Screen('Blendfunction', screen.w, GL_DST_ALPHA, GL_ONE);

            
            
            % The extra zero at the end forcefully disables bilinear filtering. This is
            % not strictly neccessary on correctly working hardware, but an extra
            % precaution to make sure that the noise values are blitted
            % one-to-one into the offscreen 
            Screen('DrawTexture', screen.w, texture, [], [], [], 0);
            
            Screen('FillOval', screen.w, color, pd);
            
            % uncomment this line to check the coordinates of the 1st checker
            % Flip 'waitframes' monitor refresh intervals after last redraw.
            screen.vbl = Screen('Flip', screen.w, screen.vbl + refresh_period - screen.ifi/2);
            
            if (KbCheck)
                break
            end
        end
        if (KbCheck)
            break
        end
    end
    
    % We have to discard the noise checkTexture.
    Screen('Close', texture);
    FinishExperiment();

catch exception
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.
    CleanAfterError();
    rethrow(exception);
end %try..catch..end
end

function array = GetCheckers(im, checkersSize)
    [x, y] = meshgrid(1:size(im,1), 1:size(im,2));
    
    array = mod(floor(x/checkersSize) + floor(y/checkersSize),2)*255;    
end



function p =  ParseInput(varargin)
    p  = inputParser;   % Create an instance of the inputParser class.

    frameRate = Screen('NominalFrameRate', max(Screen('Screens')));
    if frameRate==0
        frameRate=100;
    end
    
    p.addParamValue('image_num', 6, @(x) isnumeric(x));
    p.addParamValue('obj_centers', [300 400 500;300,400 500], ...
        @(x) isnumeric(x) && size(x,1)==2); %first all the x coordinates, then all the y coordinates
    p.addParamValue('obj_sizes', [5 10 20], @(x) isnumeric(x));
    p.addParamValue('obj_contrasts', [.5 1 .25], @(x) isnumeric(x) && ...
        all(0<=x) && all(x<=1));
    p.addParamValue('rwStepSize', 0.1, @(x) isnumeric(x));  % in degrees
    p.addParamValue('saccadeSize', 5, @(x) isnumeric(x));  % in degrees
    p.addParamValue('max_saccadeSize', 5, @(x) isnumeric(x));  % in degrees
    p.addParamValue('FEM_period', 10, @(x) isnumeric(x));           % in seconds
    p.addParamValue('saccades_period', 0.5, @(x) isnumeric(x));     % in seconds
    p.addParamValue('refresh_period', 0.03, @(x) isnumeric(x));     % in seconds
    p.addParamValue('repeats', 1000, @(x) isnumeric(x));
    p.addParamValue('seed', 1, @(x) isnumeric(x));
    p.addParamValue('frameRate', frameRate, @(x) isnumeric(x));
    p.addParamValue('species', 'Mice', @(x) isstr(x));
    p.addParamValue('pd_scale', 1, @(x) isnumeric(x));

    % Call the parse method of the object to read and validate each argument in the schema:
    p.parse(varargin{:});
    
end

