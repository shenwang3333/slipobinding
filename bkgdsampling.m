function bkgdlevel = bkgdsampling(img, sampling_num)

	[row, col] = size(img);

	bkgd_mat = zeros(4, sampling_num);

	for i = 1:sampling_num
		bkgd_mat(1, i) = img(1, i+4);
		bkgd_mat(2, i) = img(1, col-i-3);
		bkgd_mat(3, i) = img(row, i+4);
		bkgd_mat(4, i) = img(row, col-i-3);  
	end

	bkgdlevel = sum(sum(bkgd_mat))./(4*sampling_num);