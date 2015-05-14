function mic_per_degree = MICRONS_PER_DEGREE(species_or_size)
    % I am converting from Macaque to other species with a geometric
    % argument based on the eye's diameter. 
    %
    % Macaque diameter = 18mm, 200um per degree
    % Salamander diameter = 4mm, -> 200*4/18 um per degree = 44um per degree? Bipolar cell size -> 90um? -> 2 degrees?
    % Mice diameter = 3mm => 200*3/18 um per degree
    
    Add2StimLogList;
    if isstr(species_or_size)
        switch species
            case 'Human'
                diameter = 24; % in mm
            case 'Macaque'
                diameter = 18; % in mm
            case 'Salamander'
                diameter = 4;
            case 'Mice'
                diameter = 3.3; % from Geng et al. 2011
            case 'test'
                diameter = 10;
            otherwise
                error(['"',species, '" is not a recognized species in function MICRONS_PER_DEGREE. ', ...
                    'Use either Human, Macaque, Salamander, Mice'])
        end
    else
        diameter = species_or_size; % in mm
    end
    % Everything is computed relative to Macaque data
    mic_per_degree = 200*diameter/18;