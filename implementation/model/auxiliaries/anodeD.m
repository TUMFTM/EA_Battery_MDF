%% Anode Diffusion Coefficient Function: D_S_n(SOC_n) [m^2/s]
  
function [D_s_n] = anodeD(p, SOC_n)

%Coefficients
       p1 =   p.kin_D_n(1);
       p2 =   p.kin_D_n(2);
       p3 =   p.kin_D_n(3);
       p4 =   p.kin_D_n(4);
       m  =   p.D_multi_n;
       
       D_s_n = (p1*SOC_n^3 + p2*SOC_n^2 + p3*SOC_n + p4) * m;
end
