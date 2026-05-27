%% Small bits of code about MPRAGE-like tool validation
%  Just testing on different dataset.

%% Initatialisation
spm('defaults','fmri'),
spm_jobman('initcfg')

% Some pathes
pth_MPRAGElike = 'D:\6_GitHubCRC_Git\mprage-like';
pth_dataCOFITAGEfull = 'C:\Users\christophe\OneDrive - Universite de Liege\bidsified_sub-all_mod-all';
pth_data = 'D:\ccc_DATA\COFITAGE_MPRAGElike';

addpath(pth_MPRAGElike)

% Copy the data automatically, then unzip
% Need to pick up 4 images per subjects:
% - 1st echo of MTw, PDw, T1w from MPM protocol
% - the MPRAGE, labelled as 'T1w'
% simple filter: *T1w*_echo-1*mag* *MTw*_echo-1*mag* *PDw*_echo-1*mag* *-1_T1w*

% MPM 1st echo of weighted images
fn_MTw = spm_select('FPListRec',pth_dataCOFITAGEfull,'^sub.*MTw.*_echo-1.*mag');
fn_PDw = spm_select('FPListRec',pth_dataCOFITAGEfull,'^sub.*PDw.*_echo-1.*mag');
fn_T1w = spm_select('FPListRec',pth_dataCOFITAGEfull,'^sub.*T1w.*_echo-1.*mag');
% MPRAGE T1w images
fn_MPR = spm_select('FPListRec',pth_dataCOFITAGEfull,'^sub.*-1_T1w');

% Note that 
% - some subjects have 2 runs for some MPM acquisition.
% -there are more subjects with MPRAGE than MPM data.

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
% MPRAGE T1w images
fn_MPR = spm_select('FPListRec',pth_data,'^sub.*-1_T1w.nii$');

% Check those having a "run-2"
fn_MTw_r2 = spm_select('FPListRec',pth_data,'^sub.*MTw.*-2_echo-1.*mag_MPM.nii$');
fn_PDw_r2 = spm_select('FPListRec',pth_data,'^sub.*PDw.*-2_echo-1.*mag_MPM.nii$');
fn_T1w_r2 = spm_select('FPListRec',pth_data,'^sub.*T1w.*-2_echo-1.*mag_MPM.nii$');

% Apply MPRAGE-like
params = struct(...
    'lambda', NaN, ...
    'indiv', false, ...
    'thresh', [], ...
    'coreg', false, ...
    'BIDSform', false);

% Simply apply to check it works on first 5 subjects
fn_MPR = '';
for i_sub = 1:5
    fn_in = char(fn_T1w(ii,:),fn_MTw(ii,:),fn_PDw(ii,:));
    fn_out = hmri_MPRAGElike(fn_in,params);
    fn_MPR = char(fn_MPR,fn_out);
end
fn_MPR(1,:) = [];


