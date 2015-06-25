function Mouse_Eye_Movement(eye_diameter, varargin)
% eye_diameter is in mm and is used to convert from degrees to pixels
%
% I'll show different combinations of center and peipheries following a
% sequence of eye movements coming from a real mouse. 
% All peripheries are combined with all centers, total number of
% combinations is centersN * peripheriesN (most likely i'll have 4 center
% and 4 peripheries, 2 bits on each, 4 bits total)
% Each combination follows exactly the same eye movement sequence lasting
% in the order of 1 to 10 seconds.
% Every time a spatial stim (a combination of center and peri)
% is shown, it starts from exactly the same phase (same position in the
% screen). The only difference between two given presentations is the
% particular combination of center and periphery.
% Therefore at each point in time, only three parameters are needed to
% define exactly what is on the screen. Those parameters are: peri image,
% center image, time into the fixationl eye movement sequence.
%
% The experiment is carried in blocks, each block corresponds to one
% periphery and within each block center images are not randomized but 
% shown in order. This is so that I can consider a transition between 
% images as just another stimulus and I'll have as many transitions as
% center images and not the square of the number of central images.
% I will have a mask in between the center and the periphery (could be of
% zero size in which case is the same as no mask).
% Center can be placed anywhere (expressed in degrees or pixels? relative
% to the screen center). Periphery will be as large as possible, depending
% on the array its size might have to be limited to avoid interfiering with
% electronics)
% The 4 peripheries will be:
%   gray screen (somewhat like looking at the world through a tube)
%   checkerboard
%   and two natural scenes.
%
% There will probably be a large eye movement in the sequence, try
% to make the checkerboard such that it has strong peripheral stimulaiton
% for such an eye movement.
%
% All movements are in passive mode, meaning that the central stimulus
% does not move on the retina. What moves is the image projected onto the
% fixed central retinal patch

global screen
Add2StimLogList();
    
try
    % process Input variables
    p = ParseInput(varargin{:});

    eye_movement_file = p.Results.eye_movement_file;
    eye_movement_startT = p.Results.eye_movement_startT;
    eye_movement_length = p.Results.eye_movement_length;
    
    center_size = p.Results.center_size;
    center_center = p.Results.center_center;
    im_ids = p.Results.im_ids;
    im_path = p.Results.im_path;
    
    mask_size = p.Results.mask_size;    % this is the separation between center
                                        % and periphery
    chip_type = p.Results.chip_type;    % this is preventing illumination of
                                        % electronics in the HiDens array
    
    trials_per_block = p.Results.trials_per_block;
    blocksN = p.Results.blocksN;
    obj_contrast = p.Results.obj_contrast;
    checkers_size = p.Results.checkers_size;
    periN = 4;
    % parameters to define center images. First two images will also be
    % used to generate peripheries
    
    
    % start the stimulus
    InitScreen(0)

    movement_seq = LoadEyeMovements(eye_movement_file, ...
        eye_movement_startT, eye_movement_length);
    % plot(movement_seq(:,1), movement_seq(:,2));

    % change all units in degrees to pixels
    center_size = center_size*PIXELS_PER_DEGREE(eye_diameter);
    mask_size = mask_size * PIXELS_PER_DEGREE(eye_diameter);
    checkers_size = checkers_size * PIXELS_PER_DEGREE(eye_diameter);
    movement_seq = movement_seq * PIXELS_PER_DEGREE(eye_diameter);

    [center_rect, mask_rect, peri_rect, offset, screen.pd] = GetRectangles(...
        center_size, mask_size, center_center, chip_type);

    textures = GetTextures(checkers_size, im_ids, im_path, eye_diameter, peri_rect);

    % loop through the textures
    for block = 1:blocksN
        for peri = 1:periN
            for trial = 1:trials_per_block
                for center = 3:length(textures)
                    OneTrial(textures{peri}, textures{center}, obj_contrast, ...
                        peri_rect, center_rect, mask_rect, offset, chip_type, movement_seq);
                    
                    if KbCheck
                        break
                    end
                end
                
                if KbCheck
                    break
                end
            end
            if KbCheck
                break
            end
        end
        
        if KbCheck
            break
        end
    end
    % try to compute checker_size optimally from the eye movement sequence

    % After drawing, we have to discard the noise checkTexture.
    FinishExperiment();
        
catch exception
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.
    CleanAfterError();
    rethrow(exception)
end %try..catch..
end
%}


function p = ParseInput(varargin)
    p  = inputParser;   % Create an instance of the inputParser class.

    path1 = '/Users/jadz/Documents/Notebook/Matlab/Eye tracking Mice/Marcel De Jeu/Data/mouse2-HV.mat';
    path2 = '~/Desktop/stimuli/pablo/Marcel De Jeu/Data/mouse2-HV';
    if exist(path1, 'file')
        path = path1;
    else
        path = path2;
    end
        
    p.addParameter('eye_movement_file', ...
        path, ...
        @(x) exist(x, 'file'));
    p.addParameter('eye_movement_startT', 105, @(x) x>0);
    p.addParameter('eye_movement_length', 5, @(x) x>0);
    
    p.addParameter('center_size', 3, @(x) x>=0); % in degrees
    p.addParameter('center_center', [0 0], @(x) all(size(x)==[1 2])); % in what units?
    p.addParameter('mask_size', 5, @(x) x>=0);   % in degrees
    p.addParameter('chip_type', 'HiDens_v3', @(x) isstring(x));   % in what units?

    p.addParameter('trials_per_block', 51, @(x) x>0);   % 1st will be thrown away
    p.addParameter('blocksN', 20, @(x) x>0);   
    p.addParameter('obj_contrast', 0.1, @(x) x>=0 && x<=1);   
    p.addParameter('checkers_size', 1, @(x) x>0);  % in degrees; 

    % parameters to define center images. First two images will also be
    % used to generate peripheries
    p.addParameter('im_centers', [0 0], @(x) size(x,2)==2);   
    p.addParameter('im_ids', [2 3 4 5], @(x) all(isnumeric(x)) && all(mod(x,1)==0)); % in what units?
    p.addParameter('im_path', '/Users/jadz/Documents/Notebook/Matlab/Natural Images DB/RawData/cd01A/', ...
        @(x) exist(x, 'dir'));

    % Call the parse method of the object to read and validate each argument in the schema:
    p.parse(varargin{:});
    
end

function eye_movements = LoadEyeMovements(file, startT, length)
% Load eye movement sequence, check that monitor is set to same frame rate
% as the recording
    m = mouse(file);
    p0 = find(m.tax >= startT, 1);
    p1 = find(m.tax >= startT + length, 1);
    eye_movements = [m.hori(p0:p1)  m.vert(p0:p1)];
    % subtract the mean position.
    N = size(eye_movements,1);
    eye_movements = eye_movements - ones(N,1)*mean(eye_movements);
    exp_rate = m.rate;
    
    monitor_rate = Screen('NominalFrameRate', max(Screen('Screens')));
    
    if monitor_rate == 0;
        % do nothing, running from laptop
    elseif monitor_rate ~= exp_rate;
        msg = ['Data collected at ', num2str(exp_rate), ...
            'Hz, but monitor is set to ', num2str(monitor_rate), 'Hz.'];
        error(msg);
    end
end

function textures = GetTextures(checkers_size, im_ids, im_path, eye_diameter, peri_rect)
    % load images from im_path (associated with im_ids) and create textures
    % from them.
    % Original images are such that 46 pixels correspond to 1 degree of
    % visual angle. I'm changing the picture size such that 1 degree in the
    % images matches PIXELS_PER_DEGREE. For most eyes (3-4 mm in diameter)
    % this is a huge reduction in image size and images are no longer
    global screen
    
    textures = cell(length(im_ids)+2, 1);
    
    for i = 1:length(im_ids)
        % load the image
        file_name = [im_path, 'DSC_', sprintf('%04d', im_ids(i)), '_LUM.mat'];
        if exist(file_name, 'file')
            im = load(file_name);
            im = im.LUM_Image;
            v_min = min(im(:));
            v_max = max(im(:));
            norm = uint8((im-v_min)*255/(v_max-v_min));

            % change picture size by PIXELS_PER_DEGREE/46
            width = peri_rect(3)-peri_rect(1);
            height = peri_rect(4)-peri_rect(2);
            norm = NatSceneImage(norm, 46, PIXELS_PER_DEGREE(eye_diameter), [width, height]);
            
            % texture 0 is constant luminance and texture 1 is checkers
            textures{i+2} = Screen('MakeTexture', screen.w, norm);
            % I need to extract a rect 
        end
    end
    
    norm = ones(size(norm))*screen.gray;
    textures{1} = Screen('MakeTexture', screen.w, norm);
    
    textures{2} = GetCheckersTex(size(norm), checkers_size);
end

function [center_rect, mask_rect, peri_rect, offset, pd] = GetRectangles(...
        center_size, mask_size, center_center, chip_type)
    % get the rectanles needed in the stimulus
    % this are not the destination rectangles used in drawTexture but the
    % source ones
    global screen
    
    center_rect = SetRect(0, 0, center_size, center_size);
    mask_rect = SetRect(0, 0, center_size + 2*mask_size, center_size + 2*mask_size);
    peri_rect = GetRect(chip_type) + [-100 -100 100 100];  % make peri_rect
            % a bit bigger than chip_type such that once we move peri_rect
            % arround according to eye movements the image always stays
            % whithin array_mask
    peri_rect = peri_rect - peri_rect(1)*[1 0 1 0] - peri_rect(2)*[0 1 0 1];
    % Center both center and mask rect on peri_rect and then offset by
    % center_center
    center_rect = CenterRect(center_rect, peri_rect);
    mask_rect = CenterRect(mask_rect, peri_rect);
    center_rect = center_rect + [center_center center_center];
    mask_rect = mask_rect + [center_center center_center];
    
    % compute the offset needed to translate peri_rect (and
    % center/mask_rect) from source to dest (centered on screen)
    peri_dest = CenterRect(peri_rect, screen.rect);
    offset = peri_dest - peri_rect;
    pd = GetRect('pd');
end

function OneTrial(peri_tex, center_tex, obj_contrast, peri_rect, center_rect, mask_rect, patch_offset, chip_type, sequence)
% Jitter around peri_tex and center_tex
    global screen
    
    for frame = 1:size(sequence,1)
        im_offset = [sequence(frame,1) sequence(frame,2) sequence(frame,1) sequence(frame,2)];

        % Draw Periphery
        Screen('DrawTexture', screen.w, peri_tex, peri_rect + im_offset, peri_rect + patch_offset, 0, 0);
        
        % Fill circular 'mask_rect' region with gray
        Screen('FillRect', screen.w, screen.gray, mask_rect + patch_offset);
        
        % Draw center
        Screen('Blendfunction', screen.w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        Screen('DrawTexture', screen.w, center_tex, center_rect + im_offset, center_rect + patch_offset, 0, 0, obj_contrast);
        Screen('Blendfunction', screen.w, GL_ONE, GL_ZERO);
        
        MaskHiDensArray(chip_type);
        
        if frame==1
            Screen('FillRect', screen.w, screen.white, screen.pd);
        end
        
        Screen('Flip', screen.w);

        if KbCheck
            break
        end
    end
end

