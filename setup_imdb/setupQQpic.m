function  imdb = setupQQpic(datasetDir,varargin)
opts.lite = false ;
opts = vl_argparse(opts, varargin) ;

fileID = fopen(fullfile(datasetDir,'/qq_pic_select.txt'),'r');
dataArray= textscan(fileID,  '%s%f%[^\n\r]', 'Delimiter',  ',',  'ReturnOnError', false);
fclose(fileID);
dataArray(2) = cellfun(@(x) num2cell(x), dataArray(2), 'UniformOutput', false);
qqpicselect = [dataArray{1:end-1}];

classes_names = qqpicselect(:,1)';
classes_num = qqpicselect(:,2)';

image_path = fullfile(datasetDir,'/hxc/*.jpg');
images_name1 = read_images_name(image_path,'hxc');

image_path = fullfile(datasetDir,'/zdd/*.jpg');
images_name2 = read_images_name(image_path,'zdd');

image_path =fullfile(datasetDir,'/zl/*.jpg');
images_name3 = read_images_name(image_path,'zl');

imdb.images.id = [] ;
imdb.images.set = uint8([]) ;
imdb.images.name = {} ;
imdb.meta.sets = {'train', 'val', 'test'} ;
imdb.meta.classes = classes_names;
imdb.imageDir = fullfile(datasetDir) ;

imdb.images.name =[ images_name1 images_name2 images_name3];
imdb.images.id = 1:numel(imdb.images.name);
imdb.images.set = [ones(1,numel(images_name1)) 2*ones(1,numel(images_name2))  3*ones(1,numel(images_name3))];


imdb.classes.imageIds =  cell(1,100);
imdb.classes.difficult = cell(1,100);
for i=1:100
    imageIds= [];
    for j=1:numel(imdb.images.name)
        pos = strfind(imdb.images.name{1,j},'#');
        for k =1:numel(pos)-1
            temp_name = imdb.images.name{1,j}(pos(k)+1:pos(k+1)-1);
            if strcmp(classes_names{1,i} ,temp_name)
                imageIds  =  [imageIds,j];
            end
            clear temp_name
        end
    end
    imdb.classes.imageIds{1,i}= imageIds;
    imdb.classes.difficult{1,i} =zeros(1,numel(imageIds));
    fprintf('the %dth class includes %d images....\n',i,numel(imageIds));
end

if opts.lite
    ok = {} ;
    for c = 1:3
        trainIds = intersect(imdb.images.id(imdb.images.set == 1), imdb.classes.imageIds{c}) ;
        testIds = intersect(imdb.images.id(imdb.images.set == 3), imdb.classes.imageIds{c}) ;
        
        ok{end+1} = vl_colsubset(find(ismember(imdb.images.id, trainIds)), 5) ;
        ok{end+1} = vl_colsubset(find(ismember(imdb.images.id, testIds)), 5) ;
    end
    ok = unique(cat(2, ok{:})) ;
    imdb.meta.classes = imdb.meta.classes(1:3) ;
    imdb.classes.imageIds = imdb.classes.imageIds(1:3) ;
    imdb.classes.difficult = imdb.classes.difficult(1:3) ;
    imdb.images.id = imdb.images.id(ok) ;
    imdb.images.name = imdb.images.name(ok) ;
    imdb.images.set = imdb.images.set(ok) ;
    for c = 1:3
        ok = ismember(imdb.classes.imageIds{c}, imdb.images.id) ;
        imdb.classes.imageIds{c} = imdb.classes.imageIds{c}(ok) ;
        imdb.classes.difficult{c} = imdb.classes.difficult{c}(ok) ;
    end
end
end

function  images_name = read_images_name(path,str)
images_file = dir(path);
for i=1:numel(images_file)
    images_name{1,i} = strcat(str,'/',images_file(i,1).name);   
end
end
