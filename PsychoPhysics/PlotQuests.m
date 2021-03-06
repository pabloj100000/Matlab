function PlotQuests(out, xAxis, varargin)
%   out has as many quest structs as tasks
%   each quest struct is actually an array of quests

    if size(xAxis)~=size(out)
        error 'PlotQuests needs arguments out and xAxis to have the same size'
    end
    
    Qmean = zeros(size(out));
    Qsd = zeros(size(out));
    for i=1:size(out,1)
        Qmean(i, :) = QuestMean(out(i,:));
        Qsd(i, :) = QuestSd(out(i,:));
    end
    
    x=ones(1,size(out,1))'*[0 1];
    axes('FontSize', 20)
%    axes( 'XLim', [0 .3]);
    
    errorbar(x', Qmean', Qsd', 'LineWidth',2, varargin{:})

    legend('Control', 'Saccading');
    title(inputname(1));
    xlabel('Time (s)');
    ylabel('log(threshold)');
    
    
    drawnow;
end
