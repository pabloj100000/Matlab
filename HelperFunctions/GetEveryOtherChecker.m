function centers = GetEveryOtherChecker(check1, check2)
    Add2StimLogList()
    checksN = ceil((check2-check1+1)^2/2);
    centers = ones(2, checksN);
    k=1;
    for i=check1:check2
        for j=check1:check2
            if mod(i+j-check1-check1,2)==0
                centers(:, k)=[i j];
                k=k+1;
            end
        end
    end
end