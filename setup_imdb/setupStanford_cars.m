function imdb = setupStanford_cars(datasetDir, varargin)
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
% datasetDir = '/home/gaobb/mywork/SV3/image_data/Stanford_Cars/';
% Construct image database imdb structure
imdb.meta.sets = {'train', 'val', 'test'} ;
class_names = load(fullfile(datasetDir, 'devkit/cars_meta.mat'));
imdb.meta.classes = class_names.class_names;
train_file = load(fullfile(datasetDir, 'devkit/cars_train_annos.mat'));
test_file = load(fullfile(datasetDir, 'devkit/cars_test_annos_withlabels.mat'));

num_train = numel(train_file.annotations);
num_test = numel(test_file.annotations);

% switch opts.version
%     case 'original'
%         imdb.imageDir = fullfile(datasetDir);
%     case 'crop'
%         imdb.imageDir = fullfile(datasetDir);
% end

train_file = struct2cell(train_file.annotations');
test_file = struct2cell(test_file.annotations');

imdb.imageDir = fullfile(datasetDir);
imdb.images.id = 1:num_train+num_test;
imdb.images.name = [fullfile('cars_train',train_file(end,:)),fullfile('cars_test',test_file(end,:))];
imdb.images.set = [ones(1,num_train),2*ones(1,num_test)];
imdb.images.class = [cell2mat(train_file(5,:)),cell2mat(test_file(5,:))];
imdb.images.bbox = cell2mat([train_file(1:4,:),test_file(1:4,:)]);

if opts.lite
  ok = {} ;
  for c = 1:5
    ok{end+1} = vl_colsubset(find(imdb.images.class == c & imdb.images.set == 1), 5) ;
    ok{end+1} = vl_colsubset(find(imdb.images.class == c & imdb.images.set == 2), 5) ;
  end
  ok = cat(2, ok{:}) ;
  imdb.meta.classes = imdb.meta.classes(1:5) ;
  imdb.images.id = imdb.images.id(ok) ;
  imdb.images.name = imdb.images.name(ok) ;
  imdb.images.set = imdb.images.set(ok) ;
  imdb.images.class = imdb.images.class(ok) ;
  imdb.images.bbox = imdb.images.bbox(ok) ;
end
