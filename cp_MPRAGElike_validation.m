%% Small bits of code about MPRAGE-like tool validation
%  Just testing on different dataset.

%% Initatialisation
spm('defaults','fmri'),
spm_jobman('initcfg')

% Some pathes
pth_MPRAGElike = 'D:\6_GitHubCRC_Git\mprage-like';
pth_dataCOFITAGEfull = 'C:\Users\christophe\OneDrive - Universite de Liege\bidsified_sub-all_mod-all';
% pth_data = 'D:\ccc_DATA\COFITAGE_MPRAGElike';
pth_data = 'J:\COFITAGE_MPRAGElike';

addpath(pth_MPRAGElike)

% Copy the data automatically, then unzip
% 
% Need to pick up 4 images per subjects:
% - 1st echo of MTw, PDw, T1w from MPM protocol
% - the MPRAGE, labelled as 'T1w'
% simple filter: *T1w*_echo-1*mag* *MTw*_echo-1*mag* *PDw*_echo-1*mag* *-1_T1w*

% MPM 1st echo of weighted images, pick both .nii.gz and .json files
fn_MTw = spm_select('FPListRec',pth_dataCOFITAGEfull,'^sub.*MTw.*_echo-1.*mag');
fn_PDw = spm_select('FPListRec',pth_dataCOFITAGEfull,'^sub.*PDw.*_echo-1.*mag');
fn_T1w = spm_select('FPListRec',pth_dataCOFITAGEfull,'^sub.*T1w.*_echo-1.*mag');
% MPRAGE T1w images, pick both .nii.gz and .json files
fn_MPR = spm_select('FPListRec',pth_dataCOFITAGEfull,'^sub.*_T1w\.');

% Note that 
% - some subjects have 2 runs for some MPM acquisition.
% - there are more subjects with MPRAGE than MPM data.

% Copy all files, keeping the folder structure but changing the root folder
fn_all = char(fn_MTw,fn_PDw,fn_T1w,fn_MPR);
nchar_path = numel(pth_dataCOFITAGEfull);
for ii=1:size(fn_all,1)
    fn_src = deblank(fn_all(ii,:));
    fn_tgt = fullfile(pth_data,fn_src(nchar_path+2:end));
    pth_tgt = spm_file(fn_tgt,'path');
    if ~exist(pth_tgt,'dir'), mkdir(pth_tgt), end
    copyfile(fn_src, fn_tgt);
end

% delete #70 and #71 to keep things simple
rmdir(fullfile(pth_data,'sub-070'),'s')
rmdir(fullfile(pth_data,'sub-071'),'s')

% Unzip all the NIfTI files
flag = struct(...
    'filt','^.*\.gz$',... % pick all .gz files
    'rec', true, ...      % act recursively
    'delOrig', true);    % delete original file after gunzipping 
fn_out = cp_gunzip(pth_data, flag);

%% Apply on data
% in local folder

% Collect the data, only from "run-1"
fn_MTw = spm_select('FPListRec',pth_data,'^sub.*MTw.*-1_echo-1.*mag_MPM.nii$');
fn_PDw = spm_select('FPListRec',pth_data,'^sub.*PDw.*-1_echo-1.*mag_MPM.nii$');
fn_T1w = spm_select('FPListRec',pth_data,'^sub.*T1w.*-1_echo-1.*mag_MPM.nii$');

% MPRAGE T1w images
fn_MPR = spm_select('FPListRec',pth_data,'^sub.*-1_T1w.nii$');

% % removing the troublesome subjects, for the moment
% to_remove = [70 71];
% fn_MTw(to_remove,:) = [];
% fn_PDw(to_remove,:) = [];
% fn_T1w(to_remove,:) = [];
% fn_MPR(to_remove,:) = [];

nfn_MTw = size(fn_MTw,1);
nfn_PDw = size(fn_PDw,1);
nfn_T1w = size(fn_T1w,1);
fn_MPR = fn_MPR(1:nfn_MTw,:)

if nfn_MTw~=nfn_PDw || nfn_MTw~=nfn_T1w
    error('Mismatched number of images.')
end

% % Check those having a "run-2"
% fn_MTw_r2 = spm_select('FPListRec',pth_data,'^sub.*MTw.*-2_echo-1.*mag_MPM.nii$');
% fn_PDw_r2 = spm_select('FPListRec',pth_data,'^sub.*PDw.*-2_echo-1.*mag_MPM.nii$');
% fn_T1w_r2 = spm_select('FPListRec',pth_data,'^sub.*T1w.*-2_echo-1.*mag_MPM.nii$');

% Apply MPRAGE-like
% Set parameters,
params = struct(...
    'lambda', [NaN 0 15 30 45 60 75 90], ...
    'indiv', false, ...
    'thresh', [0 5] , ... % 0 % [0 500]
    'coreg', false, ...
    'BIDSform', false);

% All lambda values to test 
% -> files labelled with lambda values + json file with lambda values
% params.lambda = [1 30 50 60 70 100 200 400];
% Find the optimal lambda value -> just json file with lambda value
% params.lambda = NaN;
% test case where 2 values of lambda are identical
% params.lambda = [60 60];
% Add value 0 and 150
% params.lambda = [0 150] ;
% params.lambda = [NaN 0 1 30 50 60 70 100 150 200]

% Apply on a bunch of subjects, collect 
% - file name sof generated images
% - estimated lambda value if returned
fn_MPRl = cell(nfn_MTw,1);
est_lambda = zeros(nfn_MTw,1);
fprintf('\nDealing with %d subjects: \n',nfn_MTw)
for i_sub = 1:nfn_MTw % 5 % 
    fprintf('\t %d / %d \n',i_sub,nfn_MTw)
    fn_in = char(fn_T1w(i_sub,:),fn_MTw(i_sub,:),fn_PDw(i_sub,:));
    if any(isnan(params.lambda))
        [fn_out,est_lambda(i_sub)] = hmri_MPRAGElike(fn_in,params);
    else
        fn_out = hmri_MPRAGElike(fn_in,params);
    end
    fn_MPRl{i_sub} = fn_out;
end
fprintf('\n')

val_lambda = est_lambda;
% val_lambda([70 71]) = [];
fn_val_lambda = 'val_lambda.tsv';
spm_save(fn_val_lambda,val_lambda)
% save val_lambda val_lambda

figure, hist(val_lambda)
fprintf('\nMean & std : %f +/- %f\n',mean(val_lambda), std(val_lambda))

% % Collect fn_MPRl data afterwards
% fn_MPRl = cell(nfn_MTw,1);
% for i_sub = 1:nfn_MTw
%     pth_i_sub = spm_file(fn_T1w(i_sub,:),'path');
%     fn_MPRl{i_sub} = spm_select('FPList',pth_i_sub, ...
%         '^sub.*MPRAGElike-.*\.nii$');
% end


%% Comparison using SSIM
% The point is to look at the similarity between the acquired T1w-MPRAGE
% and all the other MPRAGE-like images. Then one can check various aspects,
% using the acquired T1w-MPRAGE as the reference:
% - look at the SSIM values across the spectrum of lambda values,
% - look at the SSIM values, for each usbject, between the individually 
%   estimated/optimized lambda and the one that gives the larget SSIM on
%   average for the group.
% This requires all the images to be in the same *voxel* space, so the
% easiest is to coregister the acquired T1w-MPRAGE onto the original the
% 1st echo from the MPM T1w image.

% Coregister & reslice 
% --------------------
% Put the acquired T1w-MPRAGE image onto 1st echo from the MPM T1w image

% Define empty MatlabBatch
matlabbatch{1}.spm.spatial.coreg.estwrite.ref = {''};
matlabbatch{1}.spm.spatial.coreg.estwrite.source = {''};
matlabbatch{1}.spm.spatial.coreg.estwrite.other = {''};
matlabbatch{1}.spm.spatial.coreg.estwrite.eoptions.cost_fun = 'nmi';
matlabbatch{1}.spm.spatial.coreg.estwrite.eoptions.sep = [4 2];
matlabbatch{1}.spm.spatial.coreg.estwrite.eoptions.tol = [0.02 0.02 0.02 0.001 0.001 0.001 0.01 0.01 0.01 0.001 0.001 0.001];
matlabbatch{1}.spm.spatial.coreg.estwrite.eoptions.fwhm = [7 7];
matlabbatch{1}.spm.spatial.coreg.estwrite.roptions.interp = 4;
matlabbatch{1}.spm.spatial.coreg.estwrite.roptions.wrap = [0 0 0];
matlabbatch{1}.spm.spatial.coreg.estwrite.roptions.mask = 0;
matlabbatch{1}.spm.spatial.coreg.estwrite.roptions.prefix = 'r';

% Loop over subjects: fill Matlabbatch and run it
% l_subj = 1:5;
l_subj = 1:nfn_MTw;
% l_subj = 1:nfn_MTw; l_subj([70 71]) = [];
for i_sub = l_subj
    % Fill with data
    matlabbatch{1}.spm.spatial.coreg.estwrite.ref{1} = ...
        deblank(fn_T1w(i_sub,:));
    matlabbatch{1}.spm.spatial.coreg.estwrite.source{1} = ...
        deblank(fn_MPR(i_sub,:));
    % run
    spm_jobman('run', matlabbatch);
end
fn_rMPR = spm_file(fn_MPR,'prefix','r');



% Estimate the SSIM
% -----------------
% Use the acquired T1w-MPRAGE image as the reference
fn_rMPR = spm_file(fn_MPR,'prefix','r');
n_MPRl = numel(params.lambda);

% Loop over subjects: load the ref image only once, then each MPRAGE-like
% image individually
to_remSSIM = 48; % Missing T1w subject -> mismatch between MPRl and MPRo

l_subj = 1:nfn_MTw; l_subj(to_remSSIM) = [];
SSIM_val = zeros(numel(l_subj),n_MPRl);
fn_SSIM_val = 'SSIM_val.tsv';
fprintf('\nDealing with %d subjects: \n',numel(l_subj))

SSIM_par = struct(...
    'MPRo_max', 800, ...
    'MPRl_max', 5);
SSIM_par.Mratio = SSIM_par.MPRl_max / SSIM_par.MPRo_max;
nl_subj = numel(l_subj);
for ii_sub = 1:nl_subj
    fprintf('\t %d / %d \n',ii_sub,nl_subj)
    i_sub = l_subj(ii_sub);
    % Load the ref image
    img_ref = spm_read_vols(spm_vol(fn_rMPR(ii_sub,:)));
    img_ref(img_ref>SSIM_par.MPRo_max) = 0;
%     img_ref = img_ref*SSIM_par.Mratio;
    % Check the MPRlike images
    fn_MPRl_sub = fn_MPRl{i_sub};
    % Loop over the MPRAGE-like images and estimate SSIM
    SSIM_val_sub = zeros(1,n_MPRl);
    for i_lam = 1:n_MPRl
        img_MPRl = spm_read_vols(spm_vol(fn_MPRl_sub(i_lam,:)));
        img_MPRl(img_MPRl>SSIM_par.MPRl_max) = 0;
%         L = max(img_MPRl(:))-min(img_MPRl(:));
%         L = 1; % L = 3;
%         SSIM_val_sub1(i_lam) = ssim(img_MPRl,img_ref,'DynamicRange',L);
%         SSIM_val_sub1_2(i_lam) = ssim(img_MPRl,img_ref)
        SSIM_val_sub(i_lam) = ssim(uint8(img_MPRl),uint8(img_ref));
%         score = msssim3d(img_MPRl,img_ref)
    end
    SSIM_val(ii_sub,:) = SSIM_val_sub;
    % save table
    spm_save(fn_SSIM_val,SSIM_val)
end

mean(SSIM_val)
std(SSIM_val)


fn_ref = fn_rMPR(i_sub,:)
fn_tst = fn_MPRl{i_sub}
SSIM = cp_SSIMglobal(fn_ref, fn_tst)
