function imdb = setupStanford40(datasetDir, varargin)
% SETUPVOC    Setup Stanford40 data
%   IMDB = SETUPVOC(DATASETDIR, 'EDITION', '2007') setups the
%   PASCAL VOC 2007 data. This is similar to SETUPGENERIC(), but adapted
%   to the peculiarities of this dataset. In particular, the
%   difficult image flag and the fact that multiple labels apply to
%   each image are supported.
%
%   Note that only the PASCAL VOC 2007 data comes with test images
%   and labels. For the other editions, setting up the test images
%   cannot be automatized due to restrictions in the distribution.
%
%   See also: SETUPGENERIC().

% Author: Andrea Vedaldi

% Copyright (C) 2013 Andrea Vedaldi
% All rights reserved.
%
% This file is part of the VLFeat library and is made available under
% the terms of the BSD license (see the COPYING file).

opts.autoDownload = false ;
opts.lite = false ;
opts.seed = 1 ;
opts = vl_argparse(opts, varargin) ;

% Download and unpack
vl_xmkdir(datasetDir) ;
if exist(fullfile(datasetDir, 'ImageSplits', 'actions.txt'))
    annoPath = fullfile(datasetDir, 'ImageSplits', 'actions.txt');
    [classes_names,classes_num] = textread(annoPath, '%s %s') ;
    classes_names(1,:) =[];
    classes_num(1,:) =[];
elseif opts.autoDownload
    urls = 'http://vision.stanford.edu/Datasets/Stanford40.zip' ;
    fprintf('Downloading Stanford40 data ''%s'' to ''%s\n''. This will take a while.', urls, datasetDir) ;
    untar(urls, datasetDir) ;
    datasetDir = fullfile(datasetDir, 'Stanford40') ;
else
    error('Stanford40 data not found in %s', datasetDir) ;
end

imdb.images.id = [] ;
imdb.images.set = uint8([]) ;
imdb.images.name = {} ;
imdb.meta.sets = {'train', 'val', 'test'} ;
imdb.meta.classes = classes_names' ;
imdb.imageDir = fullfile(datasetDir, 'JPEGImages') ;

% Construct image database imdb structure
images_names  ={};
classes ={};
sets = {};
for si = 1:numel(imdb.meta.sets)
    for ci = 1:length(imdb.meta.classes)
        setName = imdb.meta.sets{si} ;
        className = imdb.meta.classes{ci} ;
        annoPath = fullfile(datasetDir, 'ImageSplits', [className '_' setName '.txt']) ;
        if ~exist( annoPath)
            continue;%fprintf('%s:  no %s \n', mfilename, annoPath) ;
        else
            fprintf('%s: reading %s\n', mfilename, annoPath) ;
            names{ci} = textread(annoPath, '%s') ;
            images_names {end+1} =names{ci }';
            classes{end+1} = repmat(ci, 1, numel(names{ci})) ;
            sets{end+1} = repmat(si, 1, numel(names{ci})) ;
        end
    end
end
images_names = cat(2,images_names{:}) ;
images_classes = cat(2,classes{:}) ;
images_sets = cat(2,sets{:}) ;
images_ids = 1:numel(images_names) ;

ok = find(images_sets ~= 0) ;
imdb.images.id = images_ids(ok) ;
imdb.images.name =  images_names (ok) ;
imdb.images.set =  images_sets(ok) ;
imdb.images.class = images_classes(ok) ;

opts.numTrain = 100;
opts.numTest = 0;
opts.numVal = inf;

numClasses =numel(imdb.meta.classes);
classes = imdb.images.class;
for c = 1:numClasses
  sel = find(classes == c) ;
  randn('state', opts.seed) ;
  rand('state', opts.seed) ;
  selTrain = vl_colsubset(sel, opts.numTrain) ;
  selVal = vl_colsubset(setdiff(sel, selTrain), opts.numVal) ;
  selTest = vl_colsubset(setdiff(sel, [selTrain selVal]), opts.numTest) ;
  Sets(selTrain) = 1 ;
  Sets(selVal) = 2 ;
  Sets(selTest) = 3 ;
end

ok = find(Sets ~= 0) ;
imdb.images.id =imdb.images.id(ok) ;
imdb.images.name = imdb.images.name(ok) ;
imdb.images.set = Sets(ok) ;
imdb.images.class = classes(ok) ;

if opts.lite
    ok = {} ;
    for c = 1:5
        ok{end+1} = vl_colsubset(find(imdb.images.class == c & imdb.images.set == 1), 5) ;
        ok{end+1} = vl_colsubset(find(imdb.images.class == c & imdb.images.set == 2), 5) ;
        ok{end+1} = vl_colsubset(find(imdb.images.class == c & imdb.images.set == 3), 5) ;
    end
    ok = cat(2, ok{:}) ;
    imdb.meta.classes = imdb.meta.classes(1:3) ;
    imdb.images.id = imdb.images.id(ok) ;
    imdb.images.name = imdb.images.name(ok) ;
    imdb.images.set = imdb.images.set(ok) ;
    imdb.images.class = imdb.images.class(ok) ;
end



