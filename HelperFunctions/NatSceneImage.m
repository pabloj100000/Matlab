function output = NatSceneImage(image, input_pix_per_degree, ...
    output_pix_per_degree, output_size)
    % generate an image from 'image' of the given 'output_size' that will
    % have the correct pixels per degree.
    % Original image has 'input_pix_per_degree' and the output texture has to
    % be such that one degree corresponds to output_pix_per_degree
    % If the output_size is smaller than that of image after rescaling then
    % a subpart of the image is returned (TODO add the posibility to
    % specify which part of the image is returned). 
    % If the output_size is bigger than the rescaled image, then the
    % rescaled image is mirrored (vertically and horizontally) to match the
    % desired size
        
    % rescale image from input_pix_per_degree to output_pix_per_degree
    image = imresize(image, output_pix_per_degree/input_pix_per_degree);
    
    xin = size(image,1);
    yin = size(image,2);
    
    output = ones(round(output_size));
    
    % mirror image along rows
    if output_size(1) < xin
        output = image(1:output_size(1),:);
    else
        % mirror and paste image along rows as many times as needed
        N = ceil(output_size(1)/xin);
        for i=0:N-2
            % only write 1:yin, I'll deal with y latter on
            if mod(i,2)==0
                dir = 1:1:xin;
            else
                dir = xin:-1:1;
            end
            output(i*xin+1:(i+1)*xin, 1:yin) = image(dir,:);
        end
        
        % deal with last pixels
        i = i+1;
        if mod(i,2)==0
            dir = 1:mod(output_size(1), xin);
        else
            dir = xin:-1:xin - mod(output_size(1), xin);
        end
        output((N-1)*xin+1:(N-1)*xin+length(dir), 1:yin) = image(dir,:);
    end
    
    % mirror image along cols
    if output_size(2) < yin
        output = image(:, 1:output_size(2));
    else
        % mirror and paste image along cols as many times as needed
        N = ceil(output_size(2)/yin);
        temp = output(:,1:yin);
        for i=0:N-2
            if mod(i,2)==0
                dir = 1:1:yin;
            else
                dir = yin:-1:1;
            end
            output(:, i*yin+1:(i+1)*yin) = temp(:,dir);
        end
        % {
        % deal with last pixels
        i = i+1;
        if mod(i,2)==0
            dir = 1:mod(output_size(2), yin);
        else
            dir = yin:-1:yin - mod(output_size(2), yin);
        end
        output(:, (N-1)*yin+1:(N-1)*yin+length(dir)) = output(:, dir);
        %}
    end
end
