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

% plot results

% input
% ... results.mat for each subject

function plotUcmResults(varargin)
    %% parse input
    parser = inputParser;
    parser.KeepUnmatched = true;
    addParameter(parser, 'subjects', [])
    addParameter(parser, 'dictate_axes', false)
    addParameter(parser, 'show_legend', false)
    addParameter(parser, 'save', false)
    addParameter(parser, 'format', 'epsc')
    addParameter(parser, 'settings', 'studySettings.txt')
    parse(parser, varargin{:})
    subjects = parser.Results.subjects;
    dictate_axes = parser.Results.dictate_axes;
    show_legend = parser.Results.show_legend;
    settings_file = parser.Results.settings;

    % load settings
    study_settings_file = '';
    if exist('studySettings.txt', 'file')
        study_settings_file = 'studySettings.txt';
    end    
    if exist(['..' filesep 'studySettings.txt'], 'file')
        study_settings_file = ['..' filesep 'studySettings.txt'];
    end    
    if exist(['..' filesep '..' filesep 'studySettings.txt'], 'file')
        study_settings_file = ['..' filesep '..' filesep 'studySettings.txt'];
    end
    study_settings = SettingsCustodian(study_settings_file);
    
    plot_settings_file = '';
    if exist(settings_file, 'file')
        plot_settings_file = settings_file;
    end    
    if exist(['..' filesep settings_file], 'file')
        plot_settings_file = ['..' filesep settings_file];
    end    
    if exist(['..' filesep '..' filesep settings_file], 'file')
        plot_settings_file = ['..' filesep '..' filesep settings_file];
    end
    plot_settings = SettingsCustodian(plot_settings_file);

    %% determine subjects and data folders
    data_folder_list = determineDataStructure(subjects);
    [comparison_indices, conditions_per_comparison_max] = determineComparisons(study_settings, plot_settings);
    number_of_comparisons = length(comparison_indices);
    
    %% collect data from all data folders
    variables_to_plot = plot_settings.get('variables_to_plot');
    number_of_variables_to_plot = size(variables_to_plot, 1);
    condition_perturbation_list_all = {};
    condition_vision_list_all = {};
    V_para_data_all = cell(number_of_variables_to_plot, 1);
    V_perp_data_all = cell(number_of_variables_to_plot, 1);
    
    for i_folder = 1 : length(data_folder_list)
        % load data
        data_path = data_folder_list{i_folder};
        load([data_path filesep 'subjectInfo.mat'], 'date', 'subject_id');
        load([data_path filesep 'analysis' filesep date '_' subject_id '_results.mat']);

        % append data from this subject to containers for all subjects
        condition_perturbation_list_all = [condition_perturbation_list_all; condition_perturbation_list_session]; %#ok<AGROW>
        condition_vision_list_all = [condition_vision_list_all; condition_vision_list_session]; %#ok<AGROW>
        for i_variable = 1 : number_of_variables_to_plot
            % load and extract data
            this_variable_name = variables_to_plot{i_variable, 1};
            index_in_saved_data = find(strcmp(variable_names_session, this_variable_name), 1, 'first');
            this_V_para = V_para_session{index_in_saved_data}; %#ok<USENS>
            this_V_perp = V_perp_session{index_in_saved_data}; %#ok<USENS>
            
            % store
            V_para_data_all{i_variable} = [V_para_data_all{i_variable} this_V_para];
            V_perp_data_all{i_variable} = [V_perp_data_all{i_variable} this_V_perp];
        end
    end
    
    %% create figures and determine abscissae for each comparison
    comparison_variable_to_axes_index_map = zeros(number_of_comparisons, 1);
    abscissae_cell = cell(number_of_comparisons, number_of_variables_to_plot);
    
    variables_to_plot = plot_settings.get('variables_to_plot');
    conditions_to_plot = plot_settings.get('conditions_to_plot');    
    conditions_control = study_settings.get('conditions_control');
    
    % make one figure per comparison and variable
    figure_handles = zeros(number_of_comparisons, number_of_variables_to_plot);
    axes_handles = zeros(number_of_comparisons, number_of_variables_to_plot);
    for i_variable = 1 : number_of_variables_to_plot
        for i_comparison = 1 : number_of_comparisons
            % make figure and axes
            new_figure = figure; new_axes = axes; hold on;

            % store handles and determine abscissa data
            figure_handles(i_comparison, i_variable) = new_figure;
            axes_handles(i_comparison, i_variable) = new_axes;
            comparison_variable_to_axes_index_map(i_comparison) = i_comparison;

            % abscissae gives the bin edges here
            if dictate_axes
                lower_bound = str2double(variables_to_plot{i_variable, 5});
                upper_bound = str2double(variables_to_plot{i_variable, 6});
            else
                lower_bound = min([V_para_data_all{i_variable} V_perp_data_all{i_variable}]);
                upper_bound = max([V_para_data_all{i_variable} V_perp_data_all{i_variable}]);
            end
            this_comparison = comparison_indices{i_comparison};
            abscissae_control = 0;
            abscissae_stimulus = 1 : length(this_comparison);
            abscissae = {abscissae_control, abscissae_stimulus};
            abscissae_cell{i_comparison, i_variable} = abscissae;

            % set axes properties
            if dictate_axes
                set(gca, 'ylim', [str2double(variables_to_plot{i_variable, 5}), str2double(variables_to_plot{i_variable, 6})]);
            end
            
            xtick = abscissae_cell{i_comparison, i_variable}{2};
            if ~isempty(conditions_control)
                xtick = [abscissae_cell{i_comparison, i_variable}{1} xtick]; %#ok<AGROW>
            end
            set(gca, 'xlim', [-0.5 + min(xtick) 0.5 + max(xtick(end))]);
            set(gca, 'xtick', xtick);

            % set axis labels
            ylabel(variables_to_plot{i_variable, 3});

            % determine title % TODO: this is still from walking, doesn't make sense for quiet stance
            title_string = variables_to_plot{i_variable, 2};
            filename_string = variables_to_plot{i_variable, 4};
            for i_label = 1 : length(study_settings.get('condition_labels'))
                if (i_label ~= plot_settings.get('comparison_to_make')) ...
                    && (i_label ~= 1) ...
                    && (i_label ~= 3) ...
                    && (i_label ~= 5) ...
                    && (i_label ~= 6) ...
                    && (i_label ~= 7)
                    this_condition_label = strrep(conditions_to_plot{comparison_indices{i_comparison}(1), i_label}, '_', ' ');
                    if i_label ~= plot_settings.get('comparison_to_make')
                        title_string = [title_string ' - ' this_condition_label]; %#ok<AGROW>
                        filename_string = [filename_string '_' this_condition_label];
                    end
                end
            end
            stance_label = conditions_to_plot{comparison_indices{i_comparison}(1), 1};
            if strcmp(stance_label, 'STANCE_RIGHT')
                title_string = [title_string ' - first step stance leg RIGHT'];
                filename_string = [filename_string '_stanceR'];
            end
            if strcmp(stance_label, 'STANCE_LEFT')
                title_string = [title_string ' - first step stance leg LEFT'];
                filename_string = [filename_string '_stanceL'];
            end
            title(title_string); set(gca, 'Fontsize', 12)
            set(gcf, 'UserData', filename_string)


        end
    end

    
    %% plot data
    bar_width = plot_settings.get('bar_width');
    show_outliers = plot_settings.get('show_outliers');
    for i_variable = 1 : number_of_variables_to_plot
        V_para_to_plot = V_para_data_all{i_variable, 1};
        V_perp_to_plot = V_perp_data_all{i_variable, 1};
        
        color_para = plot_settings.get('color_para');
        color_perp = plot_settings.get('color_perp');
        for i_comparison = 1 : length(comparison_indices)
            % find correct condition indicator for control
            conditions_this_comparison = comparison_indices{i_comparison};
            target_axes_handle = axes_handles(comparison_variable_to_axes_index_map(i_comparison), i_variable);
            
            % plot stimulus
            for i_condition = 1 : length(conditions_this_comparison)
                
                % find correct condition indicator
                condition_identifier = conditions_to_plot(conditions_this_comparison(i_condition), :);
                perturbation_indicator = strcmp(condition_perturbation_list_all, condition_identifier{1});
                vision_indicator = strcmp(condition_vision_list_all, condition_identifier{2});
                this_condition_indicator = perturbation_indicator & vision_indicator;
                
                % get data
                V_para_to_plot_this_condition = V_para_to_plot(:, this_condition_indicator);
                V_perp_to_plot_this_condition = V_perp_to_plot(:, this_condition_indicator);
                target_abscissa = abscissae_cell{i_comparison, i_variable};
                
                % plot
                if strcmp(plot_settings.get('plot_style'), 'box')
                    singleBoxPlot ...
                      ( ...
                        target_axes_handle, ...
                        target_abscissa{2}(i_condition)-bar_width/2, ...
                        V_para_to_plot_this_condition, ...
                        color_para, ...
                        '', ...
                        show_outliers, ...
                        bar_width ...
                      )
                    singleBoxPlot ...
                      ( ...
                        target_axes_handle, ...
                        target_abscissa{2}(i_condition)+bar_width/2, ...
                        V_perp_to_plot_this_condition, ...
                        color_perp, ...
                        '', ...
                        show_outliers, ...
                        bar_width ...
                      )
                end
                if strcmp(plot_settings.get('plot_style'), 'violin')
                    singleViolinPlot ...
                      ( ...
                        V_para_to_plot_this_condition, ...
                        'axes', target_axes_handle, ...
                        'abscissa', target_abscissa{2}(i_condition)-bar_width/2, ...
                        'facecolor', color_para, ...
                        'plot_mean', true, ...
                        'meancolor', [0.02 0.2 .7], ...
                        'plot_median', true, ...
                        'mediancolor', [0 0 0], ...
                        'width', bar_width, ...
                        'show_outliers', show_outliers ...
                      );
                    singleViolinPlot ...
                      ( ...
                        V_perp_to_plot_this_condition, ...
                        'axes', target_axes_handle, ...
                        'abscissa', target_abscissa{2}(i_condition)+bar_width/2, ...
                        'facecolor', color_perp, ...
                        'plot_mean', true, ...
                        'meancolor', [0.02 0.2 .7], ...
                        'plot_median', true, ...
                        'mediancolor', [0 0 0], ...
                        'width', bar_width, ...
                        'show_outliers', show_outliers ...
                      );
                end
                
                % update labels
                label_string = strrep(conditions_to_plot{comparison_indices{i_comparison}(i_condition), plot_settings.get('comparison_to_make')}, '_', ' ');
                xtick = get(target_axes_handle, 'xtick');
                xticklabels = get(target_axes_handle, 'xticklabel');
                xticklabels{xtick == target_abscissa{2}(i_condition)} = label_string;
                set(target_axes_handle, 'xticklabel', xticklabels);
              
            end
        end
    end
    
    %% save figures
    if parser.Results.save
        % figure out folders
        if ~exist('figures', 'dir')
            mkdir('figures')
        end
        if ~exist(['figures' filesep 'withLabels'], 'dir')
            mkdir(['figures' filesep 'withLabels'])
        end
        if ~exist(['figures' filesep 'noLabels'], 'dir')
            mkdir(['figures' filesep 'noLabels'])
        end
        for i_figure = 1 : numel(figure_handles)
            % save with labels
%             legend(axes_handles(i_figure), 'show');
            filename = ['figures' filesep 'withLabels' filesep get(figure_handles(i_figure), 'UserData')];
            saveas(figure_handles(i_figure), filename, parser.Results.format)
            
            % save without labels
%             set(postext, 'visible', 'off');
%             set(negtext, 'visible', 'off');
            
            set(get(axes_handles(i_figure), 'xaxis'), 'visible', 'off');
            set(get(axes_handles(i_figure), 'yaxis'), 'visible', 'off');
            set(get(axes_handles(i_figure), 'xlabel'), 'visible', 'off');
            set(get(axes_handles(i_figure), 'ylabel'), 'visible', 'off');
            set(get(axes_handles(i_figure), 'title'), 'visible', 'off');
            set(axes_handles(i_figure), 'xticklabel', '');
            set(axes_handles(i_figure), 'yticklabel', '');
            set(axes_handles(i_figure), 'position', [0 0 1 1]);
            legend(axes_handles(i_figure), 'hide');
            filename = ['figures' filesep 'noLabels' filesep get(figure_handles(i_figure), 'UserData')];
            saveas(figure_handles(i_figure), filename, parser.Results.format);

            close(figure_handles(i_figure))            
        end
    end
    
end





