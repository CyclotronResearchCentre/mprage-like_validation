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
% - for some sujects (70 & 71) MPM images are misalagned with each other 

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

% Unzip all the NIfTI files
flag = struct(...
    'filt','^.*\.gz$',... % pick all .gz files
    'rec', true, ...      % act recursively
    'delOrig', true);    % delete original file after gunzipping 
fn_out = cp_gunzip(pth_data, flag);

%% Apply on data

% Collect the data, only from "run-1"
fn_MTw = spm_select('FPListRec',pth_data,'^sub.*MTw.*-1_echo-1.*mag_MPM.nii$');
fn_PDw = spm_select('FPListRec',pth_data,'^sub.*PDw.*-1_echo-1.*mag_MPM.nii$');
fn_T1w = spm_select('FPListRec',pth_data,'^sub.*T1w.*-1_echo-1.*mag_MPM.nii$');

% removing the troublesome subjects, for the moment
to_remove = [70 71];
fn_MTw(to_remove,:) = [];
fn_PDw(to_remove,:) = [];
fn_T1w(to_remove,:) = [];

nfn_MTw = size(fn_MTw,1);
nfn_PDw = size(fn_PDw,1);
nfn_T1w = size(fn_T1w,1);

if nfn_MTw~=nfn_PDw || nfn_MTw~=nfn_T1w
    error('Mismatched number of images.')
end

% MPRAGE T1w images
fn_MPR = spm_select('FPListRec',pth_data,'^sub.*-1_T1w.nii$');
fn_MPR(to_remove,:) = [];

% Check those having a "run-2"
fn_MTw_r2 = spm_select('FPListRec',pth_data,'^sub.*MTw.*-2_echo-1.*mag_MPM.nii$');
fn_PDw_r2 = spm_select('FPListRec',pth_data,'^sub.*PDw.*-2_echo-1.*mag_MPM.nii$');
fn_T1w_r2 = spm_select('FPListRec',pth_data,'^sub.*T1w.*-2_echo-1.*mag_MPM.nii$');

% Apply MPRAGE-like
% Set parameters,

params = struct(...
    'lambda', [NaN 1 30 50 60 70 100 200 400], ...
    'indiv', false, ...
    'thresh', [], ...
    'coreg', false, ...
    'BIDSform', false);

% All lambda values to test 
% -> files labelled with lambda values + json file with lambda values
% params.lambda = [1 30 50 60 70 100 200 400];
% Find the optimal lambda value -> just json file with lambda value
params.lambda = NaN;

% Apply on a bunch of subjects, collect 
% - file name sof generated images
% - estimated lambda value if returned
fn_MPRl = cell(nfn_MTw,1);
est_lambda = zeros(nfn_MTw,1);
fprintf('\nDealing with %d subjects: \n',nfn_MTw)
for i_sub = 1:nfn_MTw % 5 % 
    fn_in = char(fn_T1w(i_sub,:),fn_MTw(i_sub,:),fn_PDw(i_sub,:));
    if any(isnan(params.lambda))
        [fn_out,est_lambda(i_sub)] = hmri_MPRAGElike(fn_in,params);
    else
        fn_out = hmri_MPRAGElike(fn_in,params);
    end
    fn_MPRl{i_sub} = fn_out;
    fprintf('\t %d / %d \n',i_sub,nfn_MTw)
end
fprintf('\n')

val_lambda = est_lambda;
save val_lambda val_lambda

figure, hist(val_lambda)
fprintf('\nMean & std : %f +/- %f\n',mean(val_lambda), std(val_lambda))