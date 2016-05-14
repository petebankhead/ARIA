classdef Vessel_Data_IO
% VESSEL_DATA_IO Class containing static functions to load and process
% images, and to save VESSEL_DATA objects.
%   
%
% Copyright © 2011 Peter Bankhead.
% See the file : Copyright.m for further details.

   methods (Static)
       
       % Save VESSEL_DATA to a file
       function save_to_file(filename, vessel_data)
           save(filename, 'vessel_data');
       end
       
       
       % Loads VESSEL_DATA from .MAT file
       % Alternatively, loads image from file, applies the PROCESSOR to it 
       % and adds the appropriate VESSEL_SETTINGS.
       % PROCESSOR can either be an actual vessel processor (a STRUCT
       % containing a PROCESSOR_FUNCTION field), or a string giving a
       % processor name to be loaded with VESSEL_DATA_IO.
       % PROCESS_TIME gives the time spent processing an image, if
       % relevant.  Otherwise it is NaN.
        function [vessel_data, process_time] = load_from_file(filename, processor, settings)
                        
            % Full file name
            [fpath, fname, ext] = fileparts(filename);
            
            % Prepare for an unknown processing time
            process_time = NaN;

            % Try to open and process file
            if strcmpi(ext, '.mat')
                % MAT file - try to load first Vessel_Data object found
                s = load(filename);
                fields = fieldnames(s);
                vessel_data = [];
                for ii = 1:numel(fields)
                    if isa(s.(fields{ii}), 'Vessel_Data')
                        vessel_data = s.(fields{ii});
                        break;
                    end
                end
                if isempty(vessel_data)
                    error('No Vessel_Data object found in chosen file!');
                end
                % We want to use the passed settings *except* for
                % calibration, which should be read from the file
                if nargin >= 3
                    settings.calibration_value = vessel_data.settings.calibration_value;
                    settings.calibration_unit = vessel_data.settings.calibration_unit;
                    vessel_data.settings = settings;
                end
            else
                % Image file
                try
                    % Create VESSEL_DATA object
                    % Add settings if available, otherwise use default
                    if nargin >= 3
                        vessel_data = Vessel_Data(settings);
                    else
                        vessel_data = Vessel_Data;
                    end
                    
                    % Store file name
                    vessel_data.file_path = fpath;
                    vessel_data.file_name = fname;
                    
                    % Read image
                    vessel_data.im_orig = imread(filename);
                    
                    % Choose image for processing - second (green) plane of
                    % a colour image, otherwise a floating point version of
                    % the original
                    if size(vessel_data.im_orig, 3) == 3
                        vessel_data.im = single(vessel_data.im_orig(:,:,2));
                    else
                        vessel_data.im = single(vessel_data.im_orig);
                    end

                    % Run the processor - if there isn't a function
                    % defined, use the general one
                    if ischar(processor)
                        [args, fun] = load_vessel_processor(processor);
                    elseif isstruct(processor)
                        args = processor;
                        fun = processor.processor_function;
                    else
                        error('PROCESSOR must be a file name for a vessel processor, or a valid STRUCT');
                    end
                    if isempty(fun) || ~exist(fun, 'file')
                        fun = 'aria_algorithm_general';
                    end
                    prompt = vessel_data.settings.prompt && ischar(processor);
                    tic;
                    [vessel_data, args, cancelled] = feval(fun, vessel_data, args, prompt);
                    process_time = toc;
                    
                    % Test whether empty or cancelled (by user)
                    if isempty(vessel_data) || cancelled
                        vessel_data = [];
                        return;
                    end
                    
                    % Store the arguments if user was prompted
                    if prompt
                        save_vessel_processor(processor, args, fun);
                    end

                    % Test whether vessels found
                    if isempty(vessel_data.vessel_list)
                        warning('Vessel_Data_IO:No_Vessels', ['No vessels found in ', fname]);
%                         throw(MException('Vessel_Data_IO:Open', 'No vessels found in the chosen file.'));
                    end

                catch ME
                    rethrow(ME);
                end
            end

        end
       
   end

end
