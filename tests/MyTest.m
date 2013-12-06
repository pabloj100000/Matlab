alpha = 2*pi/1000
rfx = 2*cos(alpha)
rfy = sin(alpha)
	
alpha2=atan(rfy/rfx)
	
rfx2 = 2*cos(alpha2)
rfy2 = sin(alpha2)
	
[rfx rfx2 rfx-rfx2]
[rfy rfy2 rfy-rfy2]