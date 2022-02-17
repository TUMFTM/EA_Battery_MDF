%% Electrolyte Activity Coefficient Function: dlnf/dln(c_e) 

function [dActivity] = electrolyteAct(c_e,T)

if c_e > 2000
    c_e = 2000;
end

c_e = c_e./1000;

dActivity =  (0.2731.*c_e.^2+0.6352.*c_e+0.4577)./(0.1291.*c_e.^3-0.3517.*c_e.^2+0.4893.*c_e+0.5713)-1;

end
