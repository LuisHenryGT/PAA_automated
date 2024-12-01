function refined_mask = GetLargestArea(mask)

    refined_mask = zeros(size(mask));
    for i = 1:size(mask,3)
        if nnz(mask(:,:,i))
            slice = bwlabel(mask(:,:,i));
            areas = [regionprops(slice,'Area').Area];
            [~,index] = max(areas);
            refined_mask(:,:,i) = slice==index;
        end
    end

end

