function setPath()
    % Set the projects path 
    clear global;  
    clc;
    filename = matlab.desktop.editor.getActiveFilename;
    [filepath,~,~] = fileparts(filename);
    project_path=genpath(filepath);
    addpath(project_path);

    %Set CasADi path
    casadi_path='C:\Users\ARCLab\Documents\GabrielB\Matlab\casadi-3.6.3';
    addpath(casadi_path);
end