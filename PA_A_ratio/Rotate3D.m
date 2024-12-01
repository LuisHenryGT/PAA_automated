function volume_rotated = Rotate3D(volume,object)
% rotate object so that it is straight upwards, 3rd dimension must be axial
% volume is what to rotate
% object is frame of reference object that needs to be straight upwards

    orientation = regionprops3(double(object),'Orientation').Orientation;
    if orientation(1)>0
       orientation(1) = orientation(1)-90; 
    else
       orientation(1) = orientation(1)+90;
    end
    if orientation(3)>0
       orientation(3) = orientation(3)-90; 
    else
       orientation(3) = orientation(3)+90;
    end
    if orientation(3)>0
        orientation = -orientation;
    end
    a = imrotate3(volume,orientation(3),[1,0,0],"nearest","loose");
    b = imrotate3(a,-orientation(2),[0,1,0],"nearest","loose");
    volume_rotated = imrotate3(b,-orientation(1),[0,0,1],"nearest","loose");

    %volume_edge = edge3(object1,"approxcanny",0.5);
    %volume_rotated = imrotate3(object1,-orientation(1),[0,0,1],"nearest","loose");
    %volume_rotated = imrotate3(volume_rotated,-orientation(2),[0,1,0],"nearest","loose");
    %volume_rotated = imrotate3(object,-orientation(3),[0,0,1],"nearest","loose");
    %volume_rotated_edge = edge3(volume_rotated,"approxcanny",0.5);
    %[x,y,z] = ind2sub(size(volume),find(volume==1));
    %[x2,y2,z2] = ind2sub(size(volume_rotated),find(volume_rotated==1));
    %pcshowpair(pointCloud([x,y,z]),pointCloud([x2,y2,z2]))

    %pcshow(pointCloud([x,y,z]))

end

