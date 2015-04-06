function segments = GetMiceDatSegments()
    %%%%%%%%%%%%%%%%%%%%%%%%%% Mice Data %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Load Hanna's recording with mice.
    % Change channels 5-8 from V to deg.
    % Limit data to regions where Drum and Chair are still and light is On.
    % Exclude regions with high eye velocity.
    
    chaninds = 1:12;

    % {
    path1 = '/Users/jadz/Documents/Notebook/Matlab/Eye tracking Mice/dataImport/20150108_H2_botheyes/20150108_H2_botheyes.smr';
    
    % Load mice data
    mice_rec = importSpike(path1, chaninds);

    % calibrate data, changing channels 5-8 from V to deg
    mice_rec = mice_rec.calibrate_data(fileparts(path1));

    % Chair and drum are still in between 500 and 680s
    % During that time, light is off between 491.4 and 557s.
    % I'm only using data with still chair and drum and light on.
    mice_rec = mice_rec.datsplit(557,123);

    % exclude regions with high speed eye movement
    [start, duration] = detect_artifact_timing(mice_rec, .06, .05, 1, '0011110000');
    segments = dat_segments(mice_rec, start, duration);

    %{
    one_segment = segments.segments{segment};
    pos = one_segment(ch).data;
    Fs = one_segment(ch).samplerate;
    t = one_segment(ch).tstart:1/Fs:one_segment(ch).tend-1/Fs;
    
    % limit both t and pos to be whithin startT and endT
    pos(t>endT) = [];
    pos(t<startT) = [];
    t(t>endT) = [];
    t(t<startT) = [];
    %}
end