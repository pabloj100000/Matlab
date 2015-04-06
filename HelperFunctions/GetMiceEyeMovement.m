function [t, pos] = GetMiceEyeMovement(dat_segments, cutOffFreq, segment, ch, startT, endT, output_samplerate, plot_flag)
    % Given a dat_segments object, extract teh eye movements associated
    % with segment, ch, startT, endT.
    %
    % segment:  integer in the range 1:dat_segments.segmentsN
    % ch:       integer, probably 5-8 (1-4 are drum, chair set and feedback
    % positions)
    % startT/endT:  float, both start from 0
    % output_samplerate:   desired sample rate. Mice recordings are done at 1000Hz
    % but I probably want to do an experiment with a monitor working at
    % 60Hz or 100Hz
    %
    % if in dobut, run  "dat_segments.testGetEyeTrajectory(150, segment, ch)"
    %
    % This will show a plot of the recorded eye movements for the given
    % segment and ch. From there select startT/endT

    [t, pos] = dat_segments.getEyeTrajectory(cutOffFreq, segment, ch);
    
    % compute the amount of DownSampling requested
    Fs = dat_segments.samplerate;
    ds = Fs/output_samplerate;

    % Smooth data using a window of ds
    %pos = smooth(pos, ds);
        
    % I have to take samples out of pos starting from startP and ending and
    % endingP (taking one sample out of ds ones)
    startP = max(1,startT*Fs);
    endP = endT*Fs;
    pos = real(pos(round(startP:ds:endP)));
    t = t(round(startP:ds:endP));
    
    if plot_flag
        dat_segments.testGetEyeTrajectory(cutOffFreq, segment, ch)
        hold on
        plot(t, pos, 'k');
        hold off
    end
    
end