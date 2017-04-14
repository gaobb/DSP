% Single-scale DSP
% Author: Bin-Bin Gao (gaobb@lamda.nju.edu.cn)
% Created on 2015.04.28
% Last modified on 2017.04.13
clear
clc

%----------------------------------------------------------------------------------------------------------
%                   Add dependency toolbox to matlab work path
%-----------------------------------------------------------------------------------------------------------
run('setup')
%----------------------------------------------------------------------------------------------------------
%                   Set pre-train model and datasets path
%-----------------------------------------------------------------------------------------------------------
models = {'VggNet_16','VggNet_19','ResNet_50','ResNet_152'};
datasets ={'caltech101','Stanford40','Indoor67','Scene15','CUB_200_2011','Stanford_Cars','voc07','Oxford_flowers'};%'voc07': opt.train_test_set = 'trainval-test';opt.classifier = 'vlfeat';
encodes ={ 'FV','VLAD','D3'};
norms = {'fro','none','l2','0-1'};

opt.model_dir = '/home/gaobb/vgg_net';
opt.data_dir  = '/mnt/data3/gaobb/image_data/PASCAL';


opt.model = 'VggNet_16';
opt.cnn_layer = 'pool5'; 
opt.norm = 'fro';

opt.dataset = 'caltech101';
opt.imgsize = 384; %{224, 384, 512};

opt.lite = true;    
opt.encode = 'FV';
opt.numWords = 2; 
opt.gpu_id = [9]; 

opt.train_test_set = 'train-val';
opt.classifier = 'liblinear';
%----------------------------------------------------------------------------------------------------------
%                   Run Single-scale DSP
%-----------------------------------------------------------------------------------------------------------
dsp_svm(opt);

