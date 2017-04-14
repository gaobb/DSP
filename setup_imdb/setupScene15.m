function imdb = setupScene15(datasetDir, varargin)
% SETUPSCENE67    Setup Flickr Material Dataset
%    This is similar to SETUPCALTECH101(), with modifications to setup
%    the Flickr Material Dataset accroding to the standard
%    evaluation protocols.
%
%    See: SETUPCALTECH101().

% Author: Andrea Vedaldi

% Copyright (C) 2013 Andrea Vedaldi
% All rights reserved.
%
% This file is part of the VLFeat library and is made available under
% the terms of the BSD license (see the COPYING file).

opt.lite = false ;
opt.seed = 1 ;
opt.numTrain = 100 ;
opt.numVal = inf;
opt.numTest =  0;
opt.autoDownload =true;
opt = vl_argparse(opt, varargin) ;

% Download and unpack
vl_xmkdir(datasetDir) ;
if exist(fullfile(datasetDir, 'bedroom'))
  % ok
elseif opt.autoDownload
  url = 'http://www-cvr.ai.uiuc.edu/ponce_grp/data/scene_categories/scene_categories.zip' ;
  fprintf('Downloading Scene15 data to ''%s''. This will take a while.', datasetDir) ;
  unzip(url, datasetDir) ;
else
  error(' Scene15 not found in %s', datasetDir) ;
end

imdb = setupGeneric(fullfile(datasetDir), ...
  'numTrain', opt.numTrain, 'numVal', opt.numVal , 'numTest', opt.numTest,  ...
  'expectedNumClasses', 15, ...
  'seed', opt.seed, 'lite', opt.lite) ;
