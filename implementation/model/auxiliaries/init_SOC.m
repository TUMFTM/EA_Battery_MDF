%% Compute Initial Solid Concentrations from SOC
function [csn0,csp0] = init_SOC(p,SOC)
csp0 = p.c_s_p_max*(1-((p.B_A.Q_cathode_SP + (p.B_A.Q_cathode_EP - p.B_A.Q_cathode_SP) * SOC/100)));
csn0 = p.c_s_n_max*((p.B_A.Q_anode_SP + (p.B_A.Q_anode_EP - p.B_A.Q_anode_SP) * SOC/100));
