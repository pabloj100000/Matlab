function DumpText(fileName, fid)
    % output contents of fileName into fid
    
    fullPath = which(fileName);
    fid2 = fopen(fullPath,'r'); 

    tline = fgets(fid2);
    while ischar(tline)
        % replace every '%' by '%%' before writing it
        newLine = strrep(tline, '%', '%%');
        fprintf(fid, newLine);
%        fprintf(fid, [tline, '\n']);
        tline = fgets(fid2);
    end
    fclose(fid2);

    fprintf(fid, '\n');
    fprintf(fid, '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n');    
    fprintf(fid, '\n');
end

