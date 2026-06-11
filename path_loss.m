function PL = path_loss(d,f_c)
l = physconst('LightSpeed') / f_c;
PL = 4*pi*d/l;
end