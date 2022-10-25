function [out] = spotmulsz_ver2forbatch (img, threshold_init)

% spotmulsz: spots detector for multi-size objects, contains an illustration of the detections, if 
%			 threshold_init == 1, spotmulsz is almost spotdet. Taking advantage of a self-adaptive 
%			 method, thresholds for different object scale do not need to be clarified one-by-one, 
%			 just provide an initial threshold for the smallest object, spotmulsz adopts an logar-
%			 ithmic increment to calculate the rest thresholds. This self-adaptive method will ac-
%		     celarate the running speed when using a wide variety of object scales

% INPUT parameters:
%	img: 2d single channel image with a certain type, usually denoised by band-pass filter or some 
%		 other filters equal to that if the S/N of image is not good 
%	threshold_init: (scalar), if a pixel intensity is larger than this parameter, spotmulsz will 
%					treat the pixel as a spot center candicate. For multi-size objects, threshold_init
%					is the threshold for the smallest object, the rests are calculated by self-adaptive
%					logarithmic increment method. Likewise, the value of threshold_init may influence 
%					the running speed of spotmulsz, however, speed and resolution are always mutually-
%					exclusive
%	os_num: (scalar), number of input object scales, the value should be a positive integer 
%	disp_flag: (scalar), if it is set to a non-zero value, spotmulsz will display the detection image

% OUTPUT parameters:
%	out: n-by-4 array contains x- and y- coordinations (infact, these are row and column numbers) of 
%		 spot centers (out(:,1) and out(:,2)), integrated spot intensities (out(:,3)), and object 
%		 scale flag (out(:,4))

% Written by Shen Wang, Sep 15th, 2018, in HUST
% Updated by Shen Wang, Oct 20th, 2022, in HUST

%{
if os_num ~= fix(os_num) || os_num <= 0 || ~isnumeric(os_num)
	error('input os_num should be an positive integer.');
end
%}

%{
%% abandoned, MATLAB does not support += or ++ operator

for j = 1:os_num
	os_tmp = input('please type in an object scale corresponding to your spot : ');
	if os_tmp <= 0 | ~mod(os_tmp, 2) | os_tmp ~= fix(os_tmp)
		disp('object size should be an positive odd. please retype.');
		os_num = os_num + 1;
	else
		os(j) = os_tmp;
	end
end
%}

os = [5,7,9,11];

%{
while 1
	os_tmp = input('please type in an object scale corresponding to your spot : ');
	if os_tmp <= 0 || ~mod(os_tmp, 2) || os_tmp ~= fix(os_tmp)
		disp('object size should be an positive odd. please retype.');
	else
		os = [os, os_tmp];
	end
	if length(os) == os_num;
		break;
	end
end
%}

%% self-adaptive threshold array based on input initial threshold and object scale 
os = sort(os);
len_os = length(os);

% if len_os ~= 1
	os_diff = os - os(1);
	threshold_decay_fold = log10(os_diff).*10;
	threshold_decay_fold(1) = 1;
	threshold = threshold_decay_fold.*threshold_init;
% else
%	threshold = threshold_init;
% end 


%% try to remove greater-than-max_value thresholds created by self-adaptive method
max_value = max(max(img));
ind_exceed = threshold >= max_value;
threshold(:, ind_exceed) = [];
len_threshold = length(threshold);

%{
%% replaced by using eval() 

name_str {};
for j = 1:len_os
	name_str{j} = strcat('out_', num2str(os(j)));
end

%}

%% run spotdet and concatenate the results
%% larger object scale group on the top of the res_int
res_int = [];
if len_threshold ~= 1
	for j = 1:len_threshold		
		%% previous attemption flag
		%% eval(['out_', num2str(len_os-j+1), '=', 'spotdet(img, threshold(len_os-j+1), os(len_os-j+1))']);
		%% eval([res_int '= vertcat(res_int, strcat(''out_'', num2str(len_os-j+1)))']);
		tmp_out = spotdet(img, threshold(len_threshold-j+1), os(len_threshold-j+1));
		if isempty(tmp_out)
			continue;
		end
		res_int = vertcat(res_int, tmp_out);
	end
else
	res_int = spotdet(img, threshold_init, os(1));
end


%% remove the same detections of different object scales, retain those using smaller objective scales
if len_threshold ~= 1 & ~isempty(res_int)
	[res_int_row, res_int_col] = size(res_int);
	res_int_coord = res_int(:, 1:2);
	[~, idx_uni] = unique(res_int_coord, 'rows');
	idx_res = [1:res_int_row];
	idx_del = setdiff(idx_res, idx_uni);

	res_int(idx_del, :) = [];
end

out = res_int;

%% display detection image

%{
%% replaced by a new packaged function dispdet() 

imagesc(img);
colormap(hot);
axis off;
colorbar;
title('Detections');
hold on;

nspot = length(res_int(:, 1));

for i = 1:nspot
	rectangle('Position', [res_int(i, 2)-floor(res_int(i, 4)/2)-1, res_int(i, 1)-floor(res_int(i, 4)/2)-1 ...
	, res_int(i, 4), res_int(i, 4)], 'Curvature', [1, 1], 'EdgeColor', 'b');
end

%}

%{
if disp_flag

	dispdet(img, res_int);

end
%}

