function setup(doCompile, matconvnetOpts)
% SETUP  Setup paths, external, etc.
% 
%   doCompile:: false
%       Set to true to compile the libraries
%   matconvnetOpts:: struct('enableGpu',false)
%       Options for vl_compilenn

if nargin==0, 
    doCompile = false;
elseif nargin<2, 
    matconvnetOpts = struct('enableGpu', false); 
end

if doCompile && gpuDeviceCount()==0 ...
    && isfield(matconvnetOpts,'enableGpu') && matconvnetOpts.enableGpu, 
    fprintf('No supported gpu detected! ');
    return;
end

% -------------------------------------------------------------------------
%                                                                   vlfeat
% -------------------------------------------------------------------------
if doCompile,
    cmd = 'make -C external/vlfeat/ clean';
    if system(cmd), 
        error('Error while excution: %s', cmd);
    end
    cmd = sprintf('make -C external/vlfeat/ MEX=%s', ...
        fullfile(matlabroot,'bin','mex'));
    if system(cmd), 
        error('Error while excution: %s', cmd);
    end
end
run external/vlfeat/toolbox/vl_setup.m

% -------------------------------------------------------------------------
%                                                               matconvnet
% -------------------------------------------------------------------------
if doCompile, 
    run external/matconvnet/matlab/vl_setupnn.m
    cd external/matconvnet
    vl_compilenn(matconvnetOpts);
    cd ../..
end
run external/matconvnet/matlab/vl_setupnn.m


% -------------------------------------------------------------------------
%                                                             DenseLibLinear
% -------------------------------------------------------------------------
if doCompile, 
    run external/DenseLibLinear/matlab/vl_setupnn.m
    cd external/DenseLibLinear
    make clean
    make
    cp train_dense predict_dense ../../
    cd ../..
end
% -------------------------------------------------------------------------
%                                                      add utils setup_imdb
% -------------------------------------------------------------------------
addpath(genpath('./utils'))
addpath(genpath('./setup_imdb'))


