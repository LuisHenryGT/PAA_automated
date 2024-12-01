function skel = GetSkel(Image,percent)
% custom skeletonization to ensure correct points
    
    dist = bwdist(~Image);
    values = dist(dist>1);
    Image2 = dist>prctile(values,percent); % need to make sure there are no spurs in the PA
    skel = Skeleton3D(Image2); % get skeleton using the PA cleaned of spurs

    % ratio = [];
    % for percent = 10:10:90
    %     Image2 = dist>prctile(values,percent); % need to make sure there are no spurs in the PA
    %     skel2 = Skeleton3D(Image2); % get skeleton using the PA cleaned of spurs
    %     ratio = cat(1,ratio,nnz(skel2)/nnz(skel));
    %     skel = skel2;
    % end


end