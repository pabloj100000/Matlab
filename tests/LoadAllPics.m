function Textures = LoadAllPics(debugging)
    global screen
    folder = '/Users/jadz/Documents/Notebook/Matlab/Stimuli/Images/';
    
    InitScreen(debugging);
    files = dir(folder);
    textN = 0;
    Textures = cell(1, size(files,1)-2);        % -2 because "." and ".." are always present
    for i=1:size(files,1)   % for every file
        [~, ~, ext] = fileparts(files(i).name);
        if strcmpi(ext, '.jpg')
            % load the image
            im = imread([folder,files(i).name]);
            % make a texture
            textN = textN + 1;
            Textures{textN} = Screen('MakeTexture', screen.w, im);
        end
    end
    % if there are empty elements in Textures, delete them
    if (length(Textures) > textN)
        Textures(textN+1:end) = [];
    end
end
