function  feat = get_norm_cnn_feats(cnn_feats,norm_style)
s = size(cnn_feats);
if length(s) <= 3
    s(4) = 1;
end
feat = single(zeros(s));
switch norm_style   
    case 'fro'    % Frobenius normlization
        for n = 1:s(4)
            tmp_feat = cnn_feats(:,:,:,n);
            tmp_feat = reshape(tmp_feat,s(1)*s(2), s(3));
            feat(:,:,:,n) = cnn_feats(:,:,:,n)./max(norm(tmp_feat,'fro'), 1e-12);
        end
    case 'l2' % l2 normalization
        for n = 1:s(4)
            for h = 1:s(1)
                for w = 1:s(2)
                    factor = norm(squeeze(cnn_feats(h,w,:,n)));
                    feat(h,w,:,n) =  cnn_feats(h,w,:,n)./max(factor, 1e-12);
                end
            end
        end     
    case 'matrix' % Matrix normalization
        for n = 1:s(4)
            tmp_feat = cnn_feats(:,:,:,n);
            tmp_feat = reshape(tmp_feat, s(1)*s(2), s(3));
            feat(:,:,:,n) = cnn_feats(:,:,:,n)./max(norm(tmp_feat,2), 1e-12);
        end    
    case '0-1'
        for n = 1:s(4)
            for h = 1:s(1)
                for w = 1:s(2)
                    factor = max(cnn_feats(h,w,:,n));
                    feat(h,w,:,n) =  cnn_feats(h,w,:,n)./max(factor, 1e-12);
                end
            end
        end
    case 'none'
        feat = cnn_feats;
end