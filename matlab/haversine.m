function [distance] = haversine( lon1, lat1, lon2, lat2)
% this function gives the distance between two points on earth, based on
% their latitude and longtitude coordinates

R = 6371;
dLat=deg2rad(lat2 - lat1);
dLon=deg2rad(lon2 - lon1);

temp0=sin(dLat/2) * sin(dLat/2) + cos(deg2rad(lat2))...
                *cos(deg2rad(lat1)) * sin(dLon/2) * sin(dLon/2);
temp1=2 * atan2(sqrt(temp0), sqrt(1-temp0));
distance=R*temp1; 

end