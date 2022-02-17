%% Electrolyte Conductivity Function: kappa(c_e) [1/Ohms*m]

function [kappa] = electrolyteCond(c_e, T)

% Valoen (2005) 
if c_e > 5000
    c_e = 5000;
end

c_e = c_e/1e3;
kappa = (c_e/10).*(-10.5 + 0.074*T - 6.96e-5*T^2 ...
            + 0.668.*c_e - 0.0178.*c_e*T + 2.8e-5.*c_e*T^2 ...
            + 0.494.*c_e.^2 - 8.86e-4.*(c_e.^2)*T).^2;
end