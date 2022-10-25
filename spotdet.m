function [out] = spotdet (img, threshold, os)

% spotdet: spots detector, find local maximum pixels that maybe the center of 2d-gaussian type spots, designed for spot-detection/tracking package
% may filter the less bright pixel(s) if two or more local maximum pixels are within the range of the object scale (os)
% NOTE: large patches or stripes may be improperly detected, since spotdet may be used for detecting different scales of spots 
%(consider an extreme situation that os may ranges from 5 to 15), erasion of large patches or stripes will probably miss larger spots,
%so keep a clear spot image, spotdet will be more accurate and fast

% INPUT parameters
%	img: 2d single channel image with a certain type, usually denoised by band-pass filter or some other filters equal to that if the S/N of image
%		 is not good 
%	threshold: (scalar), if a pixel intensity is larger than this parameter, spotdet will treat the pixel as a spot center candicate 
%			   the value of threshold may influence the running speed of spotdet, however, speed and resolution are always mutually-exclusive
%	os: (scalar), object scale, preset value of the pixel scale of intersted object; usually considered as an odd

% OUTPUT parameters
%	out: n-by-4 array contains x- and y- coordinations (infact, these are row and column numbers) of spot centers (out(:,1) and out(:,2)), 
%	     integrated spot intensities (out(:,3)), and object scale flag (out(:,4))

% Inspired by Eric R. Dufresne, Yale University
% Written by Shen Wang, Sep. 12th, 2018, in HUST

%% Check if os is an odd
if os <= 0 || ~mod(os, 2) || os ~= fix(os)
	error('object size should be an positive odd.');
end

img = double(img);
ind = find(img > threshold);
len_ind = length(ind);

if ~len_ind
	disp('no spots were found at current object scale.');
	return
end

[row, col] = size(img);

%% Iteration style, abandoned
%{
temp_coord = zeros(len_ind, 2);
for j = 1:len_ind
	t_1 = mod(ind, row);
	if ~t_1
		break;
	end
	temp_coord(j, 2) = mod(ind, row);
	temp_coord(j, 1) = 1 + floor(ind/row);
end
%}

%% convert index to xy coordination; row_num as (:,2), col_num as (:,1)
temp_coord = zeros(len_ind, 2);
temp_coord = [1 + floor(ind/row), mod(ind, row)];

%% remove the detection of last row 
zero_x_ind = ~temp_coord(:, 2);
temp_coord(zero_x_ind, :) = [];

%% remove the detection of boundaries, boundary is floor(os/2)
r = floor(os/2);
bdry_indy = temp_coord(:, 1) <= r | temp_coord(:, 1) >= row-r+1;
temp_coord(bdry_indy, :) = [];
bdry_indx = temp_coord(:, 2) <= r | temp_coord(:, 2) >= col-r+1;
temp_coord(bdry_indx, :) = [];

%% create spot-scale mask
mask = zeros(os);
mask(r+1, r+1) = 1;
mask_bw = im2bw(mask);
SE = strel('disk', r, 0);
mask_bw = imdilate(mask_bw, SE);
mask = double(mask_bw);
mask2 = mask;
mask2(os, r+1) = 0;

%% find local maximum pixel around os 
spot_window = zeros(os);
[num, ch] = size(temp_coord);
xycoord = [];
for j = 1:num
	spot_window = img(temp_coord(j, 2)-r:temp_coord(j, 2)+r, temp_coord(j, 1)-r:temp_coord(j, 1)+r);
	spot_window_pmsk = spot_window.*mask2;
	[~, indcol] = max(max(spot_window_pmsk));
	[~, indrow] = max(spot_window_pmsk(:, indcol));
	%% convert inside-window xy-coordinates to global xy-coordinates 
	g_row = temp_coord(j, 2) + indrow - r;
	g_col = temp_coord(j, 1) + indcol - r;
	xycoord = [xycoord, [g_row, g_col]'];
end

%{
%% test flag

xycoord_tmp = [];
[num, ch] = size(xycoord);
for j = 1:num
	spot_window = img(xycoord(j, 1)-r:xycoord(j, 1)+r, xycoord(j, 2)-r:xycoord(j, 2)+r);
	spot_window_pmsk = spot_window.*mask2;
	[value, indcol] = max(max(spot_window_pmsk));
	[value, indrow] = max(spot_window_pmsk(:, indcol));
	%% convert inside-window xy-coordinates to global xy-coordinates 
	g_row = xycoord(j, 1) + indrow - (r + 1);
	g_col = xycoord(j, 2) + indcol - (r + 1);
	xycoord_tmp = [xycoord_tmp, [g_row, g_col]'];
end
xycoord = [];
xycoord = xycoord_tmp;

%% test flag 
%}

%{
%% deleted for using muiti-object scale  

if isempty(xycoord)
	error('no spots were found, probably caused by heavy density of spots or large os input.');
end

%}

%% row_num as (:,1), col_num as (:,2)
xycoord = xycoord';
xycoord = unique(xycoord, 'rows');

%{
%% delete for multi-size object

%% integrate intensities of spots, and create output
[nspot, ch2] = size(xycoord);
res = xycoord;
res(:, end+1) = 0;
spot_window2 = zeros(os);
for i = 1:nspot
	spot_window2 = img(xycoord(i, 1)-r:xycoord(i, 1)+r, xycoord(i, 2)-r:xycoord(i, 2)+r);
	spot_window2_pmsk = spot_window2.*mask;
	int_den = sum(sum(spot_window2_pmsk));
	res(i, 3) = int_den;
end
out = res;

%}

%% remove greater-than-os detections
[nspot, ch2] = size(xycoord);
img_pnt = zeros(row, col);
for i = 1:nspot
	img_pnt(xycoord(i, 1), xycoord(i, 2)) = 1;
end
img_pnt_bw = im2bw(img_pnt);
CC = bwconncomp(img_pnt_bw);
len_CC = length(CC.PixelIdxList);
xycoord_re = [];
for j2 = 1:len_CC
	if numel(CC.PixelIdxList{j2}) ~= 1
		continue;
	end
	xycoord_re = [xycoord_re, [mod(CC.PixelIdxList{j2}, row), 1 + floor(CC.PixelIdxList{j2}/row)]'];
end

res = xycoord_re';

if ~isempty(res)
    %% remove potential in-boundary detections 
    ind_exd_row = res(:, 1) <= r | res(:, 1) > (row - r);
    res(ind_exd_row, :) = [];
    ind_exd_col = res(:, 2) <= r | res(:, 2) > (col - r);
    res(ind_exd_col, :) = [];

    %% integrate intensities of spots
    [nspot2, ch3] = size(res);
    res(:, end+1) = 0;

    spot_window2 = zeros(os);

    for i2 = 1:nspot2
        spot_window2 = img(res(i2, 1)-r:res(i2, 1)+r, res(i2, 2)-r:res(i2, 2)+r);
        spot_window2_pmsk = spot_window2.*mask;
        int_den = sum(sum(spot_window2_pmsk));
        res(i2, 3) = int_den;
    end

    %% insert objective scale flag as the last column of output
    res(:, 4) = os;

    out = res;
    
else
    
    out = res;
    
end


