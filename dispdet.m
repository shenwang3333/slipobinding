function [] = dispdet (img, res_det)

% dispdet: interactively display detections, which circles the detected spots on an original image

% INPUT parameters
%	img: the original image used for spot detection
%	res_det: n-by-4 array created by spotdet() or spotmulsz()

% OUTPUT parameters
%	[]: dispdet does not return any values or arrays, instead, it displays detections made by 
%		spotdet() or spotmulsz()

% Written by Shen Wang, Sep. 17th, 2018, in HUST

if isempty(res_det)
	error('no detections were found, please check the input. ');
end 

figure;
imagesc(img);
colormap(hot);
axis off;
colorbar;
title('Detections');
hold on;

nspot = length(res_det(:, 1));

%{
%% could not be accelarate when dealing with common small-dim image (etc, 512*512), removed  

uni_os = unique(res_det(:, 4));
len_uni_os = length(uni_os);

if len_uni_os ~= 1
	for i = 1:nspot
		rectangle('Position', [res_det(i, 2)-floor(res_det(i, 4)/2)-1, res_det(i, 1)-floor(res_det(i, 4)/2)-1 ...
		, res_det(i, 4), res_det(i, 4)], 'Curvature', [1, 1], 'EdgeColor', 'b');
	end
else
	for i = 1:nspot
		rectangle('Position', [res_det(i, 2)-floor(uni_os/2)-1, res_det(i, 1)-floor(uni_os/2)-1 ...
		, uni_os, uni_os], 'Curvature', [1, 1], 'EdgeColor', 'b');
	end
end
%}

for i = 1:nspot
	rectangle('Position', [res_det(i, 2)-floor(res_det(i, 4)/2)-1, res_det(i, 1)-floor(res_det(i, 4)/2)-1 ...
	, res_det(i, 4), res_det(i, 4)], 'Curvature', [1, 1], 'EdgeColor', 'r');
end