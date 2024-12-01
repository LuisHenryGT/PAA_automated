function Segment_Normals = FindSegmentNormals(Segment_Skeleton,Segment,skeleton_radius,point_radius)
% uses the voronoi covariance measure to obtain the cross section
% orientation of every skeleton point of segment 
    
    % voronoi assignments for every skeleton point of current segment
    [~,minpairindex] = min(pdist2(Segment_Skeleton,Segment),[],1); % find all the distances between every skeleton point to every tree point and their corresponding minimum skeleton point

    % create the voronoi cells: assign every skeleton point of the current segment its closest treepoint counterpart 
    Closest_Tree_Point_Indices = [];
    for h = 1:length(Segment_Skeleton)
        Closest_Tree_Point_Indices{h,1} = Segment((minpairindex==h),:);
    end

    for Skeleton_Point_Number = 1:length(Segment_Skeleton)

        P = Segment_Skeleton(Skeleton_Point_Number,:); % extract point 

        skeletonpairdistance = pdist2(P,Segment_Skeleton); % find distance between point to all other points on segment
        skeletonpointstoconsider = find(skeletonpairdistance<skeleton_radius); % only extract skeleton points within DOI

        total_sum = 0; % reset total sum
        for m = 1:length(skeletonpointstoconsider) % iterate through all skeleton points in DOI
            j = skeletonpointstoconsider(m); % the index of the skeleton point in consideration
            for k = 1:size(Closest_Tree_Point_Indices{j,1},1) % for all points in voronoi cell
                if pdist2(Closest_Tree_Point_Indices{j,1}(k,:),P) < point_radius % if point in voronoi cell is within the point boundary
                   diff = Closest_Tree_Point_Indices{j,1}(k,:) - Segment_Skeleton(j,:); % diff between voronoi cell point to its corresponding voronoi site
                   diff_t = diff'; % transpose
                   product = diff_t*diff; % matrix multiplication, covariance calculation means multiplying a matrix by its transpose
                   total_sum = total_sum+product; % sum across all considered points and all voronoi cells within the DOI
                end
            end
        end

        [V,D] = eig(total_sum); % find the eigenvectors and values of the VCM
        [~,I] = maxk(D(:),2); % find the locations of the max 2 eigenvalues
        if length(I) == 2
            [~,col] = ind2sub([3,3],I); % convert to subscript locations
            v1 = V(:,col(1)); % extract largest eigenvector - direction 1 of orthogonal plane
            v2 = V(:,col(2)); % extract second largest eigenvector - direction 2 of orthogonal plane
            n = cross(v1,v2); % cross them to find the planes normal
            n = n/norm(n); % normalize to a unit vector 
            %Segment_Normals(Skeleton_Point_Number,:) = AdjustNormal(n)';
            Segment_Normals(Skeleton_Point_Number,:) = n';
        else
            Segment_Normals(Skeleton_Point_Number,:) = [];
        end
    end

end
