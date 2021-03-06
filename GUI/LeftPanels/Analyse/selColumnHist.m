function selColumnHist(hObject,event,h)
% selColumnHist - Select specific columns for the atomcounting routine
%
% This function enables the user to select specific column in the StatSTEM
% interface which will only be used for the atomcounting routine. Columns
% are selected from the histogram of scattering cross-sections
%
%   syntax: selColumnHist(hObject,event,h)
%       hObject - Reference to button
%       event   - structure recording button events
%       h       - structure holding references to StatSTEM interface
%

%--------------------------------------------------------------------------
% This file is part of StatSTEM
%
% Copyright: 2016, EMAT, University of Antwerp
% License: Open Source under GPLv3
% Contact: sandra.vanaert@uantwerpen.be
%--------------------------------------------------------------------------

%% Preparation of function
% First turn off figure selection options
[h_pan,h_zoom,h_cursor] = turnOffFigureSelection(h);

% Check if no other routine is running
userdata = get(h.right.tabgroup,'Userdata');
if (userdata.callbackrunning)
    % Is so store function name and variables and cancel other function
    userdata.function.name = mfilename;
    userdata.function.input = {hObject,event,h};
    set(h.right.tabgroup,'Userdata',userdata)
    robot = java.awt.Robot;
    robot.keyPress(java.awt.event.KeyEvent.VK_ESCAPE);
    robot.keyRelease(java.awt.event.KeyEvent.VK_ESCAPE);
    return
end

% Check if button is enabled
if ~get(hObject,'Enabled')
    return
end

% Check if colorbar is shown
if strcmp(get(h.colorbar(1),'State'),'off')
    sColBar = 0;
else
    sColBar = 1;
end

% Turn off all editing in the figure
plotedit(h.fig,'off')

tab = loadTab(h);
if isempty(tab)
    h_mes = errordlg('First load an image');
    waitfor(h_mes)
    return
end

% Determine state
color = hObject.getForeground;
if get(color,'Red')==0
    %% Preparation
    % Delete previous analysis is necessary
    usr = get(tab,'Userdata');
    if any(strcmp(fieldnames(usr.file),'atomcounting'))
        quest = questdlg('Select a region for atom counting will remove previous atom counting results, continue?','Warning','Yes','No','No');
        drawnow; pause(0.05); % MATLAB hang 2013 version
        switch quest
            case 'Yes'
                deleteAtomCounting(tab,h)
                usr = get(tab,'Userdata');
            case 'No'
                return
        end
    end

    %% Image preparation
    str = get(usr.figOptions.selImg.listbox,'String');
    val = get(usr.figOptions.selImg.listbox,'Value');
    value = find(strcmp(str,'Histogram SCS'));
    % Show histogram if not yet shown
    if val~=value
        showImage(tab,'Histogram SCS',h)
        usr = get(tab,'Userdata');
    end

    %% Make all text field unfocusable
    focusFields(h,false)

    %% Select interval
    % Let user select a minimum
    userdata = get(h.right.tabgroup,'Userdata');
    userdata.callbackrunning = true; % For other routines
    set(h.right.tabgroup,'Userdata',userdata);
    title(usr.images.ax,'Select lower boundary, press ESC to exit')

    % Get minimum
    [usr.fitOpt.atom.minVol,y] = ginput_AxInFig(usr.images.ax,h.fig,h_pan,h_zoom,h_cursor);
    if ~isempty(usr.fitOpt.atom.minVol)
        % Continue
        hold(usr.images.ax,'on')
        h_min = plot(usr.images.ax,usr.fitOpt.atom.minVol,y,'b+');
        
        title(usr.images.ax,'Select upper boundary, press ESC to exit')
        
        % Get maximum
        [usr.fitOpt.atom.maxVol,~] = ginput_AxInFig(usr.images.ax,h.fig,h_pan,h_zoom,h_cursor);
        delete(h_min)
    else
        usr.fitOpt.atom.maxVol = [];
    end
    
    title(usr.images.ax,'')
    userdata = get(h.right.tabgroup,'Userdata');
    userdata.callbackrunning = false; % For other routines
    set(h.right.tabgroup,'Userdata',userdata);
    
    % If user cancelled proces, delete minimum
    if isempty(usr.fitOpt.atom.maxVol)
        usr.fitOpt.atom.minVol = [];
    end
    
    % Update userdata
    set(tab,'Userdata',usr)

    %% Make all text field focusable
    focusFields(h,true)

    %% Update figure options
    if ~isempty(usr.fitOpt.atom.minVol) && ~isempty(usr.fitOpt.atom.maxVol)
        % Reshow the histogram
        showImage(tab,'Histogram SCS',h)
        usr = get(tab,'Userdata');
        % Update figure options
        nameTag = 'Coor atomcounting';
        if isempty(usr.fitOpt.atom.selCoor) && isempty(usr.fitOpt.atom.selType)
            % Add option region atomcounting
            value = find(strcmp(str,'Model'));
            data = get(usr.figOptions.selOpt.(['optionsImage',num2str(value)]),'Data');
            data(:,1) = {false};
            data = [data;{true nameTag}];
            % Update data
            set(usr.figOptions.selOpt.(['optionsImage',num2str(value)]),'Data',data);

            value2 = find(strcmp(str,'Observation'));
            data = get(usr.figOptions.selOpt.(['optionsImage',num2str(value2)]),'Data');
            data = [data;{false nameTag}];
            % Update data
            set(usr.figOptions.selOpt.(['optionsImage',num2str(value2)]),'Data',data);
        end
        % Make text button appear red
        hObject.setForeground(java.awt.Color(1,0,0))
        set(hObject,'Text','Delete selected interval')
    end
else
    %% Preparation
    % Delete previous analysis is necessary
    usr = get(tab,'Userdata');
    if any(strcmp(fieldnames(usr.file),'atomcounting'))
        quest = questdlg('Deleting the selected histogram part will remove previous atom counting results, continue?','Warning','Yes','No','No');
        drawnow; pause(0.05); % MATLAB hang 2013 version
        switch quest
            case 'Yes'
                deleteAtomCounting(tab,h)
                usr = get(tab,'Userdata');
            case 'No'
                return
        end
    end
    usr.fitOpt.atom.minVol = [];
    usr.fitOpt.atom.maxVol = [];
    set(tab,'Userdata',usr)
    
    % Update the images
    str = get(usr.figOptions.selImg.listbox,'String');
    value = get(usr.figOptions.selImg.listbox,'Value');
    val = find(strcmp(str,'Histogram SCS'));
    if val==value
        showImage(tab,'Histogram SCS',h)
        usr = get(tab,'Userdata');
    end
    
    % Image processing
    nameTag = 'Coor atomcounting';
    data = get(usr.figOptions.selOpt.(['optionsImage',num2str(value)]),'Data');
    if isempty(usr.fitOpt.atom.selCoor)  && isempty(usr.fitOpt.atom.selType)
        % Delete coordinates from images (if shown) and figure options
        if ~isempty(data)
            ind = strcmp(data(:,2),nameTag);
            if any(ind)
                if data{ind,1}
                    showHideFigOptions(tab,value,nameTag,false,h,sColBar)
                end
            end
        end

        % Now delete options from all figure options
        for n=1:length(str)
            data = get(usr.figOptions.selOpt.(['optionsImage',num2str(n)]),'Data');
            if ~isempty(data)
                ind = strcmp(data(:,2),nameTag);
                if any(ind)
                    data = data(~ind,:);
                    set(usr.figOptions.selOpt.(['optionsImage',num2str(n)]),'Data',data)
                end
            end
        end
    else
        % Update coordinates in image, if shown
        if ~isempty(data)
            ind = strcmp(data(:,2),nameTag);
            if any(ind)
                if data{ind,1}
                    showHideFigOptions(tab,value,nameTag,false,h,sColBar)
                    showHideFigOptions(tab,value,nameTag,true,h,sColBar)
                end
            end
        end
    end
    
    % Make text button appear black
    hObject.setForeground(javax.swing.plaf.ColorUIResource(0,0,0))
    set(hObject,'Text','Select columns in histogram')
end
    

%% Update GUI
% Update userdata
set(tab,'Userdata',usr)

% Check if other function is started
if ~isempty(userdata.function)
    f = userdata.function;
    userdata.function = [];
    set(h.right.tabgroup,'Userdata',userdata);
    eval([f.name,'(f.input{:})'])
    if strcmp(f.name,'deleteFigure')
        return
    end
end
