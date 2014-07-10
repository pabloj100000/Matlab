function seed = ShowGaussianNatScene(varargin)
% Show a gaussianized version of a natural scene undergoing saccades and
% FEMs.
% I start by gaussianizing an image. FEM are simulated by letting the
% checkers fluctuate according to the gaussian streams (vertical and
% horizontal) and fixing a global contrast (global contrast modulates
% the checkers independent contrast, the one that depends on the particular
% scene and whether the checker is close to an edge).
% Saccades are produce by shifting the image around.
% In this particular version I'm going to have N+1 fixational spots. One
% of them I'm going to call 'home' and it will play a different role from
% all other 'N' ('targets') fixational spots. The idea is the following:
% 1. randomly sort the targets fixational spots.
% 2. interleave home with targets such that every even fixationl spot is
% 'home', every odd fixational spot is a target.
% 3. In this way I have two different types of fixations: Going from the
% same fixation to different ones (What is the role of the new target)
% and going from different targets to the same home (What is the
% role of the history?)
%
% Possible changes:
% *) In the future I might have more than 1 'home' but doing all against all
% takes too much time.
% *) I think I do not want to repeat the random sequence but I'm going to
% include the possibility 
% *) In principle the 'N' fixational spots can be at 360/N degrees and teh
% same radial distance, but they could also be randomly picked or passed as
% parameters.
global screen
try
    Add2StimLogList();
    
    % process Input variables
    p = ParseInput(varargin{:});
    contrast = p.Results.contrast;
    originalSeed = p.Results.seed;
    cellSize = p.Results.cellSize;
    imageID = p.Results.image;
    targets = p.Results.targets;
    home = p.Results.home;
    trialsN = p.Results.trialsN;
    presentationLength = p.Results.presentationLength;
    resetSeed = p.Results.resetSeed;
    
    InitScreen(0);
    
    % seed is passed to ShowCorrelatedGaussianCheckers which overwrites
    % seed when done. If resetSeed is set, I need to have access to the
    % originalSeed.
    seed = originalSeed;
    
    Screen('FillRect', screen.w, 127);
    DrawMultiLineComment(screen, {'Pre processing images', '    Wait a bit and stim will start'});
    screen.vbl = Screen('Flip', screen.w);
        
    % load one image
    image = loadimage(imageID);
    
    [cellsMean, gradientUp, gradientLeft] = ...
        GaussianizeImage(image, cellSize, cellSize, contrast);
    
    % initial home refers to pixels in the full image. GaussianizeImage has
    % shrinked the number of pixels.
    % now home should be changed so that it still points to the same place
    % in the new images (cellsMean, gradientUp, gradientLeft)
    home = round(home/cellSize);

    % targets has distances in pixels, I have to change it to checkers
    targets(:,2) = targets(:,2)/cellSize;
    
    halfScreen = floor(screen.rect(4)/cellSize/2);

    framesPerSec = round(screen.rate/screen.waitframes);
    framesN = presentationLength*framesPerSec;

    targetsN = size(targets,1);
    RS = RandStream('mcg16807', 'Seed', 1);

    for trial=1:trialsN
        % randomize targets order
        targetsOrder = randperm(RS, targetsN);

        % show each image for a rather long time, useful for computing
        % models early/late and comparing them
        for i=0:2*targetsN - 1
            if mod(i, 2)
                theta = targets(targetsOrder(floor(i/2)+1),1);
                rho = targets(targetsOrder(floor(i/2)+1),2);
                [X,Y] = pol2cart(theta, rho);
                fixation = round([X Y] + home);
            else
                fixation = home;
            end
            
            rows = fixation(1)-halfScreen:fixation(1)+halfScreen;
            cols = fixation(2)-halfScreen:fixation(2)+halfScreen;
            
            if resetSeed
                seed = originalSeed;
            end

            seed = ShowCorrelatedGaussianCheckers(framesN, cellSize, ...
                cellsMean(rows, cols), gradientUp(rows,cols),...
                gradientLeft(rows, cols), ...
                contrast, seed);

            if (KbCheck)
                break
            end
        end

        if (KbCheck)
            break
        end
    end
    
    FinishExperiment();
    
catch exception
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.
    CleanAfterError();
    rethrow(exception)
end %try..catch..

end

function p = ParseInput(varargin)
    p  = inputParser;   % Create an instance of the inputParser class.
   
    targets = [0:2*pi/8:2*pi-pi/16; ones(1,8)*PIXELS_PER_100_MICRONS*3]';
    p.addParamValue('contrast', 1, @(x) x>=0 && x<=1);
    p.addParamValue('seed', 1, @(x) isnumeric(x));
    p.addParamValue('cellSize', PIXELS_PER_100_MICRONS/2, @(x) x>0 );
    p.addParamValue('image', 2, @(x) isnumeric(x) && x >= 1);
    p.addParamValue('trialsN', 10, @(x) x>=0);
    p.addParamValue('path', '', @(x) ischar(x));
    p.addParamValue('home', [500 700], @(x) all(isnumeric(x)) && ...
        all(x>0) && size(x, 1)==1 && size(x,2)==2);
    p.addParamValue('presentationLength', 1, @(x) isnumeric(x) && x>=0);
    p.addParamValue('resetSeed', 0, @(x) x==0 || x==1);
    p.addParamValue('targets', targets, @(x) all(isnumeric(x)) && ...
        all(x(:,2)>=0) && size(x,2)==2);
    
    % Call the parse method of the object to read and validate each argument in the schema:
    p.parse(varargin{:});
    
end

%{
function imageRect = GetImageSize(targets, home)
    % I will center the image on each target and home and display a squared
    % image of size screen.rect(4)
    % Here I will compute the rectangle out of the original image that
    % needs to be kept
    % The size of the displayed want the smallest possible image that when centered on each
    % target and homecentered on home and each target that spans teh whole
    % monitor. Figure out the size of the total image such that when
    % centering it on the different targets and home it still covers the
    % whole monitor.
    % targets are polar coordinates from home.
    % home is in cartesian coordinates.
    global screen
    
    theta = targets(:,1);
    rho = targets(:,2);
    [X,Y] = pol2cart(theta, rho);
    
    imageRect = [-1 -1 1 1]*screen.rect(4)/2 + [min(Y) min(X) max(Y) max(X)] +...
        [home home];

end
%}

function image = loadimage(imageID)

    if strcmp(computer, 'MACI64')
        % probably in my laptop
        s_path = '/Users/jadz/Documents/Notebook/Matlab/Natural Images DB/RawData/cd01A';
    else
        % probably in the stimulating computer
        s_path = '~/Desktop/stimuli/Pablo/Matlab/Natural Images DB/';
    end
    
    % get all the images in s_path of the form *LUM.mat
    imList = dir([s_path,'/*LUM.mat']);
    
    if length(imList)<imageID
        error('imageID does not exist in the given path');
    end
    
    % Load image from DB
    struct = load([s_path, '/',imList(imageID).name]);
    image = struct.LUM_Image;
    image = image*2^8/max(image(:));
end

