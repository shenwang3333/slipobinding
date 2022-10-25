clear;

cd prot;
file_list = dir(strcat('*.nd2')); 
cd ..;
cd lip;
file_list2 = dir(strcat('*.tif'));
cd ..;

file_num = length(file_list);

out_corrlst = [];
spacing_row = [NaN, NaN, NaN, NaN, NaN];

cvt_fac = 0.514856925

for i = 1:file_num
 
 	cd prot;

	file_img = file_list(i).name;

	img1 = nd2readsingle(file_img);

	imwrite(img1, [strtok(file_img,'.'), '.tif']);

	%%quite weak intensity, no need to add threshold in bpfilter
	% bkgd_level = bkgdsampling(img1, 5);
	%% bp parameters determined at 221020, (ns=0, os=3)use WP_45_0(prot)
	img_bp = bpfilter(img1, 0, 3);

	%% spotdet threshold parameter-50 determined at 221021, tested by WP_45_0(prot), 3KP_45_0(prot), 77P_45_0(prot);
	%% 35 for WF, tested by WF_45_0, WF_345_0, WF_0_0(prot)
	out_res1 = spotmulsz_batch3(img_bp, 35);

	%{
	if i == 1
		res1_temp = vertcat(res1_temp, out_res1);
	else
		res1_temp = vertcat(res1_temp, spacing_row, out_res1);
	end
	%}
	if ~isempty(out_res1)
		
		cd ..;
		cd lip;

		img2 = imread(file_list2(i).name);
		out_corrlst_temp = spotscorr_batch3(img1, img2, out_res1, cvt_fac);

		if i == 1
			out_corrlst = vertcat(out_corrlst, out_corrlst_temp);
		else
			out_corrlst = vertcat(out_corrlst, spacing_row, out_corrlst_temp);
		end

		cd ..

	else
		
		out_corrlst = vertcat(out_corrlst, spacing_row);

		cd ..

	end

end

xlswrite('det_corr.xls', out_corrlst);