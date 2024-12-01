function [skel,node,link] = EnsureSkel(skel,num_nodes)
    k = 1;
    while(1)
        [~,node,link] = Skel2Graph3D(skel,k);
        if length(node)==num_nodes
           break
        end
        skel = Graph2Skel3D(node,link,size(skel,1),size(skel,2),size(skel,3));
        k = k+1;
    end
end

