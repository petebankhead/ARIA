function ARIA_save_all_test_processors
% Generate the vessel processors used with the results published in 'Fast
% retinal vessel detection and measurement using wavelets and edge location
% refinement' and store these in the Vessel_Processors directory of ARIA.
% Note that if these processors already exist in the directory, the current
% versions will be overwritten!  Also, the directory must be available on
% MATLAB's search path (which should be the case if ARIA has already been
% run once with its GUI).
%
% 
% Copyright © 2011 Peter Bankhead.
% See the file : Copyright.m for further details.

args = ARIA_generate_test_processor('DRIVE');
save_vessel_processor('DRIVE.vessel_processor', args);

args = ARIA_generate_test_processor('CLRIS');
save_vessel_processor('REVIEW_CLRIS.vessel_processor', args);

args = ARIA_generate_test_processor('VDIS');
save_vessel_processor('REVIEW_VDIS.vessel_processor', args);

args = ARIA_generate_test_processor('KPIS');
save_vessel_processor('REVIEW_KPIS.vessel_processor', args);

args = ARIA_generate_test_processor('HRIS');
save_vessel_processor('REVIEW_HRIS.vessel_processor', args);

args = ARIA_generate_test_processor('HRIS_downsample');
save_vessel_processor('REVIEW_HRIS_downsample.vessel_processor', args);