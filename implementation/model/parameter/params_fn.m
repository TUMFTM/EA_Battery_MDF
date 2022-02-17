function p = params_fn(init_capacity, init_sei_resistance)

%% Params for Electrochemical Model
% US18650VTC5A NCA Cell

% init values are only given at t=0, so they need to be stored for next
% step of simulation

persistent init_capacity_store;
persistent init_sei_resistance_store;

if isempty(init_capacity_store)
    init_capacity_store=init_capacity;
else
    init_capacity=init_capacity_store;
end

if isempty(init_sei_resistance_store)
    init_sei_resistance_store=init_sei_resistance;
else
    init_sei_resistance=init_sei_resistance_store;
end


%% Inits for Coder
% If the struct p is once read by simulink, no new field can be added to p.
% So all fields have to be assigned first with their correct dimensions.
% The order does not matter

% There MUST NOT be any sparse definition in here, as this makes the whole
% function produce socalled "variable-sized" outputs, which leads to 
% further problems in the Simulink port definition.

p.p_a         = 0.0;
p.p_c         = zeros(1,7);
p.L_s         = 0.0;
p.Area        = 0.0;
p.R_s_n       = 0.0;
p.R_s_p       = 0.0;
p.epsilon_s_n = 0.0;
p.epsilon_s_p = 0.0;
p.epsilon_e_n = 0.0;
p.epsilon_e_s = 0.0;
p.epsilon_e_p = 0.0;
p.epsilon_f_n = 0.0;
p.epsilon_f_p = 0.0;
p.a_s_n       = 0.0;
p.a_s_p       = 0.0;
p.D_s_n0      = 0.0;
p.D_s_p0      = 0.0;
p.D_s_n       = 0.0;
p.D_s_p       = 0.0;
p.brug        = 0.0;
p.t_plus      = 0.0;
p.Faraday     = 0.0;
p.R           = 0.0;
p.alph        = 0.0;
p.R_f_n       = 0.0;
p.R_f_p       = 0.0;
p.k_n0        = 0.0;
p.k_p0        = 0.0;
p.k_n         = 0.0;
p.k_p         = 0.0;
p.T_amb       = 0.0;
p.E.kn        = 0.0;
p.E.kp        = 0.0;
p.E.Dsn       = 0.0;
p.E.Dsp       = 0.0;
p.E.De        = 0.0;
p.E.kappa_e   = 0.0;
p.T_ref       = 0.0;
p.T_ref_electrolyte = 0.0;
p.C1          = 0.0;
p.C2          = 0.0;
p.h12         = 0.0;
p.h2a         = 0.0;
p.kappa_P     = 0.0;
p.M_P         = 0.0;
p.rho_P       = 0.0;
p.i0s         = 0.0;
p.Us          = 0.0;
p.c_s_n_max   = 0.0;
p.c_s_p_max   = 0.0;
p.c_e         = 0.0;
p.Q_n         = 0.0;
p.Q_p         = 0.0;
p.L_n         = 0.0;
p.L_p         = 0.0;
p.rho_avg     = 0.0;
p.w_cell      = 0.0;
p.OneC        = 0.0;
p.delta_t     = 0.0;
p.Nr          = 0.0;
p.delta_r_n   = 0.0;
p.delta_r_p   = 0.0;
p.Nxn         = 0.0;
p.Nxs         = 0.0;
p.Nxp         = 0.0;
p.Nx          = 0.0;
p.delta_x_n   = 0.0;
p.delta_x_s   = 0.0;
p.delta_x_p   = 0.0;


%% Load Params from Fitting Skripts
% Balancing and Alignment 
transfer = coder.load('parameter/B_A');
p.B_A = transfer.Results;
% Anode OCV 
transfer = coder.load('parameter/OCV_anode');
p.p_n = transfer.p;
% Cathode OCV 
transfer = coder.load('parameter/OCV_cathode');
p.p_p = transfer.p;
% Anode kinetics
transfer = coder.load('parameter/kinetics_anode');
p.kin_k_n = transfer.anode_fitk;
p.kin_D_n = transfer.anode_fitD;
% Cathode kinetics
transfer = coder.load('parameter/kinetics_cathode');
p.kin_k_p = transfer.cathode_fitk;
p.kin_D_p = transfer.cathode_fitD;
% Fullcell kinetics
transfer = coder.load('parameter/kinetics_fullcell');
p.E.kn  = transfer.activation_energies(1);     % Reaction rate neg. electrode [J/mol]
p.E.kp  = transfer.activation_energies(2);     % Reaction rate pos. electrode [J/mol]
p.E.Dsn = transfer.activation_energies(3);     % Diffusion coeff for solid in neg. electrode [J/mol]
p.E.Dsp = transfer.activation_energies(4);     % Diffusion coeff solid pos. electrode [J/mol]
p.K_multi_n = transfer.ref_factors(1); % Scaling factor at fullcell level and reference temperature 293.15K
p.K_multi_p = transfer.ref_factors(2); % Scaling factor at fullcell level and reference temperature 293.15K
p.D_multi_n = transfer.ref_factors(3); % Scaling factor at fullcell level and reference temperature 293.15K
p.D_multi_p = transfer.ref_factors(4); % Scaling factor at fullcell level and reference temperature 293.15K


%% Geometric Params

p.Area = 0.1024;  % Electrode area [m^2] - Lain (2019) 

% Thickness of layers
p.L_s = 8e-6;     % Lain (2019) Thickness of separator [m]

L_ccn = 14e-6;    % Lain (2019) Thickness of negative current collector [m]
L_ccp = 15e-6;    % Lain (2019) Thickness of positive current collector [m]

% Particle Radii
p.R_s_n = 7e-6;   % Lain (2019) Radius of solid particles in negative electrode [m]
p.R_s_p = 2.5e-6; % Lain (2019) Radius of solid particles in positive electrode [m]

% Volume fractions
p.epsilon_s_n = 0.73*0.95;      % Volume fraction in solid for neg. electrode - Lain (2019) 95% active material 
p.epsilon_s_p = 0.87*0.96;      % Volume fraction in solid for pos. electrode - Lain (2019) 96% active material

p.epsilon_e_n = 0.27;   % Lain (2019) Volume fraction in electrolyte for neg. electrode
p.epsilon_e_s = 0.4;    % Volume fraction in electrolyte for separator
p.epsilon_e_p = 0.13;   % Lain (2019) Volume fraction in electrolyte for pos. electrode

% make element to caclulate phi_{s}
p.epsilon_f_n = 1-p.epsilon_s_n-p.epsilon_e_n;  % Volume fraction of filler in neg. electrode
p.epsilon_f_p = 1-p.epsilon_s_p-p.epsilon_e_p;  % Volume fraction of filler in pos. electrode

epsilon_f_n = p.epsilon_f_n;  % Volume fraction of filler in neg. electrode
epsilon_f_p = p.epsilon_f_p;  % Volume fraction of filler in pos. electrode

% Specific interfacial surface area
p.a_s_n = 3*p.epsilon_s_n / p.R_s_n;  % Negative electrode [m^2/m^3]
p.a_s_p = 3*p.epsilon_s_p / p.R_s_p;  % Positive electrode [m^2/m^3]

% Mass densities
rho_sn = 2250;    % CAS 7782-42-5 2200 - Lain (2019) 2250
rho_sp = 4800;    % CAS 193214-24-3 4450 - Lain (2019) 4800
rho_e =  1324;    % Electrolyte [kg/m^3]
rho_f_n = 1743;   % Filler negativ [kg/m^3] Lain (2019) Binder:Carbon 4:1  
rho_f_p = 1812;   % Filler positive [kg/m^3] Lain (2019) Binder:Carbon 1:1 
rho_ccn = 8954;   % Current collector in negative electrode
rho_ccp = 2707;   % Current collector in positive electrode


%% Transport Params

p.brug = 1.5;       % Bruggeman porosity

% Miscellaneous
p.t_plus = 0.38;            % Transference number - Valoen (2005) 
p.Faraday = 96485.33289;    % Faraday's constant, [Coulumbs/mol]


%% Kinetic Params

p.R = 8.314472;         % Gas constant, [J/mol-K]

p.alph = 0.5;           % Charge transfer coefficients

if init_sei_resistance ~= 0
    p.R_f_n = init_sei_resistance;    % Resistivity from BaSyTec [Ohms*m^2]
else
    p.R_f_n = 4.4e-3;       % Default Resistivity of SEI layer, [Ohms*m^2]
end
p.R_f_p = 0;            % Resistivity of SEI layer, [Ohms*m^2]


%% Aging submodel Params (Unused)

%   SEI Layer Growth model
%   Adopted from Ramadass et al (2004) [Univ of South Carolina]
%   "Development of First Principles Capacity Fade Model for Li-Ion Cells"
%   DOI: 10.1149/1.1634273
%   NOTE: These parameters have NOT been experimentally validated by eCAL

p.kappa_P = 1;      % [S/m] conductivity of side rxn product
p.M_P = 7.3e1;      % [kg/mol] molecular weight of side rxn product
p.rho_P = 2.1e3;    % [kg/m^3] mass density of side rxn product
p.i0s = 0; %1.5e-6; % [A/m^2] exchange current density of side rxn
p.Us = 0.4;         % [V] reference potential of side rxn


%% Concentrations

q_n = 343;                                         % Active material capacity, [mAh/g] - Lain (2019)
p.c_s_n_max = 3.6e3 * q_n * rho_sn / p.Faraday;    % Max concentration in anode, [mol/m^3]

q_p = 168;                                         % Active material capacity, [mAh/g] - Lain (2019)
p.c_s_p_max = 3.6e3 * q_p * rho_sp / p.Faraday;    % Max concentration in cathode, [mol/m^3]

p.c_e = 1e3;                                       % Fixed electrolyte concentration, [mol/m^3]


%% Cell Deviation

Q_Cell = 2.581737877888906; % Capacity of cell [Ah]

% Capacity tuning Parameter  
if init_capacity ~= 0
    Q_t = init_capacity/Q_Cell; % = 1 if cell is exacly as expected
else 
    Q_t = 1;
end

% Match thickness of electrodes according to results from Balancing and Alignment
p.Q_n = (max(p.B_A.Q_anode) - min(p.B_A.Q_anode))/3600*Q_t;      % Anode capacity, [Ah]
p.Q_p = (max(p.B_A.Q_cathode) - min(p.B_A.Q_cathode))/3600*Q_t;  % Cathode capacity according, [Ah]
p.L_n = p.Q_n*3600/(p.epsilon_s_n*p.Area*p.c_s_n_max*p.Faraday); % Thickness of neg. electrode, [m]
p.L_p = p.Q_p*3600/(p.epsilon_s_p*p.Area*p.c_s_p_max*p.Faraday); % Thickness of pos. electrode, [m]


%% Lumped weight of cell 

% Compute cell mass [kg/m^2]
m_n = p.L_n * (rho_e*p.epsilon_e_n + rho_sn*p.epsilon_s_n + rho_f_n*epsilon_f_n);
m_s = p.L_s * (rho_e*p.epsilon_e_s);
m_p = p.L_p * (rho_e*p.epsilon_e_p + rho_sp*p.epsilon_s_p + rho_f_p*epsilon_f_p);
m_cc = rho_ccn*L_ccn + rho_ccp*L_ccp;

% Lumped density [kg/m^2]
p.rho_avg = m_n + m_s + m_p + m_cc;

% Lumped weight [kg]
p.w_cell = p.rho_avg*p.Area;


%% Thermodynamic Params

% Reference temperature
p.T_ref = 293.15;   % Arrhenius reference temperature [K]
p.T_ref_electrolyte = 296.15;   % Arrhenius reference temperature for electrolyte [K]

% Activation Energies
p.E.De = 17.12e3;           % Diffusion coeff electrolyte [J/mol]
p.E.kappa_e =17.12e3;           % Activation energy electrolyte conductivity [J/mol]

% Heat transfer parameters
p.C1 = 986.2*p.w_cell;      % Heat capacity, [J/K]
p.h12 = 0.0306; % Heat transfer coefficient, [W/K]