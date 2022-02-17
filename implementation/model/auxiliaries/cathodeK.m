%% Cathode Reaction rate Function: k_p(SOC_p) [(A/m^2)*(mol^3/mol)^(1+alpha)]
  
function [k_p] = cathodeK(p, SOC_p)
   
%Coefficients 
       p1 =   p.kin_k_p(1);  
       p2 =   p.kin_k_p(2);  
       p3 =   p.kin_k_p(3);
       m  =   p.K_multi_p;
       
       k_p = (p1*(1-SOC_p)^2 + p2*(1-SOC_p) + p3) * m;       
end
