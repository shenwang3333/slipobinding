function [out] = bpfilter(img, ns, os, threshold)

% band-pass filter for denoising 
% desinged as a pre-process procedure for point detection algorithm
% inspired by David G. Grier, The University of Chicago

% INPUT parameters
%	img: 2d single channel image with a certain type
%	ns: noise_scale, used for constructing gaussian kernel, can be set to 0 or FALSE
%	os [optional]: object_scale, typical dimension (e.g., length scale) of the object of interest
%	threshold[optional]: a threshold to set any negative or below-threshold pixels to 0

% OUTPUT parameters
%	out: processed image

% Written by Shen Wang, Aug 31st, 2018, in HUST

if nargin < 3, os = false; end
if nargin < 4, threshold = 0; end

normalize = @(x) x/sum(x);

img = double(img);
if ns == 0
	gaussian_k = 1;
else
	gaussian_k = normalize(exp(-((-ceil(5*ns):ceil(5*ns))/(2*ns)).^2));
end

if os
	bc_k = normalize(ones(1, length(-round(os):round(os))));
end

gconv = conv2(img', gaussian_k', 'same');
gconv = conv2(gconv', gaussian_k', 'same');

if os
	bconv = conv2(img', bc_k', 'same');
	bconv = conv2(bconv', bc_k', 'same');
	filtered_img = gconv - bconv;
else
	filtered_img = gconv;
end

mar = max(os, ceil(5*ns));
filtered_img(1:(round(mar)),:) = 0;
filtered_img((end - mar + 1):end, :) = 0;
filtered_img(:, 1:(round(mar))) = 0;
filtered_img(:, (end - mar + 1):end) = 0;

filtered_img(filtered_img < threshold) = 0;
out = filtered_img;