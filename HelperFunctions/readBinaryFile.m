function out = readBinaryFile(file)
fid = fopen(file);
    out = fread(fid);
    fclose(fid);
end