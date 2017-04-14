function codes = get_codebook(feats, dim_cnn, varargin)

opt.PCA_energy = 0;
opt.encodes = 'FV';
opt.seed = 1;
opt.numWords = 2;
opt.spatial = '0X0';
opt.pre_model = 'VggNet_16';
opt = vl_argparse(opt, varargin) ;

tic;
codes = [];
if opt.PCA_energy>0
    codes.mu = mean(feats);
    feats = feats - repmat(codes.mu,size(feats,1),1); % center all features
    [temp , ~, latent] = princomp(feats);
    score = cumsum(latent)/sum(latent);
    opt.PCA_dim = min(find(score>=opt.PCA_energy));
    codes.lf = temp(:,1:opt.PCA_dim); % PCA load factors
    fprintf('# PCA features reserved energy: %.2f%% with %d features\n',score(opt.PCA_dim)*100,opt.PCA_dim);

    temp = (feats*codes.lf)'; % do PCA to the features
    
else
    temp = feats';
end
codes.PCA_energy = opt.PCA_energy;
codes.PCA_dim = size(feats,2);
codes.lf = single(zeros(size(feats,2),size(feats,2)));
codes.encodes = opt.encodes;
switch opt.encodes
    case 'FV'
        vl_twister('state', opt.seed) ;
        if 1
        v = var(feats)' ;
        [codes.kmeans, codes.std, codes.priors] = vl_gmm(feats',opt.numWords,'verbose', ...
                 'Initialization', 'kmeans', ...
                 'CovarianceBound', double(max(v)*0.0001), ...
                 'NumRepetitions', 1);
        else
            addpath lib/yael/matlab
            [a,b,c] = ...
                yael_gmm(feats', opt.numWords, 'verbose', 2) ;
            codes.priors = single(a) ;
            codes.kmeans = single(b) ;
            codes.std = single(c) ;
        end
    case {'VLAD','D3'}
        [kmc, c] = vl_kmeans(feats',opt.numWords,'verbose', 'algorithm', 'elkan'); % build a codebook without PCA
        codes.kmeans = kmc';
        codes.kdtree = vl_kdtreebuild(codes.kmeans');    
        
        codes.std = single(zeros(size(codes.kmeans)));
        for i=1:size(codes.std,1)
            t = temp(:,c==i);
            codes.std(i,:) = std(t,1,2)';
        end
    otherwise
end
fprintf('# Features clustered into codewords.\n');
elapsed = toc;
fprintf('# %s codebook generated in %f seconds.\n',opt.encodes,elapsed);

spatial1 = [];
spatial2 = [];
%opt.layouts = {'0x0','1x1'};%'2x2','3x3'};
for i = 1:numel(opt.spatial)
    t = sscanf(opt.spatial{i},'%dx%d') ;
    m = t(1) ;
    n = t(2) ;
    
    xt = linspace(0,1,2*n+3);
    yt = linspace(0,1,2*m+3);
    
    x_1 = xt(1:2:end);
    y_1 = yt(1:2:end);
    
    
    [x,y] = meshgrid(...
        x_1, ...
        y_1) ;
    
    x1 = x(1:end-1,1:end-1) ;
    y1 = y(1:end-1,1:end-1) ;
    x2 = x(2:end,2:end) ;
    y2 = y(2:end,2:end) ;
    
    spatial1 = cat(2, spatial1, ...
        [x1(:)' ;
        y1(:)' ;
        x2(:)' ;
        y2(:)'] ) ;
    
    
    x_2 = yt(2:2:end);
    y_2 = yt(2:2:end);
    
    
    [x,y] = meshgrid(...
        x_2, ...
        y_2) ;
    x1 = x(1:end-1,1:end-1) ;
    y1 = y(1:end-1,1:end-1) ;
    x2 = x(2:end,2:end) ;
    y2 = y(2:end,2:end) ;
    
    temp = [x1(:)' ;
        y1(:)' ;
        x2(:)' ;
        y2(:)'];   
    spatial2 = cat(2, spatial2, ...
        temp) ;   
end
codes.spatial = [spatial1,spatial2];

spm_block_num = size(codes.spatial, 2);
switch opt.encodes
    case 'FV'
        codes.dim_feat = opt.numWords*2*dim_cnn*spm_block_num;%;%
    case 'VLAD'
        codes.dim_feat = opt.numWords*dim_cnn*spm_block_num;%;%*
    case 'D3'
        codes.dim_feat = opt.numWords*dim_cnn*spm_block_num;%
    case {'MAX','AVG'}
        codes.dim_feat = dim_cnn*spm_block_num;%
end
