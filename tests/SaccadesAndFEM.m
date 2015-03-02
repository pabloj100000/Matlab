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
    % obj_contrast
    % rwStepSize
    % saccadeSize
    % seconds_per_fixation
    % fixations_per_trial
    % refresh_period: how often monitor changes, one step into FEM sequence
    % seed
    
global screen
try    

    p=ParseInput(varargin{:});
    Add2StimLogList;
    
    image_num = p.Results.image_num;
    obj_centers = p.Results.obj_centers;
    obj_sizes = p.Results.obj_sizes;            % in degrees
    obj_contrast = p.Results.obj_contrast;
    peri_contrast = p.Results.peri_contrast;
    rwStepSize = p.Results.rwStepSize;          % in degrees
    checkers_size = p.Results.checkers_size;      % in degrees
    peri_mode = p.Results.peri_mode;            % string: either 'checkers' or 'nat_scene'
    seconds_per_fixation = p.Results.seconds_per_fixation;
    fixations_per_trial = p.Results.fixations_per_trial;
    refresh_period = p.Results.refresh_period;
    repeats = p.Results.repeats;
    seed = p.Results.seed;
    species = p.Results.species;
    pd_scale = p.Results.pd_scale;
    
    
    % convert all units from degrees to pixels
    obj_sizes = round(obj_sizes * PIXELS_PER_DEGREE(species));
    rwStepSize = rwStepSize * PIXELS_PER_DEGREE(species);
    checkers_size = round(checkers_size * PIXELS_PER_DEGREE(species));
    
    InitScreen(0);
    
    % We use a normalized color range from now on. All color values are
    % specified as numbers between 0.0 and 1.0, instead of the usual 0 to
    % 255 range. This is more intuitive:
    Screen('ColorRange', screen.w, 1, 0);
        
    % Generate the natural scene textures.
    folder = '/Users/jadz/Documents/Notebook/Matlab/Natural Images DB/RawData/cd25A/'; % my laptop's path
    if (~isdir(folder))
        folder = '/Users/baccuslab/Desktop/stimuli/Pablo/Images/'; % D239 stimulus desktop's path
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Make front and periphery textures.
    % If peri_mode is 'nat_scene' then both are the same image, with the
    % same mean but different contrasts.
    peripheryIm = load([folder, 'DSC_000', num2str(image_num), '_LUM.mat']);
    peripheryIm = peripheryIm.LUM_Image;
    % Tkacik db has images that are 45 pixels per degree of visual angle. I
    % need to convert those images to PIXELS_PER_DEGREE. Resize such that
    % new image dimension = old image dimenstion * PIXELS_PER_DEGREE/45
    peripheryIm = imresize(peripheryIm', PIXELS_PER_DEGREE(species)/45);
    im_size = size(peripheryIm);
    
    % change the mean to be gray and the contrast to be peri_contrast
    % (saturating image at 0 and 255)
    objectIm = peripheryIm * obj_contrast;
    peripheryIm = (peripheryIm - mean(peripheryIm(:)))*peri_contrast + screen.gray;
    peripheryIm(peripheryIm<0) = 0;
    peripheryIm(peripheryIm>255) = 255;
    image_mean = mean(peripheryIm(:));
    objectIm = objectIm - mean(objectIm(:)) + image_mean;
    peripheryIm = uint8(peripheryIm);
    objectIm = uint8(objectIm);
    %[mean(objectIm(:)) mean(peripheryIm(:)) image_mean]

    obj_tex = Screen('MakeTexture', screen.w, objectIm');
    if strcmp(peri_mode, 'nat_scene')
        peri_tex = Screen('MakeTexture', screen.w, peripheryIm');
    else
        % Generate checkers texture, make it the same size as the natural scene
        % and convert checkers_size from degrees to pixels
        peri_tex = GetCheckersTex(im_size, checkers_size);
        peri_tex = peri_tex{1};
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%        
    % Generate rects for low contrast patches from centers and diameters
    obj_rects = GetRects(obj_sizes, obj_centers);

    % Generate rects to crop image from and to place it on screen.
    % Source and dest rects are the size of the image unless the
    % image is larger than the screen's height
    rect_size = min(screen.size, im_size);
    source_rect = SetRect(0,0, rect_size(1), rect_size(2));
%    source_rect = CenterRectOnPoint(source_rect, im_size(1)/2, im_size(2)/2);
    dest_rect = CenterRectOnPoint(source_rect, screen.center(1), screen.center(2));    
        
    % init random seed generator
    randStream = RandStream('mcg16807', 'Seed', seed);

    % compute the number of frames in a fixation
    frames_per_fixation = round(seconds_per_fixation/refresh_period);

    % generate the FEM sequence, a 2D gaussian seq with 0 mean and
    % rwStepSize standard deviation
    FEM_seq = round(randn(randStream, frames_per_fixation, 2)*rwStepSize);
    % change FEM_seq somwhere along half way through to make sure it ends
    % at the beginning
    FEM_seq(round(end/2),:) = FEM_seq(round(end/2),:) - sum(FEM_seq);
    
    % define a drift sequence that will change phase of grating completely
    drift_seq = zeros(frames_per_fixation, 2);
    drift_seq(:,1) = checkers_size/(frames_per_fixation-1);
    
    pd = DefinePD;
    first_offset = [0 0 0 0];
    
    for repeat = 0:repeats
        if mod(repeat,2)==0% || strcmp(peri_mode, 'nat_scene')
            % during nat_scene always update periphery
            update_peri = 1;
        else
            % Here only in even repeats with checkers
            update_peri = 0;
        end

        
        for fixation = 1:fixations_per_trial

            % each fixation changes the object. I do this by shifting the
            % dest rectangle relative to the fixed ovals controling alpha
            % masking
            obj_offset = (fixation - fixations_per_trial/2) * obj_sizes(1)...
                * [1 0 1 0];
            for frame=1:frames_per_fixation
                if frame==1
                    % saccade taking place,
                    color = 255;
                else
                    color = screen.gray + pd_scale * FEM_seq(frame, 1);
                end
                                
                if update_peri && frame==1
                    % force last frame of fixation + drift to be completely
                    % out of phase with frame = 1, when turning off FEM_seq
                    % new_offset for frame=1 is [1 0] already. Last frame
                    % has to be [1 0] + checkers_size*[1 0]. I'm also
                    % making offset 4x1 to be added to rect properly
                    offset = first_offset;%checkers_size*[1 0 1 0] + [1 0 1 0];
                end
                
                % Get a gray screen everywhere
                Screen('FillRect', screen.w, screen.gray);
                
                % Disable alpha-blending, so we can just overwrite the framebuffer
                % with our new pixels:
                Screen('Blendfunction', screen.w, GL_ONE, GL_ZERO, [1 1 1 1]);
                
                % Draw peripheral texture everywhere
                % The extra zero at the end forcefully disables bilinear filtering. This is
                % not strictly neccessary on correctly working hardware, but an extra
                % precaution to make sure that the noise values are blitted
                % one-to-one into the offscreen
                Screen('DrawTexture', screen.w, peri_tex, source_rect + offset, dest_rect, [], 0);

                % Now change 'colorMaskNew' such that the following commands
                % will only write to the alpha channel. Only source values of
                % alpha are taken into account and destination ones are ignored
                Screen('Blendfunction', screen.w, GL_ONE, GL_ZERO, [0 0 0 1]);
                
                % Now we fill the screen with alpha value of 0 (transparent)
                % everywhere (only writing to alpha channel)
                Screen('FillRect', screen.w, [0 0 0 0]);
                
                % Now make opaque the object regions
                Screen('FillOval', screen.w, [0 0 0 1], obj_rects);
                
                % Now change 'colorMaskNew' to modify RGB values on subsequent
                % commands. I'm overwriting destination pixels with source ones
                Screen('Blendfunction', screen.w, GL_DST_ALPHA, GL_ONE_MINUS_DST_ALPHA, [1 1 1 1]);
                
                % Now we draw the object texture which is only writing through
                % the oval holes we made 2 lines above
                Screen('DrawTexture', screen.w, obj_tex, source_rect + offset, dest_rect + obj_offset, [], 0);
                
                % Draw the photodiode
                Screen('FillOval', screen.w, color, pd);
                
                % uncomment this line to check the coordinates of the 1st checker
                % Flip 'waitframes' monitor refresh intervals after last redraw.
                screen.vbl = Screen('Flip', screen.w, screen.vbl + refresh_period - screen.ifi/2);
                
                if update_peri && frame < frames_per_fixation
                    new_offset = FEM_seq(frame, :) + drift_seq(frame, :);
                    offset = offset + [new_offset new_offset];
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
    
    % We have to discard the noise checkTexture.
    Screen('Close', obj_tex);
    Screen('Close', peri_tex);
    FinishExperiment();

catch exception
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.
    CleanAfterError();
    rethrow(exception);
end %try..catch..end
end


function p =  ParseInput(varargin)
    p  = inputParser;   % Create an instance of the inputParser class.

    frameRate = Screen('NominalFrameRate', max(Screen('Screens')));
    if frameRate==0
        frameRate=100;
    end
    
    p.addParamValue('image_num', 8, @(x) isnumeric(x));
    p.addParamValue('obj_centers', [300 400 500;300 300 300], ...
        @(x) isnumeric(x) && size(x,1)==2); %first all the x coordinates, then all the y coordinates
    p.addParamValue('obj_sizes', [1 2 5], @(x) isnumeric(x));
    p.addParamValue('obj_contrast', .3, @(x) 0<=x && x<=1);
    p.addParamValue('peri_contrast', 16, @(x) 0<=x && isnumeric(x));
    p.addParamValue('rwStepSize', 0.01, @(x) isnumeric(x));  % in degrees
    p.addParamValue('saccadeSize', 5, @(x) isnumeric(x));  % in degrees
    p.addParamValue('checkers_size', .2, @(x) isnumeric(x));  % in degrees
    p.addParamValue('peri_mode', 'nat_scene', @(x) ...
        any(strcmp(x, {'checkers', 'nat_scene'}))); % string: either 'checkers' or 'nat_scene'
    p.addParamValue('max_saccadeSize', 5, @(x) isnumeric(x));  % in degrees
    p.addParamValue('seconds_per_fixation', 0.5, @(x) isnumeric(x));           % in seconds
    p.addParamValue('fixations_per_trial', 10, @(x) isnumeric(x));     % in seconds
    p.addParamValue('refresh_period', 0.03, @(x) isnumeric(x));     % in seconds
    p.addParamValue('repeats', 1000, @(x) isnumeric(x));
    p.addParamValue('seed', 1, @(x) isnumeric(x));
    p.addParamValue('frameRate', frameRate, @(x) isnumeric(x));
    p.addParamValue('species', 'test', @(x) ischar(x));
    p.addParamValue('pd_scale', 1, @(x) isnumeric(x));

    % Call the parse method of the object to read and validate each argument in the schema:
    p.parse(varargin{:});
    
end

