%  Add dependency toolbox to matlab work path 

fprintf('# add matconvernet, vlfeat, liblinear to matlab work path\n');
%vlfeat
run(fullfile('/home/gaobb/mywork/toolbox/vlfeat-0.9.19/toolbox/vl_setup.m')) ;          
 %liblinear
addpath(genpath(fullfile('/home/gaobb/mywork/toolbox/liblinear-2.1_dense'))) ;                                  
%matconvnet
run(fullfile('/home/gaobb/mywork/toolbox/matconvnet-1.0-beta24/matlab/vl_setupnn.m')) ; 

addpath(genpath('./utils'))
addpath(genpath('./setup_imdb'))