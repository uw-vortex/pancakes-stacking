%% PANCAKES.EXE: Automated stacking v1.4
% June 9, 2020
% Author: Jason Au
% Copyright Jason Au 2020
% Licence: GPL-3.0-or-later

% This script should allow automatic identification and selection of
% end-diastolic frames, and stitch them back together for a 'stacked' image

% New additions Jan 24, 2020
% - Make frame 1/1200 be one less (to accommodate loop 1:end-1
% - Added title of each file to the Figure window
% - Removed saving png files as png backups. Saves 40% processing time
% - Extended the search range of red box before blue ECG spike to 17 pxls
% - Added legal

% New additions March 10, 2020
% - Add rectangle to visualize analysis box
% - Tweaked the search box dimensions to be even lower
% - Added a box for someone to adjust the pixel depth (one try only)
% - Added a screenshot image to show when something goes wrong
% - If a frame is skipped (i.e., >15 inter-frame interval), it will
% duplicate the current frame as a placeholder to handle missing reactive
% hyperemia beats.
% - Fix it so that you can cancel the textinput box and not have an error

% New additions March 23, 2020
% - Add an image export to see summary of stacking instead of clicking
% through MatLab windows. Also close all windows after processing.
% - Swapped subplot 4 to subplot 2 to see inter-frame interval
% - Added new subplot 4 to list the missing cycles
% - Add a warning message if there is no ECG trace, as well as a writing
% warning message specific to the file
% - Changed output location so it all goes to the base file location
% - Found a problem with the search regions so it was sampling the bottom
% of the ultrasound image (row 368), so offset to row 369 instead.



%% Legal
% Pancakes.exe: Automated image extraction from ultrasound .avi files
%     Copyright (C) 2020  Jason Au
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
%     along with this program.  If not, see <https://www.gnu.org/licenses/>.
%
%     jason.au@uwaterloo.ca
%     250 Laurelwood Dr., Waterloo ON, Canada N2J 0E2


%% Pancakes.exe
% Clean your workspace!
clear all;
close all;
fontSize = 22;

% Dialogue box
a1 = questdlg('How many files are you stacking?','Pancakes','One','Multiple','One');

switch a1
    case 'One'
        % Select the file
        [baseFileName, folderName, FilterIndex] = uigetfile('*.*','Select avi file');
        movieFileName = fullfile(folderName, baseFileName);

        % Prepare image output folter
        [folder, baseFileName, extensions] = fileparts(movieFileName);
        outputFolder = sprintf('%s', folder);
        if ~exist(outputFolder, 'dir')
            mkdir(outputFolder);
        end

        % Extract basic file information
        v = VideoReader(movieFileName);
        frames = v.NumberOfFrames;
        vHeight = v.Height;
        vWidth = v.Width;
        framesWritten = 0;
        vs = 1;

        % Prepare analysis figure
        tmptitle = sprintf('%s', baseFileName);
        fig1 = figure('Name',tmptitle,'NumberTitle','off');
        set(fig1,'units','normalized','outerposition',[0 0 1 1]);

        % Loop through all frames to find end diastole on the ECG
        % Set empty saves
        meanGrayLevels = zeros(frames, 1);
        meanRedLevels = zeros(frames, 1);
        meanGreenLevels = zeros(frames, 1);
        meanBlueLevels = zeros(frames, 1);

        % Set acquisition log to 0
        bluelog = 0;
        extractedFrames = 0;
        frameinterval = 0;
        k = 0;
        adj = 0;

        for i = 1:frames-1
            % If the preceding frame was captured, skip the next two (red box is 2
            % pixels wide)
            if bluelog == 1;
                bluelog = 2;
                continue
            end

            if bluelog == 2;
                bluelog = 0;
                continue
            end

            % Extract a single frame and display it
            tmpFrame = read(v, i);
            p1 = subplot(2,2,1);
            image(tmpFrame);
            hold on;
            rectangle('Position', [33,368,580,29+k], 'EdgeColor', 'red');
            hold off;

            % Add a section to move the box up or down a few pixels
            if i == 1
                fix = questdlg('Do you want to move the ROI?','ROI check','Yes','No','Yes');
                switch fix
                    case 'Yes'
                        kans = inputdlg('How many pixels up(-) or down(+) do you want to move?');
                        kans = str2num(kans{1,1});
                        k = k + kans;
                    case 'No'
                end
            end

            % Redraw rectangle if it's the first frame
            if k ~= 0
                image(tmpFrame);
                rectangle('Position', [33,368,580,29+k], 'EdgeColor', 'red');
                hold off;
            end

            caption = sprintf('Frame %4d of %d.', i, frames-1);
            title(caption);
            drawnow;

            % Initiate the screenshot for ROI reference
            if i == 1
                p1 = subplot(2,2,3);
                hold off;
                image(tmpFrame);
                hold on;
                rectangle('Position', [33,369,580,29+k], 'EdgeColor', 'red');
                hold off;
                title('First reference frame')
            end

            % Determine if ECG stable or moving
            ecgroi = tmpFrame(369:end, 1:569, 1);
            ecgend = tmpFrame(369:end, 571:572, 1);

            % Case when the ECG marker is still moving across the screen
            if any(ecgroi(:) > 200)
                % Catch if there is no ECG trace
                if mean(ecgroi(1:35,:)) == 0
                    warndlg('There is no ECG trace, silly!');
                    er = 1;
                    break;
                end
                %Get red box position
                [r,c] = find(ecgroi > 200);
                redcol = c(1);
                %Get blue spike positions
                ecgblue = tmpFrame(369:397+k, 33:569, 3);
                [bluer,bluec] = find(ecgblue > 120);

                %Find frames whose red positions are within 10 pixels of blue spike
                bluelog = 0;
                for j = 1:length(bluec);
                    if (redcol - bluec(j) > -25) && (redcol - bluec(j) < 0)
                        bluelog = 1;
                    elseif (redcol - bluec(j) > 0) && (redcol - bluec(j) < 10)
                        bluelog = 1;
                    end
                end

                %If red box is within 15 pixels of blue spike, save frame, and
                %export
                if bluelog == 1
                    vStacked(:,:,:,vs) = tmpFrame;
                    vs = vs+1;
                end

            % Case when ECG is at the end of the strip
            elseif any(ecgend(:) > 200)
                %Get red box position
                ecgred = tmpFrame(369:end, 555:end, 1);
                [r,c] = find(ecgred > 200);
                redcol = c(1);

                %First look for blue spikes in the 10 pixels left of box
                ecgblue = tmpFrame(369:397+k, 555:end, 3);
                [bluer,bluec] = find(ecgblue > 120);
                bluelog = 0;
                for j = 1:length(bluec);
                    if abs(redcol - bluec(j)) < 10
                        bluelog = 1;
                    end
                end

                %If red box is within 25 pixels of blue spike, save frame, and
                %export
                if bluelog == 1
                    vStacked(:,:,:,vs) = tmpFrame;
                    vs = vs+1;
                else
                    %Next look in the next frame to see if blue spike is within a
                    %certain area
                    tmpblue = read(v,i+1);
                    ecgblue = tmpblue(369:397+k, 555:end, 3);
                    [bluer,bluec] = find(ecgblue > 120);
                    for j = 1:length(bluec);
                        if abs(redcol - bluec(j)) < 25
                            bluelog = 1;
                        end
                    end

                    if bluelog == 1
                        vStacked(:,:,:,vs) = tmpFrame;
                        vs = vs+1;
                    end
                end
            end

            % Things to run if a frame is extracted
            if bluelog == 1
                tmpint = length(extractedFrames);
                extractedFrames(i) = 1;

                if length(extractedFrames) == 1
                else
                    % Plot the inter-frame interval
                    frameinterval(i) = i - tmpint;
                    p1 = subplot(2,2,2);
                    hold off;
                    plot(frameinterval, 'bo');
                    grid on;
                    title('Interval between extracted frames');
                    ylim([0,30]);
                    ax = gca;
                    ax.YTick = 3:12:15;
                    if i < 20
                        xlabel('Frame Number');
                        ylabel('Inter-frame interval');
                    end
                end

                % Plot a screenshot if the frame interval is too small or
                % too large
                if (frameinterval(i) > 15) | (frameinterval(i) < 3)
                    p1 = subplot(2,2,3);
                    hold off;
                    image(tmpFrame);
                    hold on;
                    rectangle('Position', [33,369,580,29+k], 'EdgeColor', 'red');
                    hold off;
                    if i == 1
                        title('First reference frame')
                    else
                        cap = sprintf('Cycle before frame %4d was skipped', i);
                        title(cap)
                    end

                    % Add a section that if a frame is skipped, just
                    % duplicate the frame to preserve beat-to-beat analysis
                    if frameinterval(i) > 15
                        vStacked(:,:,:,vs) = tmpFrame;
                        vs = vs+1;
                    end

                    %Plot a list of problem frames
                    p1 = subplot(2,2,4);
                    text(0.1, 0.9+adj, sprintf('Cycle before frame %4d was skipped', i));
                    axis off;
                    adj = adj-0.1;
                end
                % Indicate Progress
                progressIndication = sprintf('Wrote frame %4d of %d.', i, frames);
                disp(progressIndication);
                framesWritten = framesWritten+1;
            end
        end

        try
            % Save summary image to outputFolder
            outputBaseFileName = sprintf('summary_%s.png', baseFileName);
            outputFullFileName = fullfile(outputFolder, outputBaseFileName);
            %text(5,15,outputBaseFileName,'FontSize',20);
            %frameWithText = getframe(p1);
            %imwrite(frameWithText.cdata, outputFullFileName, 'png');
            saveas(p1, outputFullFileName, 'jpg');

            % Save stacked DICOM to outputFolder
            outputBaseDicom = sprintf('%s_stacked.dcm', baseFileName(1:end-4));
            outputFullDicom = fullfile(outputFolder, outputBaseDicom);
            dicomwrite(vStacked, outputFullDicom);

            finishedMessage = sprintf('Done! It wrote %d frames to stack', framesWritten);
            disp(finishedMessage);
            close all;
        catch nowrite
            warndlg(sprintf('Did not write a stacked file to %s', baseFileName));
        end





    case 'Multiple'
        % Select the files
        [filenames, pathname] = uigetfile('*.*','Select avi file','Multiselect','on');
        path = char(pathname);
        [row files_selected] = size(filenames);
        filenames = cellstr(filenames);

        % Loop through selected files
        for f = 1:files_selected
            clearvars -EXCEPT files_selected filenames pathname path row files_selected f a1 fontSize
            tempfile = char(filenames(f));

            movieFileName = fullfile(path, tempfile);

            % Prepare image output folter
            [folder, baseFileName, extensions] = fileparts(movieFileName);
            outputFolder = sprintf('%s', folder);
            if ~exist(outputFolder, 'dir')
                mkdir(outputFolder);
            end

            % Extract basic file information
            v = VideoReader(movieFileName);
            frames = v.NumberOfFrames;
            vHeight = v.Height;
            vWidth = v.Width;
            framesWritten = 0;
            vs = 1;

            % Prepare analysis figure
            tmptitle = sprintf('%s', tempfile);
            fig1 = figure('Name',tmptitle,'NumberTitle','off');
            set(fig1,'units','normalized','outerposition',[0 0 1 1]);

            % Loop through all frames to find end diastole on the ECG
            % Set empty saves
            meanGrayLevels = zeros(frames, 1);
            meanRedLevels = zeros(frames, 1);
            meanGreenLevels = zeros(frames, 1);
            meanBlueLevels = zeros(frames, 1);

            % Set acquisition log to 0
            bluelog = 0;
            extractedFrames = 0;
            frameinterval = 0;
            k = 0;
            adj = 0;

            for i = 1:frames-1
                % If the preceding frame was captured, skip the next two (red box is 2
                % pixels wide)
                if bluelog == 1
                    bluelog = 2;
                    continue
                end

                if bluelog == 2;
                    bluelog = 0;
                    continue
                end

                % Extract a single frame and display it
                tmpFrame = read(v, i);
                p1 = subplot(2,2,1);
                image(tmpFrame);
                hold on;
                rectangle('Position', [33,369,580,29+k], 'EdgeColor', 'red');
                hold off;

                % Add a section to move the box up or down a few pixels
                if i == 1
                    fix = questdlg('Do you want to move the ROI?','ROI check','Yes','No','Yes');
                    switch fix
                        case 'Yes'
                            kans = inputdlg('How many pixels up(-) or down(+) do you want to move?');
                            kans = str2num(kans{1,1});
                            k = k + kans;
                        case 'No'
                    end
                end

                % Redraw rectangle if it's the first frame
                if k ~= 0
                    image(tmpFrame);
                    rectangle('Position', [33,369,580,29+k], 'EdgeColor', 'red');
                    hold off;
                end

                caption = sprintf('Frame %4d of %d.', i, frames);
                title(caption);
                drawnow;

                % Initiate screenshot to show ROI
                if i == 1
                    p1 = subplot(2,2,3);
                    hold off;
                    image(tmpFrame);
                    hold on;
                    rectangle('Position', [33,369,580,29+k], 'EdgeColor', 'red');
                    hold off;
                    title('First reference frame')
                end

                % Determine if ECG stable or moving
                ecgroi = tmpFrame(369:end, 1:569, 1);
                ecgend = tmpFrame(369:end, 571:572, 1);

                % Case when the ECG marker is still moving across the screen
                if any(ecgroi(:) > 200)
                    % Catch if there is no ECG trace
                    if mean(ecgroi(1:35,:)) == 0
                        warndlg('There is no ECG trace, silly!');
                        er = 1;
                        break;
                    end
                    %Get red box position
                    [r,c] = find(ecgroi > 200);
                    redcol = c(1);
                    %Get blue spike positions
                    ecgblue = tmpFrame(369:397+k, 33:569, 3);
                    [bluer,bluec] = find(ecgblue > 120);

                    %Find frames whose red positions are within 15 pixels of blue spike
                    bluelog = 0;
                    for j = 1:length(bluec);
                        if (redcol - bluec(j) > -25) && (redcol - bluec(j) < 0)
                            bluelog = 1;
                        elseif (redcol - bluec(j) > 0) && (redcol - bluec(j) < 10)
                            bluelog = 1;
                        end
                    end

                    %If red box is within 15 pixels of blue spike, save frame, and
                    %export
                    if bluelog == 1
                        vStacked(:,:,:,vs) = tmpFrame;
                        vs = vs+1;
                    end


                % Case when ECG is at the end of the strip
                elseif any(ecgend(:) > 200)
                    %Get red box position
                    ecgred = tmpFrame(369:end, 555:end, 1);
                    [r,c] = find(ecgred > 200);
                    redcol = c(1);

                    %First look for blue spikes in the 10 pixels left of box
                    ecgblue = tmpFrame(369:397+k, 555:end, 3);
                    [bluer,bluec] = find(ecgblue > 120);
                    bluelog = 0;
                    for j = 1:length(bluec);
                        if abs(redcol - bluec(j)) < 10
                            bluelog = 1;
                        end
                    end

                    %If red box is within 25 pixels of blue spike, save frame, and
                    %export
                    if bluelog == 1
                        vStacked(:,:,:,vs) = tmpFrame;
                        vs = vs+1;
                    else
                        %Next look in the next frame to see if blue spike is within a
                        %certain area
                        tmpblue = read(v,i+1);
                        ecgblue = tmpblue(369:397+k, 555:end, 3);
                        [bluer,bluec] = find(ecgblue > 120);
                        for j = 1:length(bluec);
                            if abs(redcol - bluec(j)) < 25
                                bluelog = 1;
                            end
                        end

                        if bluelog == 1
                            vStacked(:,:,:,vs) = tmpFrame;
                            vs = vs+1;
                        end
                    end

                end

                % Things to do if a frame is extracted
                if bluelog == 1
                    tmpint = length(extractedFrames);
                    extractedFrames(i) = 1;


                    if length(extractedFrames) == 1
                    else
                        % Plot the inter-frame interval
                        frameinterval(i) = i - tmpint;
                        p1 = subplot(2,2,2);
                        hold off;
                        plot(frameinterval, 'bo');
                        grid on;
                        title('Interval between extracted frames');
                        ylim([0,30]);
                        ax = gca;
                        ax.YTick = 3:12:15;
                        if i < 20
                            xlabel('Frame Number');
                            ylabel('Inter-frame interval');
                        end
                    end

                    if (frameinterval(i) > 15) | (frameinterval(i) < 3)
                        % Plot the last image when something went wrong
                        p1 = subplot(2,2,3);
                        hold off;
                        image(tmpFrame);
                        hold on;
                        rectangle('Position', [33,369,580,29+k], 'EdgeColor', 'red');
                        hold off;
                        if i == 1
                            title('First reference frame')
                        else
                            cap = sprintf('Cycle before frame %4d was skipped', i);
                            title(cap)
                        end
                        % Add a section that if a frame is skipped, just
                        % duplicate the frame to preserve beat-to-beat analysis
                        if frameinterval(i) > 15
                            vStacked(:,:,:,vs) = tmpFrame;
                            vs = vs+1;
                        end

                        %Plot a list of problem frames
                        p1 = subplot(2,2,4);
                        text(0.1, 0.9+adj, sprintf('Cycle before frame %4d was skipped', i));
                        axis off;
                        adj = adj-0.1;
                    end

                    % Indicate Progress
                    progressIndication = sprintf('Wrote frame %4d of %d.', i, frames);
                    disp(progressIndication);
                    framesWritten = framesWritten+1;
                end
            end

            try
                % Save the summary image to outputFolder
                outputBaseFileName = sprintf('summary_%s.png', baseFileName);
                outputFullFileName = fullfile(outputFolder, outputBaseFileName);
                saveas(p1, outputFullFileName, 'jpg');

                % Save stacked DICOM
                outputBaseDicom = sprintf('%s_stacked.dcm', baseFileName(1:end-4));
                outputFullDicom = fullfile(outputFolder, outputBaseDicom);
                dicomwrite(vStacked, outputFullDicom);

                finishedMessage = sprintf('Done! It wrote %d frames to stack', framesWritten);
                disp(finishedMessage);
                close all;
            catch nowrite
                warndlg(sprintf('Did not write a stacked file to %s', baseFileName));
            end
        end
end
