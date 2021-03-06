% 1 extract DSP feature
% 2 train liblinear model
% 3 evlauate classification performance on validation or testing data
% Author: Bin-Bin Gao (gaobb@lamda.nju.edu.cn) or (csgaobb@gmail.com)
% Created on 2015.04.28
% Last modified on 2017.04.13

function dsp_svm(varargin)
opt.model_dir = '/home/gaobb/vgg_net';
opt.data_dir  = '/mnt/data3/gaobb/image_data/PASCAL';

opt.train_test_set = 'train-val';
opt.model = 'VggNet_16';

opt.cnn_layer = 'pool5'; 
opt.norm = 'fro';

opt.dataset = 'caltech101';
opt.lite = true;    
opt.split = 1;
opt.data_split = ['./results/split_',num2str(opt.split)];

opt.encode = 'FV';
opt.numWords = 2; % FV:2 VLAD:4 % the number of GMM components or the clusters of kmeans
opt.spatial = {'0x0','1x1'};
opt.imgsize = 384;

opt.gpu_id = [9]; %
opt.classifier = 'vlfeat';

opt = vl_argparse(opt, varargin) ;


opt.interpolation =  'bilinear';
opt.keepAspect = 1;
opt.PCA_energy = 0.0;
opt.useRoot = 2;
opt.useRN = 0;
opt.batch_size = 64;
opt.num_samtrain = 5000;
opt.seed = opt.split ;  
opt.model_type = 'matconvnet';

opt.datasetDir = fullfile(opt.data_dir, opt.dataset) ;
opt.rootPath = fullfile(opt.data_split, opt.dataset) ;
%----------------------------------------------------------------------------------------------------------
%                   loading a pre-trained cnn model, for example: vgg-16
%-----------------------------------------------------------------------------------------------------------
% Initialize a network with pre-trained models foe features extraction
if strcmp(opt.model_type,'matconvnet')
    fprintf('loading a pre-trained cnn model, ...');
    switch opt.model
        case 'VggNet_16'
            opt.net_path = [opt.model_dir '/imagenet-vgg-verydeep-16.mat'];
        case 'VggNet_19'  
            opt.net_path = [opt.model_dir '/imagenet-vgg-verydeep-19.mat'];    
    end
    
    tic;
    net = load(opt.net_path);
    net = vl_simplenn_tidy(net);
    time = toc;
    fprintf(' time: %.2f seconds.\n', time);
    
    for l = 1:numel(net.layers)
        if strcmp(net.layers{l}.name, opt.cnn_layer)
            break;
        end
    end
    net.layers(l+1:end) = [];
    
    if numel(opt.gpu_id)>=1
        gpuDevice(opt.gpu_id);
        net = vl_simplenn_move(net,'gpu');
    end
    vl_simplenn_display(net);
    
    for l = numel(net.layers):-1:1
        if strcmp(net.layers{l}.type, 'conv')
            dim_cnn = size(net.layers{l}.weights{1},4);
            break;
        end
    end   
end


opt.expPath = fullfile(opt.rootPath,[opt.model,'-',opt.encode,'-',...
    num2str(opt.numWords),'-SP-',num2str(numel(opt.spatial)),...
    '-Norm-',opt.norm]);

if ~exist(opt.expPath,'dir')
    vl_xmkdir(opt.expPath);
end
opt.imdbPath = fullfile(opt.rootPath, 'imdb.mat') ;
opt.diaryPath = fullfile(opt.expPath,strcat('dspv5',opt.dataset,'diary.txt')) ;

Fid=fopen(opt.diaryPath,'a');
str = sprintf('\n  Start: %s\n',datestr(clock));
fprintf(Fid,str);
fprintf(str);
% ---------------------------------------------------------------------------------------------------------
%                                          Get image database
% ---------------------------------------------------------------------------------------------------------
if exist(opt.imdbPath,'file')
    fprintf('#load data split\n');
    imdb = load(opt.imdbPath);
else
    fprintf('#get a random data split(train data and test data)\n');
    switch opt.dataset
        case 'Scene15', imdb =setupScene15(opt.datasetDir,'lite',opt.lite, 'seed', opt.seed);
        case 'Indoor67', imdb = setupScene67(opt.datasetDir, 'lite', opt.lite) ;
        case 'caltech101', imdb = setupCaltech256(opt.datasetDir, 'lite', opt.lite, ...
                'variant', 'caltech101', 'seed', opt.seed) ;
        case 'caltech256', imdb = setupCaltech256(opt.datasetDir, 'lite', opt.lite, 'seed', opt.seed) ;
        case 'voc07', imdb = setupVoc(opt.datasetDir, 'lite', opt.lite, 'edition', '2007') ;
        case 'voc12', imdb = setupVoc12(opt.datasetDir, 'lite', opt.lite, 'edition', '2012') ;
        case 'SUN397', imdb = setupSun397(opt.datasetDir,opt.split,'lite', opt.lite) ;
        case 'Stanford40', imdb = setupStanford40(opt.datasetDir, 'lite', opt.lite, 'seed', opt.seed) ;
        case 'CUB_200_2011', imdb = setupCUB(opt.datasetDir, 'lite', opt.lite,'version','original');
        case 'CUB_200_2011_R', imdb = setupCUB(opt.datasetDir, 'lite', opt.lite,'version','crop');
        case 'Stanford_Cars', imdb = setupStanford_cars(opt.datasetDir, 'lite', opt.lite);
        case 'Stanford_Cars_R', imdb = setupStanford_cars(opt.datasetDir, 'lite', opt.lite);
        case 'Oxford_flowers',  imdb = setupOxford_flowers(opt.datasetDir,'lite', opt.lite);
        case 'qq_pic', imdb = setupQQpic(opt.datasetDir, 'lite', opt.lite) ;
        case 'imagenet12', imdb = cnn_imagenet_setup_data('dataDir', opt.datasetDir, 'lite');
            
        otherwise, error('Unknown dataset type.') ;
    end
    save(opt.imdbPath, '-struct', 'imdb') ;
end

if isfield(imdb.images, 'class')%'class'
    classRange = unique(imdb.images.class);
else
    opt.classifier = 'vlfeat';
    classRange = 1:numel(imdb.classes.imageIds) ;
end

switch  opt.train_test_set
    case 'train-val'
        train_id = find(imdb.images.set ==1);
        test_id = find(imdb.images.set == 2);
    case 'train-test'
        train_id = find(imdb.images.set ==1);
        test_id = find(imdb.images.set == 3);
    case 'trainval-test'
        train_id = find(imdb.images.set <=2);
        test_id = find(imdb.images.set == 3);
end
train_test_sets = strsplit(opt.train_test_set, '-');

num_train = length(train_id);
num_test = length(test_id);
num_class = numel(classRange) ;
%----------------------------------------------------------------------------------------------------------
%                            Create codebook
%----------------------------------------------------------------------------------------------------------
str = fullfile(opt.expPath,[opt.norm,'-codes-',strrep(num2str(opt.imgsize),' ','-'),'.mat']);
fprintf('%s \n',str);

% step1: sampling
% stratified sampling
train_imgs = fullfile(imdb.imageDir, imdb.images.name(train_id));
if isfield(imdb.images, 'class')
    train_label = imdb.images.class(train_id);
else
    train_label = [];
end

sam_feats = [];
switch opt.encode
    case {'FV','VLAD','D3'}
        tic;
        % sampling
         num_samtrain =  min(opt.num_samtrain, num_train);
         if isfield(imdb.images, 'class')%'class'    for single label
            num_avgclass =  floor(num_samtrain/ num_class);
            sub_ind = cell(num_class);
            for c =1:num_class
                ind = find(train_label ==c);
                randn('state', opt.seed) ;
                rand('state', opt.seed) ;
                sub_ind{c} = vl_colsubset(ind, min(num_avgclass, length(ind)));
            end
         else         % for multi-label
             sub_ind{1} = vl_colsubset(train_id, num_samtrain);
        end
        
        sam_feats = get_sam_feats(net,train_imgs(cat(2, sub_ind{:})),...
            'imgsize', opt.imgsize, ...
            'batch_size', opt.batch_size,...
            'interpolation', opt.interpolation,...
            'keepAspect', opt.keepAspect,...
            'gpu_id', opt.gpu_id,...
            'norm', opt.norm);%);
        sam_time = toc;     
end
% step2: build codebook by k-means or GMM
fprintf('#create codebook for %s...',opt.encode);
tic;
codes = get_codebook(sam_feats, dim_cnn, ...
    'PCA_energy', opt.PCA_energy,...
    'encodes', opt.encode,...
    'seed', opt.seed ,...
    'numWords', opt.numWords,...
    'spatial', opt.spatial,...
    'pre_model', opt.model);
codetime= toc;

save(str,'codes','-v7.3');
clear sam_feats

str = sprintf('# %s, Pre_model:%s , CNN_layer: %s, Classifier: %s, Scale:%s, Encodes:%s, Norm:%s, k=%d\n',...
opt.dataset,opt.model,opt.cnn_layer, opt.classifier, strrep(num2str(opt.imgsize),' ','-'),opt.encode, opt.norm, opt.numWords);
fprintf(Fid,str);
fprintf(str);
str = sprintf('# num_train:%d, num_test:%d, num_class:%d, dim_feat:%d\n',num_train,num_test,num_class, codes.dim_feat);
fprintf(Fid,str);
fprintf(str);


fprintf('Sampling:%.2f s, Codebook:%.2f s',sam_time,codetime);
str = sprintf('# Time,Sampling:%.2f s, Codebook:%.2f s',sam_time,codetime);
fprintf(Fid,str);
%-----------------------------------------------------------------------------------------------------
%                             extract DSP features for train data
%-----------------------------------------------------------------------------------------------------
fprintf('extracting deep cnn feats with the %s\n',opt.model);

train_feat_file = strcat(train_test_sets{1},strrep(num2str(opt.imgsize),' ','-'),'.bin');% train features file
train_feat_path = fullfile(opt.expPath,train_feat_file);                % train features path

if exist(train_feat_path,'file')
    system(['rm ',train_feat_path]);
end
tic;
write_dsp_feats(net,codes, train_imgs, train_label, train_feat_path,...
    'imgsize', opt.imgsize, ...
    'interpolation', opt.interpolation,...
    'keepAspect', opt.keepAspect,...
    'gpu_id', opt.gpu_id,...
    'norm', opt.norm);
time = toc;
fprintf('the time is %.2f s', time);
str = sprintf(', dsp feats(training):%.2f s',time);
fprintf(Fid,str);
%-------------------------------------------------------------------------------------------------
%                         extract DSP feaures for test or val data
%-------------------------------------------------------------------------------------------------
test_feat_file = strcat(train_test_sets{2},strrep(num2str(opt.imgsize),' ','-'),'.bin');
test_feat_path = fullfile(opt.expPath,test_feat_file);
test_imgs = fullfile(imdb.imageDir,imdb.images.name(test_id));

if isfield(imdb.images, 'class')%'class'
    test_label = imdb.images.class(test_id);
else
    test_label = [];
end

tic;
if exist(test_feat_path,'file')
    system(['rm ',test_feat_path]);
end
tic;
write_dsp_feats(net,codes,test_imgs,test_label,test_feat_path,...
    'imgsize', opt.imgsize, ...
    'interpolation', opt.interpolation,...
    'keepAspect', opt.keepAspect,...
    'gpu_id', opt.gpu_id,...
    'norm', opt.norm);
time = toc;
fprintf('the time is %.2f s, ', time);
str = sprintf(', dsp feats(testing) :%.2f s',time);
fprintf(Fid,str);
%------------------------------------------------------------------------------------------------------
%                                train svm model via Liblinear or VLfeat
%-----------------------------------------------------------------------------------------------------
% train
fprintf('#Training linear svm classifier...');
tic;
switch opt.classifier
    case 'liblinear'
        svmmodel_name = strcat(opt.train_test_set,strrep(num2str(opt.imgsize),' ','-'),'.bin.model');
        svmmodel_path = fullfile(opt.expPath,svmmodel_name);
        system(['time  ./train_dense   -c 1 ',train_feat_path, '  ', svmmodel_path]);
    case 'vlfeat'
        % apply kernel maps
        opt.kernel = 'linear';
        opts.C = 1;
        lambda = 1 / (opts.C*numel(train_id)) ;
        par = {'Solver', 'sdca', 'Verbose', ...
            'BiasMultiplier', 1, ...
            'Epsilon', 0.001, ...
            'MaxNumIterations', 100 * numel(train_id)} ;
        
        w = cell(1, numel(classRange)) ;
        b = cell(1, numel(classRange)) ;
        
        
        % fread dsp feats for training data
        f = fopen(train_feat_path,'r');
        num_train = fread(f,1,'int');
        dim_train = fread(f,1,'int');
        
        if isfield(imdb.images, 'class')
            train_feats = single(zeros(dim_train, num_train));
            for n = 1:num_train
                train_label(n) = fread(f,1,'int');
                train_feats(:,n) = fread(f,dim_train,'float');
            end
        else
            train_feats = fread(f,[dim_train,num_train],'float');
        end
        fclose(f);
        
        for c = 1:numel(classRange)
            if isfield(imdb.images, 'class')
                y = 2 * (imdb.images.class == classRange(c)) - 1 ;
            else
                y = - ones(1, numel(imdb.images.id)) ;
                [~,loc] = ismember(imdb.classes.imageIds{classRange(c)}, imdb.images.id) ;
                y(loc) = 1 - imdb.classes.difficult{classRange(c)} ;
            end
            if all(y <= 0), continue ; end
            sub_train_label = y(train_id);
            [w{c},b{c}] = vl_svmtrain(train_feats, sub_train_label, lambda, par{:}) ;
        end
end

svmtime = toc;
fprintf('time: %.2f s \n',svmtime);

str = sprintf(', training svm:%.2f s',svmtime);
fprintf(Fid,str);

% test
fprintf('#Evaluatting classification performance for test data...\n');
switch opt.classifier
    case 'liblinear'
        predfile = fullfile(opt.expPath, ['preds_label',strrep(num2str(opt.imgsize),' ','-'),'.txt']);
        if exist(predfile,'file')
            system(['rm  ',predfile]);
        end
        system(['time ./predict_dense ', test_feat_path,'  ', svmmodel_path,'  ',predfile]);
        pred_time = toc;
        fprintf(Fid,', pred_svm: %.2f s\n',pred_time);
        preds = textread(predfile,'','delimiter',',');
    case 'vlfeat'
        f = fopen(test_feat_path,'r');
        num_test = fread(f,1,'int');
        dim_test = fread(f,1,'int');
        
        if isfield(imdb.images, 'class')
            test_feats = single(zeros(dim_test, num_test));
            for n = 1:num_train
                test_label(n) = fread(f,1,'int');
                test_feats(:,n) = fread(f,dim_test,'float');
            end
        else
            test_feats = fread(f,[dim_test, num_test],'float');
        end
        fclose(f);
        
        for c = 1:numel(classRange)
            if isfield(imdb.images, 'class')
                y = 2 * (imdb.images.class == classRange(c)) - 1 ;
            else
                y = - ones(1, numel(imdb.images.id)) ;
                [~,loc] = ismember(imdb.classes.imageIds{classRange(c)}, imdb.images.id) ;
                y(loc) = 1 - imdb.classes.difficult{classRange(c)} ;
            end
            if all(y <= 0), continue ; end
            sub_test_label = y(test_id);
            scores{c} = w{c}' * test_feats + b{c} ;
            
            [~,~,info] = vl_pr(sub_test_label, scores{c}) ;
            ap(c) = info.ap ;
            ap11(c) = info.ap_interp_11 ;
            
            fprintf(Fid,'class %s AP %.2f; AP 11 %.2f \n', num2str(classRange(c)), ...
                ap(c) * 100, ap11(c)*100) ;
        end
        
        % confusion matrix (can be computed only if each image has only one label)
        Scores = cat(1,scores{:}) ;
        
        if isfield(imdb.images, 'class')
            [~,max_ind] = max(Scores, [], 1) ;
            preds = max_ind';
        end
end

% confusion matrix (can be computed only if each image has only one label)
if isfield(imdb.images, 'class')
    cmat = confusionmat(test_label', preds(:,1));
    meanAcc = sum(diag(cmat))./sum(cmat(:));
    meanRecall = mean(diag(cmat)./sum(cmat,2));
    Result = sprintf('# meanAcc: %.2f%%, meanRecall: %.2f%%\n',100*meanAcc,100*meanRecall);
    
    figure(1) ; clf ;
    imagesc(cmat) ; 
    axis square ;
    title(Result) ;
    vl_printsize(1) ;
    print('-dpdf', fullfile(opt.expPath, [opt.norm,'-codes-',num2str(opt.imgsize), 'result-confusion.pdf'])) ;
    print('-djpeg', fullfile(opt.expPath, [opt.norm,'-codes-',num2str(opt.imgsize), 'result-confusion.jpg'])) ;
    close all;
else
    Result = sprintf('mAP: %.2f%%; mAP-11: %.2f%%\n', mean(ap)*100, mean(ap11)*100);
    figure(2) ;
    clf ;
    bar(ap * 100) ;
    title(Result) ;
    ylabel('AP %%') ; xlabel('class') ;
    grid on ;
    vl_printsize(1) ;
    ylim([0 100]) ;
    print('-dpdf', fullfile(opt.expPath,[opt.norm,'-codes-',num2str(opt.imgsize),'result-ap.pdf'])) ;
    save(fullfile(opt.expPath,'result.mat'), ...
        'scores', 'ap', 'ap11', 'classRange', 'opt') ;
end
fprintf('\n %s \n',Result);
fprintf(Fid,'%s ',Result);
fprintf(Fid,' End: %s\n',datestr(clock));
fclose(Fid);



function write_dsp_feats(net,codes,imgs_path,imgs_label,feats_path, varargin)
opt.imgsize = 384;
opt.interpolation =  'bilinear';
opt.keepAspect = 'true';
opt.model_type = 'matconvnet';
opt.gpu_id = [];
opt.norm = 'fro';
opt = vl_argparse(opt, varargin) ;

num = numel(imgs_path);
dim = codes.dim_feat;


C = progress('init',['Extracting dsp feats for images, please wait...',': # num(s) ', num2str(num)]);
f1 = fopen(feats_path,'w');
fwrite(f1,num,'int'); % the number of samples
fwrite(f1,dim,'int'); % dimensions 
for n = 1:num
    img_path = imgs_path(n); % image
    if ~isempty(imgs_label)  %'class'
        img_label = imgs_label(n);
    end
    
    cnn_feat = get_cnn_feats(net, img_path,...
        'imgsize', opt.imgsize, ...
        'interpolation', opt.interpolation,...
        'keepAspect', opt.keepAspect,...
        'crop', false,...
        'gpu_id', opt.gpu_id);%
    dsp_feat = get_dsp_feats(cnn_feat,codes); % extract DSP feature
    % writting dsp feats and label to disk
    if ~isempty(imgs_label)%'class'
        dsp_label = img_label;
        fwrite(f1,dsp_label,'int'); % label
    end
    fwrite(f1,dsp_feat,'float'); % feature
    C = progress(C,n/num);
end
fclose(f1);


function feats = get_sam_feats(net, imgs_path, varargin)
opt.imgsize = 384;
opt.interpolation =  'bilinear';
opt.keepAspect = 'true';
opt.model_type = 'matconvnet';
opt.gpu_id = [];
opt.norm = 'fro';
opt.batch_size = 128;
opt = vl_argparse(opt, varargin) ;

num = numel(imgs_path);
tic;
C = progress('init',['Extracting cnn feats for train data,please wait...',': # num_train(s) ', num2str(num)]);
bn = 1;
for n = 1:opt.batch_size :num
    batch = n:min(n+opt.batch_size -1, num);
    img_path = imgs_path(batch)'; % image path
    cnn_feats = get_cnn_feats(net, img_path,...
        'imgsize', opt.imgsize, ...
        'interpolation', opt.interpolation,...
        'keepAspect', opt.keepAspect,...
        'crop', true,...
        'gpu_id', opt.gpu_id);%
    [h,w,c,d] = size(cnn_feats{1});
    tmp = permute(cnn_feats{1}, [1,2,4,3]);   
    cnn_bnfeats{bn,1} = reshape(tmp, h*w*d,c);
    bn = bn+1;
    C = progress(C,n/num);
end
feats = cat(1,cnn_bnfeats{:});
time = toc;
fprintf('the time is %.2f s\n',time);
