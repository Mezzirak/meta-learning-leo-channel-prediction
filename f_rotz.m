function R_z = f_rotz(theta)

R_z = [ cosd(theta), sind(theta), 0 ;
       -sind(theta), cosd(theta), 0 ;
        0         , 0         , 1];

