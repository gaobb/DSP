% Function: obtain the SPM block images
% Input:
% cnn                   - original cnn feature
% pyramid_levl          - SPM levels
% Output:
% spm_block_cnn             - SPM block images
% spm_block_num    - number of spm blocks


% Function: obtain the SPM block images
% Input:
% I                           - original image
% pyramid_levl          - SPM levels
% Output:
% spm_block_cnn             - SPM block images
% spm_block_num    - number of spm blocks
% Author: Yang Xiao @ SCE NTU (hustcowboy@gmail.com)
% Created on 2012.6.7
% Last modified on 2012.6.7

function spm_block = get_spm_block(cnn_feat, subdivision)
spm_block_num = size(subdivision,2);
spm_block = cell(numel(cnn_feat),spm_block_num);

[h,w,c,n] = size(cnn_feat{1});
for i = 1:spm_block_num
    x1 = max(round(subdivision(1,i)*w),1);
    y1 = max(round(subdivision(2,i)*h),1);
    x2 = min(round(subdivision(3,i)*w),w);
    y2 = min(round(subdivision(4,i)*h),h);
    tmp = cnn_feat{1}(y1:y2,x1:x2,:,:); % sclae and spatial
    spm_block{1,i} = reshape(tmp,(y2-y1+1)*(x2-x1+1),c,n);
end

% spm_block = cell(1,spm_block_num);
% for i =1 :spm_block_num
%     tmp = spm_block_cnn(:,i);
%     spm_block{1,i} = cat(1,tmp{:});
% end
% 
























% spm_block_num = 1;      % number of patches in SPM
% for ii = 2:opt.pyramid_levl
%     if opt.spm_row_col==true
%         hii = ii; wii = ii;
%         spm_block_num = spm_block_num + hii*wii+(hii-1)*(wii-1);
%     elseif opt.spm_row == true
%         hii = ii; wii = 1;
%         spm_block_num = spm_block_num + hii*wii+(hii-1)*wii;
%     else
%         hii = 1;  wii = ii;
%         spm_block_num = spm_block_num + hii*wii+ hii*(wii-1);
%     end
% end
% 
% [h, w, c] = size(cnn);   % image size of the original image
% spm_block_cnn = cell(1, spm_block_num);
% 
% 
% % SPM block images size
% % block_h = floor(img_h / power(2, (pyramid_levl-1)));
% % block_w = floor(img_w / power(2, (pyramid_levl-1)));
% % 
% % % SPM block images
% % spm_block_cnn = cell(1, spm_block_num);
% % for ii = 1:spm_block_num
% %     spm_block_cnn{1,ii} = zeros(block_h, block_w);
% % end
% 
% % Obtain SPM block images
% block_counter = 1;
% temp = reshape(cnn,[],c);
% 
% % % 1.08.2015 by gaobb
% %  temp(temp>0 ) = 1;
% %  temp(temp<=0 ) = -1;
% 
% switch opt.norm
%     case 'matrix'
%         %matrix normalization
%         temp =  temp./max(norm(temp),1e-12);
%         % l2 normalization
%     case 'vector'
%         for  n =1:h*w
%             temp(n,:) = temp(n,:)./max(norm(temp(n,:)),1e-12);
%         end 
%     otherwise
% end
% 
% 
% if  opt.spm_row_col==true
%     block_counter = 1;
%     for ii = 1:opt.pyramid_levl
%         if ii == 1
%             spm_block_cnn{1,block_counter}  =  temp;
%             cnn = reshape(spm_block_cnn{1,block_counter},h,w,c);
%             block_counter = block_counter + 1;     
%         else
%             block_h_ori =  round(h / ii);
%             block_w_ori =  round(w / ii);
%            
%             
%             for jj = 1:ii
%                 for kk = 1:ii
%                     % left-top point of each block
%                     lt_point.y = block_h_ori*(kk-1) + 1;
%                     lt_point.x = block_w_ori*(jj-1) + 1;
%                     
%                     spm_block_cnn{1,block_counter} = reshape(cnn(lt_point.y:min(lt_point.y+block_h_ori-1,h),lt_point.x:min(lt_point.x+block_w_ori-1,w),:),[],c);
%                     block_counter = block_counter + 1;
%                 end
%             end
%             
%             for jj = 1:ii-1
%                 for kk = 1:ii-1
%                     % left-top point of each block
%                     lt_point.y = block_h_ori*(kk-1) + round(block_h_ori / 2);
%                     lt_point.x = block_w_ori*(jj-1) + round(block_w_ori / 2);
%                     
%                     spm_block_cnn{1,block_counter} = reshape(cnn(lt_point.y:min(lt_point.y+block_h_ori-1,h),lt_point.x:min(lt_point.x+block_w_ori-1,w),:),[],c);
%                     block_counter = block_counter + 1;
%                 end
%             end
%         end
%     end
% elseif  opt.spm_row == true
%     block_counter = 1;
%     for ii = 1:opt.pyramid_levl
%         if ii == 1
%             spm_block_cnn{1,block_counter}  =  temp;
%             cnn = reshape(spm_block_cnn{1,block_counter},h,w,c);
%             block_counter = block_counter + 1;
%         else
%             block_h_ori =  round(h / ii);
%             for kk = 1:ii
%                 % left-top point of each block
%                 lt_point.y = block_h_ori*(kk-1)+1;
%                 spm_block_cnn{1,block_counter} = reshape(cnn(lt_point.y:min(lt_point.y+block_h_ori-1,h),:,:),[],c);
%                 block_counter = block_counter + 1;
%             end
%             
%             for kk = 1:ii-1
%                 % left-top point of each block
%                 lt_point.y = block_h_ori*(kk-1) + round(block_h_ori / 2);
%                 spm_block_cnn{1,block_counter} = reshape(cnn(lt_point.y:min(lt_point.y+block_h_ori-1,h),:,:),[],c);
%                 block_counter = block_counter + 1;
%             end
%         end
%     end
% else
%     block_counter = 1;
%     for ii = 1:opt.pyramid_levl
%         if ii == 1
%             spm_block_cnn{1,block_counter}  =  temp;
%             cnn = reshape(spm_block_cnn{1,block_counter},h,w,c);
%             block_counter = block_counter + 1;
%         else
%             block_w_ori =  round(img_w / ii);
%             
%             for jj = 1:ii
%                 % left-top point of each block
%                 lt_point.x = block_w_ori*(jj-1) + 1;
%                 spm_block_cnn{1,block_counter} = reshape(cnn(:,lt_point.x:min(lt_point.x+block_w_ori-1,w),:),[],c);
%                 block_counter = block_counter + 1;
%             end
%         end
%         
%         for jj = 1:ii-1
%             % left-top point of each block
%             lt_point.x = block_w_ori*(jj-1) + round(block_w_ori / 2);
%             
%             spm_block_cnn{1,block_counter} = reshape(cnn(:,lt_point.x:min(lt_point.x+block_w_ori-1,w),:),[],c);
%             block_counter = block_counter + 1;
%         end
%     end
% end