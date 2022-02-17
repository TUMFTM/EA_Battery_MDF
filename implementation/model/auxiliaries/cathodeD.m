%% Cathode Diffusion Coefficient Function: D_s_p(SOC_p) [m^2/s]
  
function [D_s_p] = cathodeD(p, SOC_p)

%Coefficients 
       p1 =   p.kin_D_p(1);  
       p2 =   p.kin_D_p(2);  
       p3 =   p.kin_D_p(3);  
       p4 =   p.kin_D_p(4);  
       m  =   p.D_multi_p; 
       
       D_s_p = (p1*(1-SOC_p)^3 + p2*(1-SOC_p)^2 + p3*(1-SOC_p) + p4) * m;   
end
