function imdb = setupCUB(datasetDir, varargin)
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


% Construct image database imdb structure
imdb.meta.sets = {'train', 'val', 'test'} ;
tt_file = fullfile(datasetDir, 'train_test_split.txt');

fid = fopen(tt_file);
tt_id = textscan(fid,'%d%d') ;
fclose(fid);


img_list_file = fullfile(datasetDir, 'images.txt');
fid = fopen(img_list_file);
img_list = textscan(fid,'%d%s') ;
fclose(fid);

img_label_file = fullfile(datasetDir, 'image_class_labels.txt');
fid = fopen(img_label_file);
img_label = textscan(fid,'%d%d') ;
fclose(fid);

img_bbox_file = fullfile(datasetDir, 'bounding_boxes.txt');
fid = fopen(img_bbox_file);
img_bbox = textscan(fid,'%d%f%f%f%f') ;
fclose(fid);


switch opts.version
    case 'original'
         imdb.imageDir = fullfile(datasetDir,'images');
    case 'crop'
         imdb.imageDir = fullfile(datasetDir,'images_crop');
end

imdb.images.id = 1:numel(img_list{1,2}) ;
imdb.images.name = img_list{1,2}';
imdb.images.set = double(tt_id{1,2}');
imdb.images.set(imdb.images.set ==0) = 2;
imdb.images.class = double(img_label{1,2}');
imdb.images.bbox = cat(2,img_bbox{:})';

if opts.lite
  ok = {} ;
  for c = 1:5
    ok{end+1} = vl_colsubset(find(imdb.images.class == c & imdb.images.set == 1), 5) ;
    ok{end+1} = vl_colsubset(find(imdb.images.class == c & imdb.images.set == 2), 5) ;
  end
  ok = cat(2, ok{:}) ;
  imdb.images.id = imdb.images.id(ok) ;
  imdb.images.name = imdb.images.name(ok) ;
  imdb.images.set = imdb.images.set(ok) ;
  imdb.images.class = imdb.images.class(ok) ;
  imdb.images.bbox = imdb.images.bbox(ok) ;
end

end



