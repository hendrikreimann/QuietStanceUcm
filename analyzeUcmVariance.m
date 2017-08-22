%     This file is part of the CoBaL code base
%     Copyright (C) 2017 Hendrik Reimann <hendrikreimann@gmail.com>
% 
%     This program is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, either version 3 of the License, or
%     (at your option) any later version.
% 
%     This program is distributed in the hope that it will be useful,
%     but WITHOUT ANY WARRANTY; without even the implied warranty of
%     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%     GNU General Public License for more details.
% 
%     You should have received a copy of the GNU General Public License
%     along with this program.  If not, see <http://www.gnu.org/licenses/>.

% analyze the data

% input
% relevantDataStretches.mat

function analyzeUcmVariance(varargin)
    [condition_list, trial_number_list] = parseTrialArguments(varargin{:});
    load('subjectInfo.mat', 'date', 'subject_id');
    % load settings
    study_settings_file = '';
    if exist(['..' filesep 'studySettings.txt'], 'file')
        study_settings_file = ['..' filesep 'studySettings.txt'];
    end    
    if exist(['..' filesep '..' filesep 'studySettings.txt'], 'file')
        study_settings_file = ['..' filesep '..' filesep 'studySettings.txt'];
    end
    study_settings = SettingsCustodian(study_settings_file);
    load('subjectModel.mat');
    
    if exist('conditions.csv', 'file')
        conditions_file_name = 'conditions.csv';
    end
    if exist(makeFileName(date, subject_id, 'conditions.csv'), 'file')
        conditions_file_name = makeFileName(date, subject_id, 'conditions.csv');
    end
    
    ucm_variables = study_settings.get('ucm_variables');
    number_of_ucm_variables = length(ucm_variables);
    
    % make containers to hold the data
    V_para_session = cell(number_of_ucm_variables, 1);
    V_perp_session = cell(number_of_ucm_variables, 1);
    jacobians_session = cell(number_of_ucm_variables, 1);
    condition_perturbation_list_session = {};
    condition_vision_list_session = {};
    
    % analyze and store data
    for i_type = 1 : length(condition_list)
        condition = condition_list{i_type};
        trials_to_process = trial_number_list{i_type};
        for i_trial = trials_to_process
            disp(['i_trial = ' num2str(i_trial)])
            % load and prepare data
            load(['processed' filesep makeFileName(date, subject_id, condition, i_trial, 'kinematicTrajectories.mat')]);
            
            % calculate Jacobians
            for i_variable = 1 : number_of_ucm_variables
                theta_mean = mean(joint_angle_trajectories)';
                kinematic_tree.jointAngles = theta_mean;
                kinematic_tree.updateConfiguration;
                if strcmp(ucm_variables{i_variable}, 'com_ap')
                    J_com = kinematic_tree.calculateCenterOfMassJacobian;
                    J_com_ap = J_com(1, :);
                    jacobians_session{i_variable} = J_com_ap;
                end
                if strcmp(ucm_variables{i_variable}, 'com_vert')
                    J_com = kinematic_tree.calculateCenterOfMassJacobian;
                    J_com_vert = J_com(3, :);
                    jacobians_session{i_variable} = J_com_vert;
                end
                if strcmp(ucm_variables{i_variable}, 'com_2d')
                    J_com = kinematic_tree.calculateCenterOfMassJacobian;
                    J_com_2d = J_com([1 3], :);
                    jacobians_session{i_variable} = J_com_2d;
                end
            end
                    
            for i_variable = 1 : number_of_ucm_variables
                % calculate and store UCM variance
                [V_para, V_perp] = calculateUcmVariance(joint_angle_trajectories', jacobians_session{i_variable});
                V_para_session{i_variable} = [V_para_session{i_variable} V_para];
                V_perp_session{i_variable} = [V_perp_session{i_variable} V_perp];
                
            end
            % store conditions
            condition_perturbation = loadConditionFromFile(conditions_file_name, 'perturbation', i_trial);
            condition_vision = loadConditionFromFile(conditions_file_name, 'vision', i_trial);
            
            condition_perturbation_list_session = [condition_perturbation_list_session; condition_perturbation]; %#ok<AGROW>
            condition_vision_list_session = [condition_vision_list_session; condition_vision]; %#ok<AGROW>
        end
    end
    
    % save data
    variable_names_session = ucm_variables; %#ok<NASGU>
    
    results_file_name = ['analysis' filesep makeFileName(date, subject_id, 'results')];
    save ...
      ( ...
        results_file_name, ...
        'V_para_session', ...
        'V_perp_session', ...
        'variable_names_session', ...
        'condition_perturbation_list_session', ...
        'condition_vision_list_session' ...
      )
end

          

