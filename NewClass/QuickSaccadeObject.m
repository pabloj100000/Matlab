function QuickSaccadeObject()
    objLums = DefaultObjLums();
    SaccadeObject('trialsPerBlock', 110, 'objLums', objLums, 'blocksN',2);
end

function objLums = DefaultObjLums()
    objLums = ones(1, 3, 3);
    for i=1:size(objLums,3)
        objLums(1, :, i) = [-1 1 -1]*3*(i-2) + 127;
    end
end
