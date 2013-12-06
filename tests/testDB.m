function testDB()

f1=fopen('imk00001.imc','rb');%,'ieee-be');
w=1536;h=1024;
buf=fread(f1,[w,h],'uint16');
colormap(gray);
imagesc(buf');
end
