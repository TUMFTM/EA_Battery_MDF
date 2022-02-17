%% ODEs for SPMeT Model
%   Called by spmet.m

function [x_dot,varargout] = ode_spmet(t,x,data,p)

% Electrolyte error handling
persistent ce0_old;

if isempty(ce0_old)
    ce0_old=zeros(p.Nxn-1);
end

%% Parse Input Data

% Parse and interpolate current
% cur = griddedInterpolant(data.time,data.cur);
cur = interp1(data.time,data.cur,t);
%cur = cur(t);
% T2 = griddedInterpolant(data.time,data.T2);
T2 = interp1(data.time,data.T2,t);
%T2 = T2(t);

% Parse states
c_s_n = real(x(1:(p.Nr-1)));
c_s_p = real(x(p.Nr : 2*(p.Nr-1)));
c_e = real(x(2*p.Nr-1 : 2*p.Nr-1+p.Nx-4));
T1 = real(x(end-1));
delta_sei = real(x(end));

% Calculate SOC
r_vec = (0:p.delta_r_n:1)';
c_n = [c_s_n(1); c_s_n; c_s_n(p.Nr-1)];
c_p = [c_s_p(1); c_s_p; c_s_p(p.Nr-1)];
SOC_n = 3/p.c_s_n_max * trapz(r_vec,r_vec.^2.*c_n);
SOC_p = 3/p.c_s_p_max * trapz(r_vec,r_vec.^2.*c_p);

%% Pre-calculations with current states

%%% MOLAR FLUXES
% Compute total molar flux
jn_tot = -cur/(p.Faraday*p.a_s_n*p.Area*p.L_n);
jp_tot = cur/(p.Faraday*p.a_s_p*p.Area*p.L_p);

%%% SOLID PHASE DYNAMICS
% Solid phase diffusivity temperature dependence
D_s_n0 = anodeD(p, SOC_n);
D_s_p0 = cathodeD(p, SOC_p);

p.D_s_n = D_s_n0* exp(p.E.Dsn/p.R*(1/p.T_ref - 1/T1)); 
p.D_s_p = D_s_p0* exp(p.E.Dsp/p.R*(1/p.T_ref - 1/T1));

% Construct (A,B) matrices for solid-phase Li diffusion
[A_n,A_p,B_n,B_p,C_n,C_p,D_n,D_p] = spm_plant_obs_mats(p);

% Compute surface concentrations
c_ss_n = C_n*c_s_n + D_n*jn_tot;
c_ss_p = C_p*c_s_p + D_p*jp_tot;
% Remark: I am cheating slightly here. jn_tot should be jn, but doing so
% imposes an algebraic equation. This forms a DAE. I am going to
% approximate jn by jn_tot, which should be ok, since jn and jn_tot have a
% error on the order of 0.001%

%%% ELECTROLYTE PHASE DYNAMICS
% Electrolyte error handling
if any(c_e<0)
    %c_e0 = evalin('base','ce0');
    c_e0 = ce0_old;
    c_e(1:(p.Nxn-1)) = c_e0(1:(p.Nxn-1));
end

% Compute electrolyte Boundary Conditions
c_e_bcs = p.ce.C * c_e;

ce0n = c_e_bcs(1);
cens = c_e_bcs(2);
cesp = c_e_bcs(3);
ce0p = c_e_bcs(4);

debug=false;

if debug
disp("ce0n");
disp(ce0n);
disp("cens");
disp(cens);
disp("cesp");
disp(cesp);
disp("ce0p");
disp(ce0p);
disp("c_e");
disp(c_e);
end

% Electrolyte error handling
elektrolyte_flag = 0;
if (c_e<0 | ce0n<0 | ce0p<0) 
    elektrolyte_flag = 1;
    ce0n = 0.5;
end

% Separate and aggregate electrolyte concentration
c_en = c_e(1:(p.Nxn-1));
c_es = c_e((p.Nxn-1)+1:(p.Nxn-1)+(p.Nxs-1));
c_ep = c_e((p.Nxn-1)+p.Nxs : end);
c_ex = [ce0n; c_en; cens; c_es; cesp; c_ep; ce0p];


%% Voltage output

% Average electrolyte concentrations
cen_bar = mean(c_ex(1:p.Nxn+1,:));
ces_bar = mean(c_ex((p.Nxn+1):(p.Nxn+p.Nxs+1),:));
cep_bar = mean(c_ex((p.Nxn+p.Nxs+1):(p.Nxn+p.Nxs+p.Nxp+1),:));

% Overpotentials due to electrolyte subsystem
kap_n = electrolyteCond(cen_bar,T1);
kap_s = electrolyteCond(ces_bar,T1);
kap_p = electrolyteCond(cep_bar,T1);

% Bruggeman relationships
kap_n_eff = kap_n * p.epsilon_e_n.^(p.brug);
kap_s_eff = kap_s * p.epsilon_e_s.^(p.brug);
kap_p_eff = kap_p * p.epsilon_e_p.^(p.brug);

% Activity coefficient
dfca_n = electrolyteAct(cen_bar,T1);
dfca_s = electrolyteAct(ces_bar,T1);
dfca_p = electrolyteAct(cep_bar,T1);

% Kinetic reaction rate, adjusted for Arrhenius temperature dependence
k_n0 = anodeK(p, SOC_n);
k_p0 = cathodeK(p, SOC_p);

p.k_n = k_n0* exp(p.E.kn/p.R*(1/p.T_ref - 1/T1));
p.k_p = k_p0* exp(p.E.kp/p.R*(1/p.T_ref - 1/T1));

% Stochiometric Concentration Ratio
theta_n = c_ss_n / p.c_s_n_max;
theta_p = c_ss_p / p.c_s_p_max;

% Equilibrium Potential
Unref = refPotentialAnode(p,theta_n);
Upref = refPotentialCathode(p,theta_p);

% Exchange current density
c_e_bar = [cen_bar; ces_bar; cep_bar];
[i_0n,i_0p] = exch_cur_dens(p,c_ss_n,c_ss_p,c_e_bar);

% Overpotentials
RTaF=(p.R*T1)/(p.alph*p.Faraday);
eta_n = RTaF * asinh(-cur / (2*p.a_s_n*p.Area*p.L_n*i_0n(1)));
eta_p = RTaF * asinh(cur / (2*p.a_s_p*p.Area*p.L_p*i_0p(end)));

% Total resistance (film + growing SEI layer)
R_tot_n = p.R_f_n + delta_sei/p.kappa_P;
R_tot_p = p.R_f_p + 0;

% SPM Voltage (i.e. w/o electrolyte concentration terms)
eta_sei_n = (R_tot_n/(p.a_s_n*p.L_n*p.Area))*-cur;
eta_sei_p = (R_tot_p/(p.a_s_p*p.L_p*p.Area))*-cur;

V_noVCE = eta_p - eta_n + Upref - Unref - eta_sei_n + eta_sei_p;

% Overpotential due to electrolyte conductivity
V_electrolyteCond = (p.L_n/(2*kap_n_eff) + 2*p.L_s/(2*kap_s_eff) + p.L_p/(2*kap_p_eff))*(-cur/p.Area);

% Overpotential due to electrolyte polarization
V_electrolytePolar = (2*p.R*T1)/(p.Faraday) * (1-p.t_plus)* ...
        ( (1+dfca_n) * (log(cens) - log(ce0n)) ...
         +(1+dfca_s) * (log(cesp) - log(cens)) ...
         +(1+dfca_p) * (log(ce0p) - log(cesp)));

% Add 'em up!
V = V_noVCE - V_electrolyteCond + V_electrolytePolar;


%% Aging Dynamics

%   SEI Layer Growth model
%   Eqns Adopted from Ramadass et al (2004) [Univ of South Carolina]
%   "Development of First Principles Capacity Fade Model for Li-Ion Cells"
%   DOI: 10.1149/1.1634273
%   NOTE1: This model has NOT been validated experimentally by eCAL
%   NOTE2: We assume this submodel only applies to anode

% Difference btw solid and electrolyte overpotential [V]
phi_se = eta_n + Unref + p.Faraday*R_tot_n*jn_tot;

% Side exn overpotential [V]
eta_s = phi_se - p.Us - p.Faraday*R_tot_n*jn_tot;

% Molar flux of side rxn [mol/s-m^2]
j_s = -p.i0s/p.Faraday * exp((-p.alph*p.Faraday)/(p.R*T1)*eta_s);

% SEI layer growth model [m/s]
delta_sei_dot = -p.M_P/(p.rho_P) * j_s;

% Molar flux of intercalation
jn = (abs(jn_tot) - abs(j_s)) * sign(jn_tot);
jp = jp_tot;


%% Solid Phase Dynamics

% ODE for c_s
c_s_n_dot = A_n*c_s_n + B_n*jn;
c_s_p_dot = A_p*c_s_p + B_p*jp;


%% Electrolyte Dynamics

% Compute Electrolyte Diffusion Coefficient and Derivative
[D_en,dD_en] = electrolyteDe(c_en, T1, p);
[D_es,dD_es] = electrolyteDe(c_es, T1, p);
[D_ep,dD_ep] = electrolyteDe(c_ep, T1, p);

% Apply bruggeman relation 
D_en_eff = D_en .* p.epsilon_e_n.^(p.brug-1);
dD_en_eff = dD_en .* p.epsilon_e_n.^(p.brug-1);

D_es_eff = D_es .* p.epsilon_e_s.^(p.brug-1);
dD_es_eff = dD_es .* p.epsilon_e_s.^(p.brug-1);

D_ep_eff = D_ep .* p.epsilon_e_p.^(p.brug-1);
dD_ep_eff = dD_ep .* p.epsilon_e_p.^(p.brug-1);

% System Matrices have all been precomputed & stored in param struct "p"

% Compute derivative
c_en_dot = dD_en_eff.*(p.ce.M1n*c_en + p.ce.M2n*c_e_bcs(1:2)).^2 ...
    + D_en_eff.*(p.ce.M3n*c_en + p.ce.M4n*c_e_bcs(1:2)) + diag(p.ce.M5n)*jn;

c_es_dot = dD_es_eff.*(p.ce.M1s*c_es + p.ce.M2s*c_e_bcs(2:3)).^2 ...
    + D_es_eff.*(p.ce.M3s*c_es + p.ce.M4s*c_e_bcs(2:3));

c_ep_dot = dD_ep_eff.*(p.ce.M1p*c_ep + p.ce.M2p*c_e_bcs(3:4)).^2 ...
    + D_ep_eff.*(p.ce.M3p*c_ep + p.ce.M4p*c_e_bcs(3:4)) + diag(p.ce.M5p)*jp;

% Assemble c_e_dot
c_e_dot = [c_en_dot; c_es_dot; c_ep_dot];

% Electrolyte error handling
if  elektrolyte_flag==1 & c_en_dot(1)<0
    c_e_dot = zeros(size(c_e_dot));
end

%% Thermal Dynamics

% State-of-Charge (Bulk)
r_vec = (0:p.delta_r_n:1)';
c_n = [c_s_n(1); c_s_n; c_ss_n];
c_p = [c_s_p(1); c_s_p; c_ss_p];
SOC_n = 3/p.c_s_n_max * trapz(r_vec,r_vec.^2.*c_n);
SOC_p = 3/p.c_s_p_max * trapz(r_vec,r_vec.^2.*c_p);

% Equilibrium potentials
[Unb,~,dUnbdT] = refPotentialAnode(p, SOC_n);
[Upb,~,dUpbdT] = refPotentialCathode(p, SOC_p);


%% Heat generation
Qdot = cur*(V - (Upb - Unb) + T1*(dUpbdT - dUnbdT));

% Differential equations
T1_dot = (p.h12 * (T2-T1) + Qdot) / p.C1;
%T2_dot = (p.h12 * (T1-T2) + p.h2a*(p.T_amb - T2)) / p.C2;


%% Concatenate time derivatives
x_dot = [c_s_n_dot; c_s_p_dot; c_e_dot; T1_dot; delta_sei_dot];

%% Electrolyte error handling
%assignin('base','ce0',c_e);
ce0_old=c_e(1:(p.Nxn-1));

%% Concatenate outputs
varargout{1} = V;
varargout{2} = V_noVCE;
varargout{3} = SOC_n;
varargout{4} = SOC_p;
varargout{5} = c_ss_n;
varargout{6} = c_ss_p;
varargout{7} = c_ex';
varargout{8} = eta_n;
varargout{9} = eta_p;
varargout{10} = Unref;
varargout{11} = Upref;
varargout{12} = V_electrolytePolar;
varargout{13} = V_electrolyteCond;  
varargout{14} = eta_sei_n; 
varargout{15} = eta_sei_p;
varargout{16} = c_n;
varargout{17} = c_p; 

