%% Test on Simulink Algorithm 1 from  "Numerical Methods to Compute the Coriolis Matrix and Christoffel Symbols for Rigid-Body System" 
% by Sebastian Echeandia and Patrick M. Wensing

%% Choose a urdf model
setPath()
filename = matlab.desktop.editor.getActiveFilename;
[location_tests_folder,~,~] = fileparts(filename);
a1 = [location_tests_folder,'/../../URDFs/a1.urdf'];
kuka_urdf = [location_tests_folder,'/../../URDFs/kr30_ha-identified.urdf'];
twoLink_urdf = [location_tests_folder,'/../../URDFs/twoLinks.urdf'];
kuka_kr210 = [location_tests_folder,'/../../URDFs/kuka_kr210.urdf'];
iCub_r_leg = [location_tests_folder,'/../../URDFs/iCub_r_leg.urdf'];

%% Import necessary functions 
import urdf2casadi.Utils.modelExtractionFunctions.extractSystemModel
import urdf2casadi.Dynamics.createMassAndCoriolisMatrixFunction
import urdf2casadi.Dynamics.symbolicInverseDynamics
import urdf2casadi.Dynamics.auxiliarySymbolicDynamicsFunctions.createSpatialTransformsFunction
import urdf2casadi.Utils.auxiliaryFunctions.plot_trajectories
import urdf2casadi.Utils.auxiliaryFunctions.romualdi2020_generate_min_jerk_trajectories

%% Input urdf file to acquire robot structure
robotURDFModel = a1;

%% Generate functions
% Fix location folder to store the generated c and .mex files
location_generated_functions = [location_tests_folder,'/../../automaticallyGeneratedFunctions'];

[HFunction,HDotFunction,CFunction]= createMassAndCoriolisMatrixFunction(robotURDFModel,1,location_generated_functions);
symbolicIDFunction = symbolicInverseDynamics(robotURDFModel,1,location_generated_functions);
spatialTransformoptions.geneate_c_code = true;
spatialTransformoptions.location_generated_fucntion = location_generated_functions;
spatialTransformoptions.FrameVelocityRepresentation = "INERTIAL_FIXED_REPRESENTATION";

[jacobian,X,XForce,S] = createSpatialTransformsFunction(robotURDFModel,spatialTransformoptions);
%% Create trajectories for simulation
[smds,model] = extractSystemModel(robotURDFModel);
nrOfJoints = smds.NB;
K = eye(nrOfJoints);
if nrOfJoints == 6
    initial_pos = [35.9124; -90.0776; 114.0132; -87.1129; 96.4907; 86.7602];
    final_pos = [50.9124; -90.0776; 114.0132; -87.1129; 96.4907; 86.7602];
end
if nrOfJoints==1
    initial_pos = [35.9124];
    final_pos = [335.9124];
end
trajectoryDuration = 10;
sampling_period = 0.01;
q = romualdi2020_generate_min_jerk_trajectories(initial_pos,...
                            zeros(nrOfJoints,1), zeros(nrOfJoints,1), final_pos, zeros(nrOfJoints,1), zeros(nrOfJoints,1),...
                            trajectoryDuration, sampling_period);
qd = [zeros(1,nrOfJoints);
      diff(q)];
qdd = [zeros(1,nrOfJoints);
      diff(qd)];

gravityModulus = 0;
g = [0;0;-gravityModulus];
nrOfSamples = trajectoryDuration/sampling_period +1;
tau_rnea = zeros(nrOfSamples,nrOfJoints);

jacobian_inTime = zeros(6,nrOfJoints,nrOfSamples);
% Some external force for the simulation
F_ext = zeros(6,nrOfJoints);
for t = 1:nrOfSamples
    tau_rnea(t,:) = rnea(q(t,:),qd(t,:),qdd(t,:),g,F_ext)';
end
%% Plot results
timesInSeconds = sampling_period*(1:nrOfSamples);
plot_trajectories(q, timesInSeconds,'q');
plot_trajectories(qd, timesInSeconds,'dq');
plot_trajectories(qdd, timesInSeconds,'ddq');
plot_trajectories(tau_rnea, timesInSeconds,'tau_{rnea}');


% Store trajectories as timeseries for simulink
q_data = timeseries(q);
qd_data = timeseries(qd);
qdd_data = timeseries(qdd);
tau_data = timeseries(tau_rnea);

