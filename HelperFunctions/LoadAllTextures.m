function Textures = LoadAllTextures(images2load, textureSize)
    % generate textures
    global screen
    Add2StimLogList();
    InitScreen(0);
    
%    p=ParseInput(varargin{:});
    
%    images2load = p.Results.images2load;
%    textureSize = p.Results.textureSize;
    
    folder = '/Users/jadz/Documents/Notebook/Experiments/Simulations/Natural Images DB/RawData/cd01A/'; % my laptop's path
    if (~isdir(folder))
        folder = '/Users/baccuslab/Desktop/stimuli/Pablo/Images/'; % D239 stimulus desktop's path
    end
    

    % get the list of jpg files in folder
    files = dir([folder, '*LUM.mat']);

    Textures = cell(1, length(images2load));
    for i=1:min(length(images2load), length(files))  % for every selected file
%        [~, ~, ext] = fileparts(files(images2load(i)).name);
        % load the image
        load([folder,files(images2load(i)).name]);

        % limit image size to textureSize
        im = LUM_Image(1:textureSize(1), 1:textureSize(2));

        im = normalize(im);
        % make a texture
        Textures{i} = Screen('MakeTexture', screen.w, im);
    end
end

function LUM_Image = normalize(LUM_Image)
    v_min = min(LUM_Image(:));
    v_max = max(LUM_Image(:));
    LUM_Image = uint8((LUM_Image-v_min)*255/(v_max-v_min));
end

%{
function p =  ParseInput(varargin)
    p  = inputParser;   % Create an instance of the inputParser class.

    p.addParamValue('images2load', 1, @(x) all(isnumeric(x)));
    p.addParamValue('textureSize', 1, @(x) all(isnumeric(x) && all(size(x)==[1 2])));

    % Call the parse method of the object to read and validate each argument in the schema:
    p.parse(varargin{:});
    
end
%}