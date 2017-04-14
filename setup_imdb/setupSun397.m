function imdb = setupSun397(datasetDir, split, varargin)
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
opts = vl_argparse(opts, varargin) ;
% Download and unpack
if exist(fullfile(datasetDir, 'k', 'kindergarden_classroom'))
  % ok
else
  vl_xmkdir(datasetDir) ;

  url = 'http://groups.csail.mit.edu/vision/SUN1old/SUN397.tar' ;
  train_test_ImagesUrl = 'http://vision.princeton.edu/projects/2010/SUN/download/Partitions.zip'; 
  fprintf('Downloading SUN397 data to ''%s''. This will take a while.', datasetDir) ;
 
  untar(url, datasetDir) ;
  untar(train_test_ImagesUrl, datasetDir) ;
end

% Construct image database imdb structure
imdb.meta.sets = {'train', 'val', 'test'} ;
if split<10
    train_name = strcat('Training_0',num2str(split),'.txt');
    test_name = strcat('Testing_0',num2str(split),'.txt');
else
    train_name = strcat('Training_',num2str(split),'.txt');
    test_name = strcat('Testing_',num2str(split),'.txt');
end
trainNames = textread(fullfile(datasetDir, 'Partitions',train_name),'%s','delimiter','\n') ;
testNames = textread(fullfile(datasetDir, 'Partitions',test_name),'%s','delimiter','\n') ;

names = [trainNames; testNames]' ;
sets = [ones(1,numel(trainNames)), 2*ones(1,numel(testNames))] ;
imdb.images.id = 1:numel(names) ;
[imdb.images.name,perm] = sort(names) ;
imdb.images.set = sets(perm) ;

parfor i = 1:numel(names)
    position = find(imdb.images.name{1,i}=='/');
    a{i} = imdb.images.name{1,i}(position(2)+1:position(end)-1);
    a{i} (a{i}=='/') ='-';
end
[imdb.meta.classes, ~, imdb.images.class] = unique(a) ;
imdb.images.class = imdb.images.class(:)' ;
imdb.imageDir = fullfile(datasetDir) ;


if opts.lite
  ok = {} ;
  for c = 1:10
    ok{end+1} = vl_colsubset(find(imdb.images.class == c & imdb.images.set == 1), 5) ;
    ok{end+1} = vl_colsubset(find(imdb.images.class == c & imdb.images.set == 2), 5) ;
  end
  ok = cat(2, ok{:}) ;
  imdb.meta.classes = imdb.meta.classes(1:3) ;
  imdb.images.id = imdb.images.id(ok) ;
  imdb.images.name = imdb.images.name(ok) ;
  imdb.images.set = imdb.images.set(ok) ;
  imdb.images.class = imdb.images.class(ok) ;
end


