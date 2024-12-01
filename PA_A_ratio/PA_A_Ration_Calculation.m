clear; clc; close all;

%% User Configuration Section
% Define the base path to the CT scans and TotalSegmentator results
basePath = 'INSERT_PATH_TO_YOUR_DATA'; % Example: 'C:\Your\Directory\Here'
patientID = 'INSERT_PATIENT_ID'; % Example: '7856 - 7856'

% Construct the paths dynamically
ctScanPath = 'C:\Your\Directory\Here';
aortaPath = 'C:\Your\Directory\Here';
pulmonaryArteryPath = 'C:\Your\Directory\Here';
leftVentriclePath = 'C:\Your\Directory\Here';
rightVentriclePath = 'C:\Your\Directory\Here';

%% Load CT Volume
volume = LoadCT(ctScanPath);

%% Load and Process Segments
% Aorta
A = niftiread(aortaPath);
A = imresize3(imrotate3(uint8(A), 90, [0 0 1]), size(volume), 'method', 'nearest');
A = GetLargestVolume(imclose(A, strel('sphere', 5)), 1);

% Pulmonary Artery
PA = niftiread(pulmonaryArteryPath);
PA = imresize3(imrotate3(uint8(PA), 90, [0 0 1]), size(volume), 'method', 'nearest');
PA = GetLargestVolume(imclose(PA, strel('sphere', 5)), 1);

% Left Ventricle
LV = niftiread(leftVentriclePath);
LV = imresize3(imrotate3(uint8(LV), 90, [0 0 1]), size(volume), 'method', 'nearest');
LV = GetLargestVolume(imclose(LV, strel('sphere', 5)), 1);
LV = imclose(A | LV, strel('sphere', 5)) & ~A;

% Right Ventricle
RV = niftiread(rightVentriclePath);
RV = imresize3(imrotate3(uint8(RV), 90, [0 0 1]), size(volume), 'method', 'nearest');
RV = GetLargestVolume(imclose(RV, strel('sphere', 5)), 1);
RV = imclose(PA | RV, strel('sphere', 5)) & ~PA;

% Visualize segments
volumeSegmenter(volume, A + 2 * PA);


%% isolate ascending aorta only one slice, when using the highchamber res the aorta is already segmented in two
Ascending_Aorta = A;
Ascending_Aorta = bwlabeln(Ascending_Aorta); %bwlabeln Function: Labels the connected components in the 3D binary volume 
volumes = round(regionprops3(Ascending_Aorta, 'Volume').Volume); %volumes: An array containing the volumes of each connected component in the labeled 3D volume.
%check how many components in volume due to Totalsegmentator either 1 or 2 aortas
if length(volumes) > 1
    [~, idx] = min(volumes); % idx: The index of the smallest connected component in the labeled 3D volume.
    Ascending_Aorta(Ascending_Aorta == idx) = 0; % Sets all voxels in the largest connected component to 0, effectively removing this component from the labeled 3D volume.
else
    Ascending_Aorta = A;
    num_objects = [];
    for k = 1:size(Ascending_Aorta,3) % find the slice where the asecnding arota and descending aorta meet
        num_objects(k) = length(unique(bwlabel(Ascending_Aorta(:,:,k))))-1;
    end
    num_objects(1:min(find(num_objects==2)))=NaN; %marks the elements from the beginning of num_objects up to (and including) the first occurrence of the value 2 as NaN.
    slice=min(find(num_objects==1)); %finds the first occurrence of the value 1 in num_objects after marking certain elements as NaN in the previous step
    Ascending_Aorta(:,:,slice-10:end)=0; % cut aorta 1cm below the aortic arch - this could be subject to change
    Ascending_Aorta = bwlabeln(Ascending_Aorta);
    volumes = round(regionprops3(Ascending_Aorta,'Volume').Volume);
    [~,idx] = max(volumes);
    Ascending_Aorta(Ascending_Aorta==idx) = 0;
end
%% Rotation
% find just the close part of the aorta and PA to the RV and LV then use that to rotate the aorta and pulmonary artery

Aorta_Overlap = (imdilate(LV,strel('sphere',5))&imdilate(Ascending_Aorta,strel('sphere',5)))&(LV|Ascending_Aorta);
PA_Overlap = (imdilate(RV,strel('sphere',5))&imdilate(PA,strel('sphere',5)))&(RV|PA);

PA_rotated = imopen(Rotate3D(PA,PA_Overlap),strel('sphere',1));

%% remove the bifurcation from the pulmonary aorta by skeletonizing to the point where we only have 1 branchpoint and 3 endpoints (4 nodes in total)
Image = regionprops3(PA_rotated>0,'Image').Image{1}; % make the computation region smaller to speed things up
skel = GetSkel(Image,60);
[skel,node,link] = EnsureSkel(skel,4); % ensure that skeleton is correct and there is 1 bp and 3 ep - 4 node
max_z = round(node(find([node.ep]==0)).comz);
mini_PA = Image(:,:,5:max_z-7); % cut 0.5 cm above the heart to 0.5 cm below the bifurcation, this could be subject to change
mini_PA = GetLargestVolume(mini_PA,1); % remove any leftover regions
%volumeSegmenter(double(mini_PA),skel(:,:,5:max_z-5))
skel2 = skel(:,:,5:max_z-5);

%% measure the diameters using regionprops3 - For AA
mini_AA = regionprops3(Ascending_Aorta>0,'Image').Image{1};
%mini_AA = permute(mini_AA,[3,2,1]); % get the correct dimension on 3rd axis
for k = 1:size(mini_AA,3)
    if nnz(mini_AA(:,:,k))
        props = regionprops(GetLargestArea(mini_AA(:,:,k)),'All');
        AA_stats{1}(k,:) = [props.EquivDiameter,props.MinorAxisLength,props.MajorAxisLength,...
                             props.MinFeretDiameter,props.MaxFeretDiameter,props.Circularity]; % regionprops gives you many different values, more than just the diameter
    else
        AA_stats{1}(k,:) = [NaN,NaN,NaN,NaN,NaN,NaN];
    end
end
AA_mean_med1 = mean(AA_stats{1}(:, 1));
%% measure the diameters using regionprops3 - For PA
for k = 1:size(mini_PA,3)
    if nnz(mini_PA(:,:,k))
        props = regionprops(GetLargestArea(mini_PA(:,:,k)),'All');
        PA_stats{1}(k,:) = [props.EquivDiameter,props.MinorAxisLength,props.MajorAxisLength,...
                             props.MinFeretDiameter,props.MaxFeretDiameter,props.Circularity];
    else
        PA_stats{1}(k,:) = [NaN,NaN,NaN,NaN,NaN,NaN];
    end
end
PA_mean_med1 = mean(PA_stats{1}(:, 1));
Ratio_method1 = PA_mean_med1/AA_mean_med1;

%% Compute AA diameter using bwdist method

dist_image = bwdist(~mini_AA); % get geodesic distance image
values = dist_image(dist_image>5); % remove very small values
threshold = prctile(values,99); % find 99% threshold, you can play with it
volumeSegmenter(dist_image,dist_image>threshold)
values = dist_image(dist_image>threshold);
AA_bwDiameter(1) = round(2*mean(values),1);

%% Compute PA diameter using bwdist method

dist_image = bwdist(~mini_PA); % get geodesic distance image
values = dist_image(dist_image>5); % remove very small values
threshold = prctile(values,99); % find 99% threshold, you can play with it
volumeSegmenter(dist_image,dist_image>threshold)
values = dist_image(dist_image>threshold);
PA_bwDiameter(1) = round(2*mean(values),1);
Ratio_method2 = PA_bwDiameter/AA_bwDiameter;

%% A measure the diameter using skeletonization then surface normal cuts (through voronoi normal estimation)
skel = GetSkel(mini_AA,80);
[skel,node,link] = EnsureSkel(skel,2); % ensure that skeleton is correct and there is 2 bp 
data = []; skel_data = [];
[data(:,1),data(:,2),data(:,3)] = ind2sub(size(mini_AA),find(mini_AA));
[skel_data(:,1),skel_data(:,2),skel_data(:,3)] = ind2sub(size(mini_AA),link.point);
Segment_Normals = FindSegmentNormals(skel_data,data,10,10);
B = {};
for k = 1:length(skel_data)
    B{k} = GetLargestArea(obliqueslice(mini_AA,skel_data(k,:),Segment_Normals(k,:)));
   % use region props to calculate the diameter of the oblique cuts
end
for k = 1:length(B)
    if nnz(B{k})
        props = regionprops(GetLargestArea(B{k}),'All');
        AA_stats_voronoi{1}(k,:) = [props.EquivDiameter,props.MinorAxisLength,props.MajorAxisLength,...
                             props.MinFeretDiameter,props.MaxFeretDiameter,props.Circularity];
    else
        AA_stats_voronoi{1}(k,:) = [NaN,NaN,NaN,NaN,NaN,NaN];
    end
end
AA_mean_med3 = mean(AA_stats_voronoi{1}(:, 1), 'omitnan');
%% PAA measure the diameter using skeletonization then surface normal cuts (through voronoi normal estimation)
skel2 = GetSkel(mini_PA,80);
[skel2,node,link] = EnsureSkel(skel2,2); % ensure that skeleton is correct and there is 2 bp 
data2 = []; skel2_data = [];
[data2(:,1),data2(:,2),data2(:,3)] = ind2sub(size(mini_PA),find(mini_PA));
[skel_data2(:,1),skel_data2(:,2),skel_data2(:,3)] = ind2sub(size(mini_PA),link.point);
Segment_Normals = FindSegmentNormals(skel_data2,data2,10,10);
B = {};
for k = 1:length(skel_data2)
    B{k} = GetLargestArea(obliqueslice(mini_PA,skel_data2(k,:),Segment_Normals(k,:)));
   % use region props to calculate the diameter of the oblique cuts
end
for k = 1:length(B)
    if nnz(B{k})
        props = regionprops(GetLargestArea(B{k}),'All');
        PA_stats_voronoi{1}(k,:) = [props.EquivDiameter,props.MinorAxisLength,props.MajorAxisLength,...
                             props.MinFeretDiameter,props.MaxFeretDiameter,props.Circularity];
    else
        PA_stats_voronoi{1}(k,:) = [NaN,NaN,NaN,NaN,NaN,NaN];
    end
end
PA_mean_med3 = 0; % so the T table works in case this doesn't
PA_mean_med3 = mean(PA_stats_voronoi{1}(:, 1), 'omitnan');
Ratio_method3 = PA_mean_med3/AA_mean_med3;

%% Data collection
patientIDString = string(patientID);
T = table(patientIDString, AA_mean_med1, PA_mean_med1, AA_bwDiameter, PA_bwDiameter, ...
          AA_mean_med3, PA_mean_med3, ...
          'VariableNames', {'patientID', 'AA_mean_med1', 'PA_mean_med1', 'AA_mean_med2', ...
                            'PA_mean_med2', 'AA_mean_med3', 'PA_mean_med3'});

%% explain
    %figure,montage(B)
    %volumeSegmenter(double(mini_AA),skel)

    % strictly for easy viewing purposes
    %figure,labelvolshow(mini_PA+2*skel2,'LabelOpacity',[0;0.03;1])
    %figure,labelvolshow(mini_AA+2*skel,'LabelOpacity',[0;0.03;1])

%Dimensions:
%Rows (65): Each row corresponds to an oblique slice generated perpendicular to the skeleton of the volume.
%Columns (6): Each column corresponds to a different morphological property of the largest connected component in that slice.
%Columns:
%Column 1: EquivDiameter - The diameter of a circle with the same area as the region.
%Column 2: MinorAxisLength - The length of the minor axis of the ellipse that has the same normalized second central moments as the region.
%Column 3: MajorAxisLength - The length of the major axis of the ellipse that has the same normalized second central moments as the region.
%Column 4: MinFeretDiameter - The smallest distance between two parallel lines tangent to the region.
%Column 5: MaxFeretDiameter - The largest distance between two parallel lines tangent to the region.
%Column 6: Circularity - A measure of how close the shape is to a perfect circle.