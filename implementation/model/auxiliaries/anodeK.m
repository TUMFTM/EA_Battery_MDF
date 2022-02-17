%% Anode Reaction rate Function: k_n(SOC_n) [(A/m^2)*(mol^3/mol)^(1+alpha)] 

function [k_n] = anodeK(p, SOC_n)

%Coefficients 
       p1 =   p.kin_k_n(1);  
       p2 =   p.kin_k_n(2);  
       p3 =   p.kin_k_n(3);  
       m  =   p.K_multi_n;
       
       k_n = (p1*SOC_n^2 + p2*SOC_n + p3) * m;          
end
