function MovingBar(species_or_size, varargin)
    % This stimulus presents a set of bars that move at a constant speed on
    % top of some random checkers. The whole scene jitters back and forth
    % according to some eye movements.
    % after some time (~10s), the whole scene (bars + checkers + eye 
    % sequence) are reset to the original position and a new trial starts.
    % The experiment will be presented in blocks. Each block has two
    % parameters, the width and contrast of the bars. Other than that all
    % trails are identical
    %
    % To change a parameter from its default value just type
    % MovingBar('paramToChange', newValue, ...)
    p=ParseInput(varargin{:});

    bars_contrasts = p.Results.bar_contrasts;
    bars_widths_deg = p.Results.bar_widths_deg;
    bars_height_deg = p.Results.bars_height_deg;
    bars_spacing_secs = p.Results.bars_spacing_secs;
    bars_speed_deg_per_sec = p.Results.bars_speed_deg_per_sec;
    object_type = p.Results.object_type;
    seed = p.Results.seed;
    eye_movement_file = p.Results.eye_movement_file;
    jitter_start = p.Results.jitter_start;
    jitter_length = p.Results.jitter_length;
    stimSize = p.Results.stimSize;
    checkerSizeX = p.Results.checkerSizeX;
    checkerSizeY = p.Results.checkerSizeY;
    repeats_per_block = p.Results.repeats_per_block;
    blocks_nb = p.Results.blocks_nb;
    array_type = p.Results.array_type;    % this is preventing illumination of
    
 
try
    screen = InitScreen(0, 800, 600, 60);

    Add2StimLogList();

    checkersN_H = ceil(stimSize(1)/checkerSizeX);
    checkersN_V = ceil(stimSize(2)/checkerSizeY);
    
    % Make array with pink checkers
    y = PinkNoise2D_FFT([checkersN_H, checkersN_V], 'seed', seed);
    y = 255 * (y-min(y(:)))/(max(y(:))-min(y(:)));
    checkers_tex = Screen('MakeTexture', screen.w, y);

    
    % Define the obj Destination Rectangle
    checkersRect = SetRect(0,0, checkersN_H*checkerSizeX, checkersN_V*checkerSizeY);
    checkersRect = CenterRect(checkersRect, screen.rect);
    
    % Define the eye movement sequence
    eye_movements = LoadEyeMovements(eye_movement_file, jitter_start, jitter_length);


    % Define the bars
    % Bars are moving at bars_speed_deg_per_sec (in degrees per seconds)
    % First change bars_speed from degrees per second to pixels per second.
    % Since monitor refreshes at 120Hz, the step per frame is
    % bars_speed_pix_per_sec/120
    % Bars are defined as a concatenation of a basic unit. The basic unit
    % have all the same length 'bars_spacing_pix' and have a bar such that
    % the leading edge of the bar is always at the same place (the maximum
    % bar width counting from the left)
    % Number of basic units is ceil(texture_length/bars_spacing_pix)
    %
    % Then bars should be separated by bars_speed_pix_per_sec * bars_spacing_secs
    bars_speed_pix_per_sec = bars_speed_deg_per_sec * PIXELS_PER_DEGREE(species_or_size);
    bars_step_per_frame = bars_speed_pix_per_sec/screen.rate;
    bars_spacing_pix = round(bars_speed_pix_per_sec * bars_spacing_secs);
    bars_widths_pix = round(bars_widths_deg * PIXELS_PER_DEGREE(species_or_size));
    basic_unit_nb = ceil(size(eye_movements,1)*bars_step_per_frame/bars_spacing_pix);
    texture_length = basic_unit_nb * bars_spacing_pix;
    bars = ones(1, texture_length,2)*255;     % (pixels, 1 pix height, LA)
    bars_textures = zeros(size(bars_widths_pix,2),1);
    max_bar_width = max(bars_widths_pix);
    
    for i = 1:size(bars_widths_pix,2)
        width = bars_widths_pix(i);
        basic_unit = zeros(1, bars_spacing_pix);
        basic_unit(max_bar_width - width + 1:max_bar_width) = 255;
%        bars(1,:, 2) = (mod(0:texture_length-1, bars_spacing_pix) < bars_width_pix)*255;
        bars(1,:, 2) = repmat(basic_unit, 1, basic_unit_nb);
        %(mod(texture_length-1:-1:0, bars_spacing_pix) < bars_width_pix)*255;
        bars_textures(i) = Screen('MakeTexture', screen.w, bars);
    end

    bars_source_rect = SetRect(0,0,size(bars,2),bars_height_deg*PIXELS_PER_DEGREE(species_or_size));
    bars_dest_rect = CenterRect(bars_source_rect, screen.rect);
    bars_dest_rect = OffsetRect(bars_dest_rect, -size(bars,2)/2,0);
    pd = DefinePD();

    % Define the center gray stripe, always used when object_type=2
    gray_box = SetRect(0,0,checkersRect(3),bars_height_deg*PIXELS_PER_DEGREE(species_or_size));
    gray_box = CenterRect(gray_box, screen.rect);
    
    Screen('FillRect', screen.w, screen.gray);
    vbls(1) = Screen('Flip', screen.w);
   
    for b = 1:blocks_nb
        for c = bars_contrasts
            for t = bars_textures'
                for r = 1:repeats_per_block
                    for frame = 1:size(eye_movements,1)
                        jitter = [eye_movements(frame,:) eye_movements(frame,:)];
                        Screen('DrawTexture', screen.w, checkers_tex, [], checkersRect+jitter, 0, 0);
                        edge_position = [1 0 1 0]*bars_step_per_frame*frame;
                        
                        if object_type==1
                            % draw a gray rectangle where the object will
                            % be to cover the checkers
                            Screen('FillRect', screen.w, screen.gray, bars_dest_rect + jitter + edge_position);
                        elseif object_type==2
                            Screen('FillRect', screen.w, screen.gray, gray_box);
                        end
                        
                        % Enable alpha blending
                        Screen('Blendfunction', screen.w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);%, [1 1 1 1]);
                        Screen('DrawTexture', screen.w, t, [], bars_dest_rect + jitter + edge_position, 0, 0, [], c*255);
                        % Restore alpha blending mode for next draw iteration:
                        Screen('Blendfunction', screen.w, GL_ONE, GL_ZERO, [1 1 1 1]);
                        
                        MaskHiDensArray(screen, array_type)

                        if frame==1
                            Screen('FillOval', screen.w, 255, pd);
                        end
                        screen.vbl = Screen('Flip', screen.w, screen.vbl + .5 * screen.ifi);
                        
                        if (KbCheck)
                            break
                        end
                    end
                    if (KbCheck)
                        break
                    end
                end
                if (KbCheck)
                    break
                end
            end
            if (KbCheck)
                break
            end
        end
        if (KbCheck)
            break
        end
    end
    % Define some needed variables
    
    vbls(2)=screen.vbl;

    start_t = clock;


    Screen('CloseAll');
    Priority(0);
    ShowCursor();

    %add_experiments_to_db(start_t, vbls, varargin)
        
catch exception
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.
    CleanAfterError();
    rethrow(exception);
end %try..catch..
end


function eye_movements = LoadEyeMovements(file, startT, length)
% Load eye movement sequence, check that monitor is set to same frame rate
% as the recording
    m = mouse(file);
    p0 = find(m.tax >= startT, 1);
    p1 = find(m.tax >= startT + length, 1);

    monitor_rate = Screen('NominalFrameRate', max(Screen('Screens')));
    if monitor_rate==120
        slice = p0:p1-1;
    elseif monitor_rate==60
        slice = p0:2:p1-1;
    else
        slice = p0:p1-1;
    end
    
    eye_movements = [m.hori(slice)  m.vert(slice)];
    % subtract the mean position.
    N = size(eye_movements,1);
    eye_movements = eye_movements - ones(N,1)*mean(eye_movements);
    exp_rate = m.rate;
    
    
    if monitor_rate == 0;
        % do nothing, running from laptop
    elseif monitor_rate ~= exp_rate;
%        msg = ['Data collected at ', num2str(exp_rate), ...
%            'Hz, but monitor is set to ', num2str(monitor_rate), 'Hz.'];
%        error(msg);
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

    path1 = '/Users/jadz/Documents/Notebook/Matlab/Eye tracking Mice/Marcel De Jeu/Data/mouse2-HV.mat';
    path2 = '/Users/baccuslab/Desktop/stimuli/Pablo/Matlab/Mouse-eye-movements/Marcel De Jeu/Data/mouse2-HV.mat';
    if exist(path1, 'file')
        path = path1;
    else
        path = path2;
    end
        
    p.addParamValue('eye_movement_file', ...
        path, ...
        @(x) exist(x, 'file'));
    
    p.addParamValue('bar_contrasts', [0, .1 .2 .4], @(x) all(x)>=0 && all(x)<=1 && size(x,1)==1);
    p.addParamValue('bar_widths_deg', [.5 1 2 4], @(x) isnumeric(x) && size(x,1)==1);   % in degrees
    p.addParamValue('bars_spacing_secs', 1, @(x) x>0);        % in seconds, how often should a leading edge of a bar pass through a given point
    p.addParamValue('bars_speed_deg_per_sec', 10, @(x) x>0);          % in degrees per second
    p.addParamValue('bars_height_deg', 10, @(x) x>0);      % in degrees
    p.addParamValue('object_type', 1, @(x) x==0 || x==1 || x==2);    % 0:    transparent object
                                                                    % 1: gray background that moves with bars
                                                                    % 2: gray long sripe that is always present and doesn't move
                                                                    
    p.addParamValue('seed', 1, @(x) isnumeric(x));
    p.addParamValue('jitter_length', 5, @(x)x>0);
    p.addParamValue('stimSize', 32*PIXELS_PER_100_MICRONS*[1 1], @(x) all(size(x)==[1 2]) && all(x>0));
    p.addParamValue('debugging', 0, @(x)x>=0 && x <=1);
    p.addParamValue('checkerSizeX', PIXELS_PER_100_MICRONS, @(x) x>0);
    p.addParamValue('checkerSizeY', PIXELS_PER_100_MICRONS, @(x) x>0);
    p.addParamValue('jitter_start', 5, @(x) isnumeric(x) && x >= 0);
    p.addParamValue('repeats_per_block', 55, @(x) isnumeric(x) && x > 0);
    p.addParamValue('blocks_nb', 2, @(x) isnumeric(x) && x > 0);
    p.addParamValue('array_type', 'HiDens_v3', @(x) ischar(x));   % in what units?
    
    % Call the parse method of the object to read and validate each argument in the schema:
    p.parse(varargin{:});
    
end

