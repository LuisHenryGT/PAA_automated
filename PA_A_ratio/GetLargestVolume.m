function refined_mask = GetLargestVolume(mask,n)

    props = regionprops3(mask,'VoxelIdxList');
    region_sizes = cellfun(@length,props.VoxelIdxList);
    [~,index] = maxk(region_sizes,n);
    refined_mask = zeros(size(mask));
    for i = 1:length(index)
        refined_mask(props.VoxelIdxList{index(i)})=1;
    end

end

