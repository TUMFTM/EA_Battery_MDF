%% Single Particle Model w/ Electrolyte & Temperature
%   Published December 18, 2016 by Professor Scott Moura
%   Extended July 16, 2020 by Matthias Wanzel and Nikolaos Wassiliadis

clear;
clc;
close all;
addpath(genpath(pwd));

%% Electrochemical model parameters

% Load US18650VTC5A NCA Cell parameter
run parameter/params

% Calculate C-Rate
[cn_low,cp_low] = init_SOC(p,0); 
[cn_high,cp_high] = init_SOC(p,100); 
Delta_cn = cn_high-cn_low;
Delta_cp = cp_low-cp_high;
qn = p.epsilon_s_n*p.Area*p.L_n*Delta_cn*p.Faraday/3600; 
qp = p.epsilon_s_p*p.Area*p.L_p*Delta_cp*p.Faraday/3600;
p.OneC = min(p.epsilon_s_n*p.L_n*Delta_cn*p.Area*p.Faraday/3600, p.epsilon_s_p*p.L_p*p.Area*Delta_cp*p.Faraday/3600);

%% Measurement hand-over

% Load measurement file
load('measurement/CC_5C_20deg');

% Assign cell deviations
Dataset.Q = 2.52;
Q_t = Dataset.Q/qn;
p.Q_n = p.Q_n*Q_t;     
p.Q_p = p.Q_p*Q_t; 
p.L_n = p.Q_n*3600/(p.epsilon_s_n*p.Area*p.c_s_n_max*p.Faraday);
p.L_p = p.Q_p*3600/(p.epsilon_s_p*p.Area*p.c_s_p_max*p.Faraday);

% Interpolate measurement data
ip_t = 0:1:max(Dataset.Time);
Dataset.U = interp1(Dataset.Time, Dataset.U, ip_t);
Dataset.I = interp1(Dataset.Time, Dataset.I, ip_t);
Dataset.T2 = interp1(Dataset.Time, Dataset.T2, ip_t);
Dataset.I(1) = 0;

% Parse data
t = ip_t;
I =  Dataset.I;
T2 = Dataset.T2;


%% Input data structure with time, current and temperature
% Current | Positive <=> Charge | Negative <=> Discharge
data.time = t;          % [s]
data.cur = I;           % [A]
data.T2 = T2+273.15;    % [K]


%% Preallocation and initial conditions

% Finite difference for spherical particle
p.Nr = 20; % Make this very large so it closely approximates the true model
Nr = p.Nr;
p.delta_r_n = 1/p.Nr;
p.delta_r_p = 1/p.Nr;
r_vec = (0:p.delta_r_n:1)';
r_vecx = r_vec(2:end-1);

% Finite difference points along x-coordinate
p.Nxn = 10;
p.Nxs = 5;
p.Nxp = 10;
p.Nx = p.Nxn+p.Nxs+p.Nxp;
Nx = p.Nx - 3;
x_vec_spme = linspace(0,1,Nx+4);

p.delta_x_n = 1 / p.Nxn;
p.delta_x_s = 1 / p.Nxs;
p.delta_x_p = 1 / p.Nxp;


% Output discretization parameter
disp('Discretization Params:');
fprintf(1,'No. of FDM nodes in Anode | Separator | Cathode : %1.0f | %1.0f | %1.0f\n',p.Nxn,p.Nxs,p.Nxp);
fprintf(1,'No. of FDM nodes in Single Particles : %1.0f\n',p.Nr);


% Solid concentration
SOC_0 = 0; % Initial SOC
[csn0,csp0] = init_SOC(p,SOC_0);  
c_n0 = csn0 * ones(p.Nr-1,1);
c_p0 = csp0 * ones(p.Nr-1,1);

% Electrolyte concentration
ce0 = p.c_e*ones(Nx,1);

% Temperature
T10 = data.T2(1);

% SEI layer
delta_sei0 = 0;

disp('Initial Conditions:');
fprintf(1,'SOC : %2 \n',SOC_0);
fprintf(1,'Normalized Solid Concentration in Anode | Cathode : %1.4f | %1.4f\n',csn0/p.c_s_n_max*100 ,csp0/p.c_s_p_max*100);
fprintf(1,'Electrolyte Concentration : %2.3f kmol/m^3\n',ce0(1)/1e3);
disp(' ');

%% Generate constant system matrices

% Electrolyte concentration matrices
[M1n,M2n,M3n,M4n,M5n, M1s,M2s,M3s,M4s, M1p,M2p,M3p,M4p,M5p, C_ce] = c_e_mats(p);

p.ce.M1n = M1n;
p.ce.M2n = M2n;
p.ce.M3n = M3n;
p.ce.M4n = M4n;
p.ce.M5n = M5n;

p.ce.M1s = M1s;
p.ce.M2s = M2s;
p.ce.M3s = M3s;
p.ce.M4s = M4s;

p.ce.M1p = M1p;
p.ce.M2p = M2p;
p.ce.M3p = M3p;
p.ce.M4p = M4p;
p.ce.M5p = M5p;

p.ce.C = C_ce;

clear M1n M2n M3n M4n M5n M1s M2s M3s M4s M1p M2p M3p M4p M5p C_ce;

%% Simulate SPMeT Plant
tic;
disp('Simulating SPMeT Plant...');

% Initial Conditions
x0 = [c_n0; c_p0; ce0; T10; delta_sei0];
options = odeset('Stats','off','MaxStep',10);

% Solver
[t,x] = ode23s(@(t,x) ode_spmet(t,x,data,p),t,x0,options); 

% Parse states
c_s_n = x(:,1:(p.Nr-1));
c_s_p = x(:,p.Nr : 2*(p.Nr-1));
c_ex = x(:,2*p.Nr-1 : 2*p.Nr-1+p.Nx-4);
T1 = x(:,end-1);
delta_sei = x(:,end);


%% Output Function %%%
NT = length(data.time);

V = zeros(NT,1);                        % Voltage SPMeT
V_spm = zeros(NT,1);                    % Voltage without electrolyte 
SOC_n = zeros(NT,1);                    % State of charge neg. electrode 
SOC_p = zeros(NT,1);                    % State of charge pos. electrode 
c_ss_n = zeros(NT,1);                   % Surface concentration neg. particle
c_ss_p = zeros(NT,1);                   % Surface concentration pos. particle
c_n = zeros(NT,p.Nr+1);                 % Solid concentration neg. electrode
c_p = zeros(NT,p.Nr+1);                 % Solid concentration pos. electrode
c_e = zeros(p.Nx+1,NT);                 % Electrolyte concentrations
n_Li_s = zeros(NT,1);                   % Total Moles of Lithium in Solid
eta_n = zeros(NT,1);                    % Activation overpotential neg. electrode based on Butler–Volmer equation
eta_p = zeros(NT,1);                    % Activation overpotential pos. electrode based on Butler–Volmer equation
Unref = zeros(NT,1);                    % Equilibrium potential neg. electrode
Upref = zeros(NT,1);                    % Equilibrium potential pos. electrode
V_ep = zeros(NT,1);                     % Overpotential due to electrolyte polarization
V_ec = zeros(NT,1);                     % Overpotential due to electrolyte conductivity
eta_sei_n = zeros(NT,1);                % Overpotential neg. electrode due to SEI resistance
eta_sei_p = zeros(NT,1);                % Overpotential pos. electrode due to SEI resistance

for k = 1:NT
    
    % Compute outputs
    [~,V(k),V_spm(k),SOC_n(k),SOC_p(k),c_ss_n(k),c_ss_p(k),c_e(:,k),eta_n(k),eta_p(k),Unref(k),Upref(k),V_ep(k),...
        V_ec(k), eta_sei_n(k), eta_sei_p(k)] = ode_spmet(t(k),x(k,:)',data,p);

    % Aggregate Solid concentrations
    c_n(k,:) = [c_s_n(k,1), c_s_n(k,:), c_ss_n(k)];
    c_p(k,:) = [c_s_p(k,1), c_s_p(k,:), c_ss_p(k)];
    
    % Total Moles of Lithium in Solid
    n_Li_s(k) = (3*p.epsilon_s_p*p.L_p*p.Area) * trapz(r_vec,r_vec.^2.*c_p(k,:)') ...
            + (3*p.epsilon_s_n*p.L_n*p.Area) * trapz(r_vec,r_vec.^2.*c_n(k,:)');
        

    if k > 1
        fprintf(reverseStr);
    end
    msg = sprintf('Processed %d/%d', k, NT);
    fprintf(msg);
    reverseStr = repmat(sprintf('\b'), 1, length(msg));
end

% Output elapsed time
simtime = toc;
fprintf(1,'\n Elapsed time: %4.1f sec or %2.2f min \n',simtime,simtime/60);

disp('To plots results, run...');
disp(' plot_spmet');
disp(' animate_spmet');

figure;
plot(t, V, 'b')
hold on;
plot(t, Dataset.U, 'k')
hold on;
legend({'$$U_{Simulation}$$','$$U_{Measurement}$$'},'interpreter','latex','Fontsize',12,'Location','best');
ylabel('U in V');
xlabel('t in s');