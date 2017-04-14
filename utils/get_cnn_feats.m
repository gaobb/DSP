function cnn_feats = get_cnn_feats(net, img_path, varargin)
opt.imgsize = 384;
opt.interpolation =  'bilinear';
opt.keepAspect = 'true';
opt.model_type = 'matconvnet';
opt.crop = true;
opts.numThreads = 8 ;
opt.gpu_id = [];
opt.norm = 'fro';
opt = vl_argparse(opt, varargin) ;

rgb_mean = mean(mean(net.meta.normalization.averageImage,1),2);

imt = cell(numel(img_path),1);
if opt.crop
    imgs = vl_imreadjpeg(img_path, 'NumThreads', opts.numThreads, ...
        'Interpolation', opt.interpolation, ...
        'Resize', [opt.imgsize, opt.imgsize],...
        'CropSize', [1,1],...
        'subtractAverage', rgb_mean,...
        'CropLocation', 'center');
else
    imgs = vl_imreadjpeg(img_path, 'NumThreads', opts.numThreads, ...
        'Interpolation', opt.interpolation, ...
        'Resize', opt.imgsize,...
        'subtractAverage', rgb_mean);
end
imt(:,1) = imgs;


imageSize = opt.imgsize;
for n = 1:numel(img_path)
    if isempty(imt{n,1}) | max(size(imt{n,1},1),size(imt{n,1},2)) >1120
        system(['convert ', img_path{1,n}, ' -colorspace RGB ', 'temp.jpg']);
        img = imread('temp.jpg');
        if size(img,3)==1
            img = repmat(img,[1 1 3]);
        end
        w = size(img,2) ;
        h = size(img,1) ;
        factor_thresh = min(1120./[h w]);
        
        factor = [imageSize/h,imageSize/w];
        
        if opt.keepAspect
            factor = min(max(factor),factor_thresh);
        end
        if any(abs(factor - 1) > 0.0001)
            img = imresize(img, ...
                'scale', factor, ...
                'method', opt.interpolation) ;
        end
        if opt.crop
            [h, w, c] = size(img);
            [longs, ind] = max([h,w]);
            indices = [0 longs-imageSize] + 1;
            
            center = floor(indices(2) / 2) + 1;
            if ind == 1
                img =  img(center:center+imageSize-1,:,:);
            else
                img =  img(:,center:center+imageSize-1,:);
            end
        end
        if strcmp(opt.model_type,'matconvnet')
            h = size(img,1) ;
            w = size(img,2) ;
            im_data = bsxfun(@minus, single(img), rgb_mean) ;
        end
        imt{n,1} = im_data;
    else
         if size(imt{n,1},3)==1
            imt{n,1} = repmat(imt{n,1},[1 1 3]);
         end
        
         
    end
end

% img = imgs{1};
% imshow(uint8(img))       
% im_data = get_img(img_path, rgb_mean, ...
%     'cnn_layer',opt.cnn_layer, 'scales', ...
%     opt.imgsize, 'interpolation', ...
%     opt.interpolation);
% feats = cell(num_scales,1);


if opt.crop
    input0{1} = cat(4,imt{:,1});
else
    input0 = imt;
end

cnn_feats = cell(numel(input0),1);
if strcmp(opt.model_type,'matconvnet')
    for bn =1:numel(input0)
        if numel(opt.gpu_id)>=1
            input_data = gpuArray(input0{bn});
        else 
            input_data = input0{bn}; 
        end
        res = vl_simplenn(net, input_data, [], [], ...
            'accumulate', false, ...
            'mode', 'test', ...
            'conserveMemory', true, ...
            'sync', false, ...
            'cudnn', true) ;
        feats = gather(res(end).x);
        % normliaztion
        cnn_feats{bn,1} = get_norm_cnn_feats(feats, opt.norm);
    end
end
