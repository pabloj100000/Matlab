objSize = 20;
[x, y] = meshgrid(0:objSize, 0:objSize);
dist = sqrt((x-objSize/2).^2+(y-objSize/2).^2);
gauss = normpdf(dist, 0, 1);
gauss = gauss/max(max(gauss));

    