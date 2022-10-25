clear;

file_list = dir(strcat('*.nd2')); 

file_num = length(file_list);

res = [];

spacing_row = [NaN, NaN, NaN, NaN];

for i = 1:file_num
 
	file_img = file_list(i).name;

	img = nd2readsingle(file_img);

	imwrite(img, [strtok(file_img,'.'), '.tif']);

	bkgd_level = bkgdsampling(img, 5);

	%% bp parameters determined at 221020, use WP_45_0(lip)
	img_bp = bpfilter(img, 0, 7, bkgd_level);

	%% spotdet threshold parameter-300 determined at 221020, tested by WP_45_0(lip) and 3KP_45_0(lip)
	out = spotmulsz_batch3(img_bp, 300);

	if i == 1
		res = vertcat(res, out);
	else
		res = vertcat(res, spacing_row, out);
	end

end

xlswrite('det_res.xls', res);
