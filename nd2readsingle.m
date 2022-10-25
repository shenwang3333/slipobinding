function im = nd2readsingle(filename)

finfo = nd2finfo(filename);

im = zeros(finfo.img_width, finfo.img_height, 'uint16');

fid = fopen(filename, 'r');
fseek(fid, finfo.file_structure(strncmp('ImageDataSeq', ...
  {finfo.file_structure(:).nameAttribute}, 12)).dataStartPos, 'bof');


for ii = 1: finfo.img_height
    temp = reshape(fread(fid, finfo.ch_count * finfo.img_width, '*uint16'),...
          [finfo.ch_count finfo.img_width]);
    im(:, ii) = temp(1, :);
end 

fclose(fid);

im = permute(im, [2 1]);

for j = 1:4
  im(1, j) = im(1, 5);
end
