%% Electrolyte Diffusion Coefficient Function: D_e(c_e,T) [m^2/s]

function [D_e,varargout] = electrolyteDe(c_e,T,p)

T_ref = 298;

D_e = 6.5e-10*exp(-0.7*c_e/1e3);
D_e = D_e*exp(p.E.De/p.R*(1/T_ref - 1/T));

if(nargout == 2)
    dD_e = -0.7*D_e/1e3;
    varargout{1} = dD_e;
end
end
