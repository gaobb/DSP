function imdb = setupStanford_dogs(datasetDir, varargin)
% SETUPSCENE67    Setup MIT Scene 67 dataset
%    This is similar to SETUPGENERIC(), with modifications to setup
%    MIT Scene 67 according to the standard evaluation protocols. The
%    function supports only the LITE option.
%
%    See: SETUPGENERIC().

% Author: Andrea Vedaldi

% Copyright (C) 2013 Andrea Vedaldi
% All rights reserved.
%
% This file is part of the VLFeat library and is made available under
% the terms of the BSD license (see the COPYING file).

opts.lite = false ;
opts.version = 'original';
opts = vl_argparse(opts, varargin) ;

% datasetDir = '/home/gaobb/mywork/SV3/image_data/Stanford_dogs/';

% Construct image database imdb structure
imdb.meta.sets = {'train', 'val', 'test'} ;
train_file = load(fullfile(datasetDir, 'train_list.mat'));
test_file = load(fullfile(datasetDir, 'te_list.mat'));
num_train = numel(train_file.file_list);
num_test = numel(test_file.file_list);

switch opts.version
    case 'original'
         imdb.imageDir = fullfile(datasetDir,'Images');
    case 'crop'
         imdb.imageDir = fullfile(datasetDir,'Images_crop');
end

imdb.images.id = 1:num_train+num_test;
imdb.images.name = [train_file.file_list',test_file.file_list'];
imdb.images.set = [ones(1,num_train),2*ones(1,num_test)];
imdb.images.class = [train_file.labels',test_file.labels'];
imdb.images.annotation = [train_file.annotation_list',test_file.annotation_list'];

if opts.lite
  ok = {} ;
  for c = 1:5
    ok{end+1} = vl_colsubset(find(imdb.images.class == c & imdb.images.set == 1), 5) ;
    ok{end+1} = vl_colsubset(find(imdb.images.class == c & imdb.images.set == 2), 5) ;
  end
  ok = cat(2, ok{:}) ;
%   imdb.meta.classes = imdb.meta.classes(1:3) ;
  imdb.images.id = imdb.images.id(ok) ;
  imdb.images.name = imdb.images.name(ok) ;
  imdb.images.set = imdb.images.set(ok) ;
  imdb.images.class = imdb.images.class(ok) ;
  imdb.images.bbox = imdb.images.bbox(ok) ;
end

for n =1:numel(imdb.images.name)
    img_name = imdb.images.name{1,n};
    img_path = fullfile(imdb.imageDir,img_name);
    
    im = imread(img_path);
    
    
    [h,w,c] = size(im);
    
    bbox = imdb.images.bbox(2:5,n);
    x1 = max(bbox(1),1);
    x2 = min(bbox(1)+bbox(3),w);
    
    y1 = max(bbox(2),2);
    y2 = min(bbox(2)+bbox(4),h);
    
    
    crop = im(y1:y2,x1:x2,:);
    crop_path = fullfile(imdb.imageDir,'images_crop',img_name);
    seq = strfind(crop_path,'/');
    if ~exist(fullfile(crop_path(1:seq(end))),'dir')
        mkdir(fullfile(crop_path(1:seq(end))));
    end
    imwrite(crop,crop_path);
%     figure
%     subplot(1,2,1)
%     imshow(im)
%     subplot(1,2,2)
%     imshow(im(y1:y2,x1:x2,:));
%     pause;
%     close all;
end



