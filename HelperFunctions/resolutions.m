function resolutions(desired_hz)
    res = Screen('Resolutions',1);
    for i = 1:length(res)
        if res(i).hz==desired_hz
            [res(i).width,res(i).height]
        end
    end
end