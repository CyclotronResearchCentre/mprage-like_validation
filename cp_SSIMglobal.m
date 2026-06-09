function SSIM = cp_SSIMglobal(fn_ref, fn_tst, fn_msk)

% Function to calculate SSIM cooeficient between a pair of reference and
% test images.
%
% FORMAT
% SSIM = cp_SSIMglobal(fn_ref, fn_tst, fn_msk)
%
% INPUT
% fn_ref : single reference image filename
% fn_tst : test image(s)(as char array if multiple)
% fn_msk : mask image to apply on data
%
% OUTPUT
% SSIM
% 
% KEY FEATURE
%
% NOTE
%
% TO-DO's
%
% REFERENCCE
% Zhou W, Bovik Alan C, Sheikh Hamid R, Simoncelli EP. 
% Image quality assessment: from error visibility to structural similarity. 
% IEEE Trans Image Process. 2004; 13: 600-612.
% https://doi.org/10.1109/TIP.2003.819861
%_______________________________________________________________________
% Copyright (C) 2026 Cyclotron Research Centre

% Written by C. Phillips,
% Cyclotron Research Centre, University of Liege, Belgium

% Check input
% -----------

% Load data
% ---------
% Put ref-image into vector 'x' and tested-image(s) into matrix 'y'
v_ref = spm_read_vols(spm_vol(fn_ref));
x = v_ref(:);
n_tst = size(fn_tst,1)
v_tst = spm_read_vols(spm_vol(fn_tst));
y = reshape(v_tst,[numel(x) n_tst]);

% Mask out stuff
to_remove = (x==0) | (x<20) | (x>800) | any(y>4,2); % | (y<=0) | (y>1400);
x(to_remove)   = [];
y(to_remove,:) = [];

% x = rand(1000,1);
% y = rand(1000,5);
% n_tst = size(y,2);

x = x/800*4;

% Proceed with calculation
% ------------------------
% Calculate summary stats
mu_x = mean(x);
mu_y = mean(y);
sig_x = std(x);
sig_y = std(y);
tmp_cov = cov([x y]); 
sig_xy = tmp_cov(1,2:end);

% Check all test images
SSIM = zeros(1,n_tst);
for ii = 1:n_tst
    dynmRange = 1;
%     dynmRange = min(max([x y(:,ii)])) - min(min([x y(:,ii)]));
    C = [(0.01*dynmRange)^2 (0.03*dynmRange)^2 ((0.03*dynmRange)^2)/2];
    l = ( 2*mu_x*mu_y(ii) + C(1) )   / ( mu_x^2+mu_y(ii)^2 + C(1) );
    c = ( 2*sig_x*sig_y(ii) + C(2) ) / ( sig_x^2+sig_y(ii)^2 + C(2) );
    s = ( sig_xy(ii) + C(3) )        / ( sig_x*sig_y(ii) + C(3));
    SSIM(ii) = l.*c.*s;
end

end
