function paths = setupPaths()
%SETUPPATHS Configure MATLAB paths for the ISAR project.
%
%   paths = setupPaths()
%
%   Adds the project code directories to the MATLAB search path
%   and returns absolute paths for locating data and outputs.
%
%   Can be called from any working directory once MATLAB
%   can locate this file.

    % Repository root.
    rootDir = fileparts(mfilename('fullpath'));
after i put this in my
    % Project directories.
    paths.root = rootDir;
    paths.data = fullfile(rootDir, 'data');
    paths.outputs = fullfile(rootDir, 'outputs');

    % Add directories containing MATLAB code.
    addpath(fullfile(rootDir, 'functions'));
    addpath(fullfile(rootDir, 'config'));
    addpath(fullfile(rootDir, 'mcatws'));
    addpath(fullfile(rootDir, 'imaging'));
    addpath(fullfile(rootDir, 'simulator'));
    addpath(fullfile(rootDir, 'verification'));

    fprintf('Project paths configured: %s\n', rootDir);
end