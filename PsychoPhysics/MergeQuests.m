function q = MergeQuests(varargin)
    % Merge the different trials and recompute the psychometric funciton by
    % calling QuestRecompute
    inputN = length(varargin);
    questN = size(varargin{1}, 2);

    q = varargin{1};
    for i=2:inputN
        length1 = length(q(1).intensity);
        length2 = length(varargin{i}(1).intensity);
        for j=1:questN
            q(j).intensity(length1+1:length1+length2) = varargin{i}(j).intensity;
            q(j).response(length1+1:length1+length2) = varargin{i}(j).response;
        end
    end
    
%{
    figure(2)
    subplot(2,2,1)
    plot(q(1).x, q(1).pdf)
    subplot(2,2,2)
    plot(q(1).x2, q(1).p2)
   %} 
    q = QuestRecompute(q);
%{    
    subplot(2,2,3)
    plot(q(1).x, q(1).pdf)
    subplot(2,2,4)
    plot(q(1).x2, q(1).p2)
  %}  

end