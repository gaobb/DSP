% Multi-scale DSP
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
encodes ={ 'FV','VLAD'};
norms = {'fro','l2','0-1'};

opt.model_dir = '/home/gaobb/vgg_net';
opt.data_dir  = '/mnt/data3/gaobb/image_data/PASCAL';


opt.model = 'VggNet_16';
opt.cnn_layer = 'pool5'; 
opt.norm = 'fro';

opt.dataset = 'caltech101';

opt.split = 1;
opt.lite = false;    
opt.encode = 'FV';
opt.spatial = {'0x0','1x1'};

opt.numWords = 2; 
opt.gpu_id = [9]; 

opt.train_test_set = 'train-val';
opt.classifier = 'liblinear';



%----------------------------------------------------------------------------------------------------------
%                   step1: Single-scale DSP
%-----------------------------------------------------------------------------------------------------------
imgsizes = {224, 384, 512};
for s= 1:3
    opt.imgsize = imgsizes{s};
    dsp_svm(opt);
end
%----------------------------------------------------------------------------------------------------------
%                   step2: Multi-scale DSP
%-----------------------------------------------------------------------------------------------------------
opt.datasetDir = fullfile(opt.data_dir, opt.dataset) ;
opt.data_split = ['./results/split_',num2str(opt.split)];
opt.rootPath = fullfile(opt.data_split, opt.dataset) ;
opt.expPath = fullfile(opt.rootPath,[opt.model,'-',opt.encode,'-',...
    num2str(opt.numWords),'-SP-',num2str(numel(opt.spatial)),...
    '-Norm-',opt.norm]);

train_test_sets = strsplit(opt.train_test_set, '-');

for s = 1:3
    train_file = [train_test_sets{1},num2str(imgsizes{s}),'.bin'];
    fin(s) = fopen(fullfile(opt.expPath,train_file));
    
    num = fread(fin(s),1,'int');
    dim = fread(fin(s),1,'int');
end

Mstrainfeat_path = fullfile(opt.expPath,'MsTrain.bin');
if exist(Mstrainfeat_path,'file')
    system(['rm  ' Mstrainfeat_path]);
end
f1 = fopen(Mstrainfeat_path,'w');
fwrite(f1,num,'int'); % # of examples
fwrite(f1,dim,'int'); % # of dimensions

for n=1:num
    for s =1:numel(imgsizes)
        label(1,s) = fread(fin(s),1,'int');
        feat(:,s) = fread(fin(s),dim,'float');
    end
    ms_label = label(1,1);
    ms_feat = mean(feat,2);
    ms_feat =  ms_feat./max(norm(ms_feat),1e-12);
    fwrite(f1,ms_label,'int'); % label
    fwrite(f1,ms_feat,'float'); % data
end

svmmodel_path = fullfile(opt.expPath,'Mstrain.bin.model');
system(['time  ./train_dense   -c 1 ',Mstrainfeat_path, '  ', svmmodel_path]);


Mstestfeat_path = fullfile(opt.expPath,'MsTest.bin');

if exist(Mstestfeat_path,'file')
    system(['rm  ' Mstestfeat_path]);
end
for s = 1:3
    test_file = [train_test_sets{2},num2str(imgsizes{s}),'.bin'];
    fin(s) = fopen(fullfile(opt.expPath,test_file));
    
    num = fread(fin(s),1,'int');
    dim = fread(fin(s),1,'int');
end

f1 = fopen(Mstestfeat_path,'w');
fwrite(f1,num,'int'); % # of examples
fwrite(f1,dim,'int'); % # of dimensions

for n=1:num
    for s =1:numel(imgsizes)
        label(1,s) = fread(fin(s),1,'int');
        feat(:,s) = fread(fin(s),dim,'float');
    end
    ms_label = label(1,1);
    ms_feat = mean(feat,2);
    % ms_feat = max(temp_feat');
    
    ms_feat =  ms_feat./max(norm(ms_feat),1e-12);
    fwrite(f1,ms_label,'int'); % label
    fwrite(f1,ms_feat,'float'); % data
end
pred_test = fullfile(opt.expPath,'MsPred.txt');
system(['time  ./predict_dense   ',Mstestfeat_path, '  ', svmmodel_path, '  ', pred_test]);


preds = textread(pred_test,'','delimiter',',');
cmat = confusionmat(preds(:,end), preds(:,1));
meanAcc = sum(diag(cmat))./sum(cmat(:));
meanRecall = mean(diag(cmat)./sum(cmat,2));
Result = sprintf('# meanAcc: %.2f%%, meanRecall: %.2f%%\n',100*meanAcc,100*meanRecall);

figure(1) ; clf ;
imagesc(cmat) ; axis square ;
title(Result) ;
vl_printsize(1) ;
print('-dpdf', fullfile(opt.expPath, ['MS-result-confusion.pdf'])) ;
print('-djpeg', fullfile(opt.expPath, ['Ms-result-confusion.jpg'])) ;

diary = fullfile(opt.expPath,['MS',opt.dataset,'diary.txt']);
f = fopen(diary,'a');
fprintf(f,'\n# Muti-Scale %s ',[opt.model,'-',opt.encode,'-',num2str(opt.numWords)]);
fprintf(f,'%s \n',Result);

fclose(f);

%----------------------------------------------------------------------------------------------------------
%                   End
%-----------------------------------------------------------------------------------------------------------
