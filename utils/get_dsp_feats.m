% Function: extract DSP feature for all block by pooling with FV or VLAD 
% Author: Bin-Bin Gao (gaobb@lamda.nju.edu.cn) or (csgaobb@gmail.com)
% Created on 2015.04.28
% Last modified on 2015.04.28

function dsp_feats = get_dsp_feats(cnn_feat, codes)
spm_block = get_spm_block(cnn_feat, codes.spatial);
num_spm = numel(spm_block);
num_imgs =  size(spm_block{1,1},3);
dim_feats =  codes.dim_feat;
dsp_feats = single(zeros(num_imgs, dim_feats));
for n = 1:num_imgs
    feat = cell(1, num_spm);
    for m = 1:num_spm
        desc = spm_block{m}(:,:,n);
        feat{m} = encode_feat(desc, codes);
    end
    feat = cat(2,feat{:});
    dsp_feats(n,:) = feat./max(norm(feat),1e-12);
end
end

function spm_block = get_spm_block(cnn_feat, spatial)
spm_block_num = size(spatial, 2);
spm_block = cell(numel(cnn_feat),spm_block_num);

[h,w,c,n] = size(cnn_feat{1});
for i = 1:spm_block_num
    x1 = max(round(spatial(1,i)*w),1);
    y1 = max(round(spatial(2,i)*h),1);
    x2 = min(round(spatial(3,i)*w),w);
    y2 = min(round(spatial(4,i)*h),h);
    tmp = cnn_feat{1}(y1:y2,x1:x2,:,:); % sclae and spatial
    spm_block{1,i} = reshape(tmp,(y2-y1+1)*(x2-x1+1),c,n);
end
end


function [feat] = encode_feat(raw, codes)
% Function extract DSP feature  for per block
% by gaobb
% latest modify 2015-04-28
num = size(raw,1);
if codes.PCA_energy>0
    raw = raw - repmat(codes.mu,num,1); % center the raw features
end

switch codes.encodes
    case 'FV'
        feat = Fisher(raw,codes);
    case 'VLAD'
        feat = Vlad(raw,codes);
    case 'D3'
        feat = D3(raw,codes);   
    case 'MAX'
        feat = MaxPool(raw,codes);
    case 'AVG'
        feat = AvgPool(raw,codes);  
end
end

function maxv = MaxPool(feat,codes)
% create FV feature
if codes.PCA_energy>0
    temp = (feat*codes.lf)';
else
    temp = feat';
end
maxv = max(temp,[],2)';%Improved
end

function avgv = AvgPool(feat,codes)
% create FV feature
if codes.PCA_energy>0
    temp = (feat*codes.lf)';
else
    temp = feat';
end
avgv = mean(temp,2)';%Improved
end

function fv = Fisher(feat,codes)
% create FV feature
if codes.PCA_energy>0
    temp = (feat*codes.lf)';
else
    temp = feat';
end
fv = vl_fisher(temp,codes.kmeans,codes.std,codes.priors,'Improved')';%Improved
end


function vlad = Vlad(feat,codes)
% create VLAD feature
if codes.PCA_energy>0
    temp = (feat*codes.lf)';
else
    temp = feat';
end
nn = vl_kdtreequery(codes.kdtree,codes.kmeans',temp);
assignments = zeros(size(codes.kmeans,1),size(temp,2),'single');
assignments(sub2ind(size(assignments),nn,1:length(nn)))= 1;

vlad = vl_vlad(temp,codes.kmeans',assignments,'SquareRoot')';
vlad = vlad./max(norm(vlad),1e-12);
end

function d3 = D3(feat,codes)
% create D3 feature
if codes.PCA_energy>0
    temp = (feat*codes.lf)';
else
    temp = feat';
end

n = size(temp,2);
d = size(temp,1);
codebook = codes.kmeans';
stdev = codes.std';

k = size(codes.kmeans',2);
freq = zeros(k,1);
mu = zeros(d,k,'single');
[~, words] = min(vl_alldist2(codes.kmeans',temp),[],1);
sigma2 = zeros(d,k,'single');
temp = (temp - codebook(:,words)) ./ stdev(:,words);
for id = 1:n
    pos = words(id);
    mu(:,pos) = mu(:,pos) + temp(:,id);
    sigma2(:,pos) = sigma2(:,pos) + temp(:,id).^2;
    freq(pos) = freq(pos) + 1;
end
for id = 1:k
    if freq(id)>0
        mu(:,id) = mu(:,id) / freq(id);
        t = sigma2(:,id) / freq(id) - mu(:,id).^2;
        t(t<1e-12) = 1e-12;
        sigma2(:,id) = sqrt(t);
    end
end
mu = erf( mu/sqrt(2)./(sigma2+1) );
for id = 1:k
    mu(:,id) = mu(:,id) / max(norm(mu(:,id)),1e-12);
end
d3 = mu(:)';
d3 = d3./max(norm(d3),1e-12);
end
