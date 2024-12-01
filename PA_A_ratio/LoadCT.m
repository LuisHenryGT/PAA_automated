%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
function [volume,spacing] = LoadCT(dicom_folder)
    dicom_file = dir(dicom_folder); % individual dicom directory
    info = dicominfo(fullfile(dicom_file(3).folder,dicom_file(3).name)); % get rescale slope and intercept to change values of HU to -1024 to 1024 range
    [volume,stat1,~] = dicomreadVolume(dicom_folder); % load in CT
    spacing = [stat1.PixelSpacings(1,1),stat1.PixelSpacings(1,2),median(abs(diff(stat1.PatientPositions(:,3))))];
    volume = int16(squeeze(volume));
    volume = volume.*info.RescaleSlope + info.RescaleIntercept; % already done before
    volume = imresize3(volume,size(volume).*spacing,'method','nearest'); % resize to 1x1x1
    volume(volume<-1024)=-1024; % anything below -1024 set to -1024 (background)
    volume(volume>1024)=1024; % anything below -1024 set to -1024 (background)
    % volume = rescale(volume,[-1024,1024],'InputMin',-1024,'InputMax',1024)
end