%% MRI Prostate post processing tool
function mriprostate()
%% Callback: Browse
    function browseButton_Callback(hObject, eventdata, handles)
        folder_name = uigetdir();
        if(folder_name == 0)
            return
        end
        h = findobj('Tag', 'loadImagesEdit');
        set(h,'String',folder_name);
    end

%% Callback: Load Dicom Images
    function loadDicomImagesButton_Callback(hObject, eventdata, handles)
        loadImagesEdit = findobj('Tag', 'loadImagesEdit');
        imageListBox = findobj('Tag', 'imageListBox');
        images_dir = get(loadImagesEdit,'String');
        images = dir(strcat(images_dir,''));
        [sorted_names,~] = sortrows({images.name}');
        sorted_names = sorted_names(3:end);
        set(imageListBox,'String',sorted_names,'Value',1);
        slicessize = length(sorted_names);
        [imgs, infos] = readAllDICOMImages(images_dir,sorted_names);
        %         % Display first image in list
        %         selected_image_path = getSelectedImagePath();
        %         displayImage(selected_image_path);
        %         displayImageInfo(selected_image_path);
        displayImage(imgs(:,:,1));
        displayImageInfo(infos(1));
    end

%% Callback: Load JPG Images
    function loadJPGImagesButton_Callback(hObject, eventdata, handles)
        loadImagesEdit = findobj('Tag', 'loadImagesEdit');
        imageListBox = findobj('Tag', 'imageListBox');
        images_dir = get(loadImagesEdit,'String');
        images = dir(strcat(images_dir,filesep,'*.jpg'));
        [sorted_names,~] = sortrows({images.name}');
        set(imageListBox,'String',sorted_names,'Value',1);
        slicessize = length(sorted_names);
        
        [imgs, infos] = readAllJPGImages(images_dir,sorted_names);
        displayImage(imgs(:,:,1));
        displayImageInfo(infos(1));
    end

%% Callback: Image List Box
    function imageListBox_Callback(hObject, eventdata, handles)
        %         selected_image_path = getSelectedImagePath();
        [selected_image,selected_image_info,selected_image_index] = getSelectedImage();
        displayImage(selected_image);
        displayImageInfo(selected_image_info);
        displayImageMarks(selected_image_index);
    end

%% Callback: Save Anonymized Images
    function saveAnonymizedButton_Callback(hObject, eventdata, handles)
        anonymized_folder_path = uigetdir();
        if anonymized_folder_path == 0
            return
        end
        loadImagesEdit = findobj('Tag', 'loadImagesEdit');
        imageListBox = findobj('Tag', 'imageListBox');
        images_dir = get(loadImagesEdit,'String');
        images_names_list = get(imageListBox, 'String');
        createDirectoryIfNotExist(anonymized_folder_path);
        for i = 1:length(images_names_list)
            image_path = strcat(images_dir,filesep,images_names_list(i));
            image_path = image_path{:};
            image = dicomread(image_path);
            new_image_path = strcat(anonymized_folder_path,filesep,images_names_list(i));
            new_image_path = new_image_path{:};
            metadata = dicominfo(image_path);
            newHeader = buildNewHeader(metadata);
            dicomwrite(uint16(image), new_image_path, 'ObjectType', 'MR Image Storage',...
                'WritePrivate', true, newHeader);
        end
    end

%% Callback:  Save JPG
    function saveJPGButton_Callback(hObject, eventdata, handles)
        %         selected_image_path = getSelectedImagePath();
        %         selected_image = dicomread(selected_image_path);
        [filename,filepath] = uiputfile({'*.jpg','jpgformat'});
        [filepath, filename, ~] = fileparts(strcat(filepath,filename));
        [img, info] = getSelectedImage();
        P = im2double(img);
        imwrite(imadjust(P), strcat(filepath,filesep,filename,'.jpg'));
        save(strcat(filepath,filesep,filename,'.mat'),'info');
    end

%% Callback:  Save DICOM
    function saveDICOMButton_Callback(hObject, eventdata, handles)
        [filename,pathname] = uiputfile('*.*');
        filepath = strcat(pathname,filesep,filename);
        [selected_image, selected_image_info] = getSelectedImage();
        dicomwrite(uint16(selected_image), filepath, 'ObjectType', 'MR Image Storage',...
                'WritePrivate', true, selected_image_info);
    end

%% Callback: Mark TZ
    function markTZButton_Callback(hObject, eventdata, handles)
        currentTZmark = clearTZ();
        if ~isempty(currentTZmark)
            poly = impoly(imageAxes,[currentTZmark(:,1),currentTZmark(:,2)]);
        else
            poly = impoly(imageAxes,TZpolyposition);
        end
        TZpolyposition = wait(poly);
        delete(poly);
        TZpolyposition = [TZpolyposition; TZpolyposition(1,:)];
        xi = TZpolyposition(:,1); yi = TZpolyposition(:,2);
        selected_image_index = getSelectedImageIndex();
        zi = ones(length(xi),1) * selected_image_index;
        TZ = [TZ; [xi, yi, zi]];
        hold on;
        TZplot = plot(imageAxes,xi,yi,TZcolor,'Linewidth', lineWidth);
        
        showAreaAndVolume();
    end

%% Callback: Mark PZ
    function markPZButton_Callback(hObject, eventdata, handles)
        currentPZmark = clearPZ();
        if ~isempty(currentPZmark)
            poly = impoly(imageAxes,[currentPZmark(:,1),currentPZmark(:,2)]);
        else
            poly = impoly(imageAxes,PZpolyposition);
        end
        PZpolyposition = wait(poly);
        delete(poly);
        PZpolyposition = [PZpolyposition; PZpolyposition(1,:)];
        xi = PZpolyposition(:,1); yi = PZpolyposition(:,2);
        selected_image_index = getSelectedImageIndex();
        zi = ones(length(xi),1) * selected_image_index;
        PZ = [PZ; [xi, yi, zi]];
        hold on;
        PZplot = plot(imageAxes,xi,yi,PZcolor,'Linewidth', lineWidth);
        
        showAreaAndVolume();
    end

%% Callback: Mark CZ
    function markCZButton_Callback(hObject, eventdata, handles)
        currentCZmark = clearCZ();
        if ~isempty(currentCZmark)
            poly = impoly(imageAxes,[currentCZmark(:,1),currentCZmark(:,2)]);
        else
            poly = impoly(imageAxes,CZpolyposition);
        end
        CZpolyposition = wait(poly);
        delete(poly);
        CZpolyposition = [CZpolyposition; CZpolyposition(1,:)];
        xi = CZpolyposition(:,1); yi = CZpolyposition(:,2);
        selected_image_index = getSelectedImageIndex();
        zi = ones(length(xi),1) * selected_image_index;
        CZ = [CZ; [xi, yi, zi]];
        hold on;
        CZplot = plot(imageAxes,xi,yi,CZcolor,'Linewidth', lineWidth);
        
        showAreaAndVolume();
    end

%% Callback: Mark CZ
    function markTumourButton_Callback(hObject, eventdata, handles)
        currentTumourmark = clearTumour();
        if ~isempty(currentTumourmark)
            poly = impoly(imageAxes,[currentTumourmark(:,1),currentTumourmark(:,2)]);
        else
            poly = impoly(imageAxes,Tumourpolyposition);
        end
        Tumourpolyposition = wait(poly);
        delete(poly);
        Tumourpolyposition = [Tumourpolyposition; Tumourpolyposition(1,:)];
        xi = Tumourpolyposition(:,1); yi = Tumourpolyposition(:,2);
        selected_image_index = getSelectedImageIndex();
        zi = ones(length(xi),1) * selected_image_index;
        Tumour = [Tumour; [xi, yi, zi]];
        hold on;
        Tumourplot = plot(imageAxes,xi,yi,Tumourcolor,'Linewidth', lineWidth);
        
        showAreaAndVolume();
    end


%% Callback: Clear TZ
    function clearTZButton_Callback(hObject, eventdata, handles)
        clearTZ();
        showAreaAndVolume();
    end

%% Callback: Clear PZ
    function clearPZButton_Callback(hObject, eventdata, handles)
        clearPZ();
        showAreaAndVolume();
    end

%% Callback: Clear CZ
    function clearCZButton_Callback(hObject, eventdata, handles)
        clearCZ();
        showAreaAndVolume();
    end

%% Callback: Clear Tumour
    function clearTumourButton_Callback(hObject, eventdata, handles)
        clearTumour();
        showAreaAndVolume();
    end

%% Callback: Save Marks as .mat file for current slice
    function saveSliceMarksButton_Callback(hObject, eventdata, handles)
        selected_image_index = getSelectedImageIndex();
        [filename,pathname] = uiputfile('*.mat');
        filepath = strcat(pathname,filesep,filename);
        slice.TZ = [];
        slice.PZ = [];
        slice.CZ = [];
        slice.Tumour = [];
        if ~isempty(TZ)
            TZslice = TZ(TZ(:,3) == selected_image_index,:)
            slice.TZ = TZslice;
        end
        
        if ~isempty(PZ)
            PZslice = PZ(PZ(:,3) == selected_image_index,:);
            slice.PZ = PZslice;
        end
        
        if ~isempty(CZ)
            CZslice = CZ(CZ(:,3) == selected_image_index,:);
            slice.CZ = CZslice;
        end
        
        if ~isempty(Tumour)
            Tumourslice = Tumour(Tumour(:,3) == selected_image_index,:);
            slice.Tumour = Tumourslice;
        end
        save(filepath,'slice');
    end

%% Callback: Load Marks from .mat file for current slice
    function loadSliceMarksButton_Callback(hObject, eventdata, handles)
        [filename,pathname] = uigetfile('*.mat','Select Prostate Zone Marks for Current Slice');
        if(~isempty(filename))
            filepath = strcat(pathname,filesep,filename);
            clearTZ();
            clearPZ();
            clearCZ();
            clearTumour();
            data = load(filepath);
            TZ = [TZ; data.slices.TZ];
            PZ = [PZ; data.slices.PZ];
            CZ = [CZ; data.slices.CZ];
            Tumour = [Tumour; data.slices.Tumour];
            % Now Display Marks for current slice
            selected_image_index = getSelectedImageIndex();
            displayImageMarks(selected_image_index);
        end
    end

%% Callback: Save Marks as .mat file for all slices
    function saveAllMarksButton_Callback(hObject, eventdata, handles)
        [filename,pathname] = uiputfile('*.mat');
        if(~isempty(filename))
            filepath = strcat(pathname,filesep,filename);
            slices.TZ = TZ;
            slices.PZ = PZ;
            slices.CZ = CZ;
            slices.Tumour = Tumour;
            save(filepath,'slices');
        end
    end

%% Callback: Load Marks from .mat file for all slices
    function loadAllMarksButton_Callback(hObject, eventdata, handles)
        [filename,pathname] = uigetfile('*.mat','Select Prostate Zone Marks for Current Slice');
        if(~isempty(filename))
            filepath = strcat(pathname,filesep,filename);
            data = load(filepath);
            TZ = data.slices.TZ;
            PZ = data.slices.PZ;
            CZ = data.slices.CZ;
            Tumour = data.slices.Tumour;
            % Now Display Marks for current slice
            selected_image_index = getSelectedImageIndex();
            displayImageMarks(selected_image_index);
        end
    end

%% Callback: Show 3D model of all marks
    function show3DButton_Callback(hObject, eventdata, handles)
        facealpha = 0.8;
        figure
        set(gca, 'YDir', 'reverse')
        hold on;
        for sliceindex = 1:64
            if ~isempty(TZ)
                TZslice = TZ(TZ(:,3) == sliceindex,:);
                TZfill = fill3(TZslice(:,1),TZslice(:,2),TZslice(:,3),'red');
                set(TZfill, 'FaceAlpha', facealpha);
            end
            hold on;
            if ~isempty(PZ)
                PZslice = PZ(PZ(:,3) == sliceindex,:);
                PZfill = fill3(PZslice(:,1),PZslice(:,2),PZslice(:,3),'green');
                set(PZfill, 'FaceAlpha', facealpha);
            end
            hold on;
            if ~isempty(CZ)
                CZslice = CZ(CZ(:,3) == sliceindex,:);
                CZfill = fill3(CZslice(:,1),CZslice(:,2),CZslice(:,3),'blue');
                set(CZfill, 'FaceAlpha', facealpha);
            end
            hold on;
            if ~isempty(Tumour)
                Tumourslice = Tumour(Tumour(:,3) == sliceindex,:);
                Tumpurfill = fill3(Tumourslice(:,1),Tumourslice(:,2),Tumourslice(:,3),'cyan');
                set(Tumpurfill, 'FaceAlpha', facealpha);
            end
            hold on;
        end
        
        legend('TZ', 'PZ', 'CZ', 'Tumour');
    end

%% Clear TZ
    function currentTZmark = clearTZ()
        currentTZmark = [];
        if ~isempty(TZ)
            selected_image_index = getSelectedImageIndex();
            selected_index_rows = TZ(:,3) == selected_image_index;
            currentTZmark = TZ(selected_index_rows,:);
            TZ(selected_index_rows,:) = [];
            if ishandle(TZplot)
                delete(TZplot);
            end
        end
    end

%% Clear PZ
    function currentPZmark = clearPZ()
        currentPZmark = [];
        if ~isempty(PZ)
            selected_image_index = getSelectedImageIndex();
            selected_index_rows = PZ(:,3) == selected_image_index;
            currentPZmark = PZ(selected_index_rows,:);
            PZ(selected_index_rows,:) = [];
            if ishandle(PZplot)
                delete(PZplot);
            end
        end
    end

%% Clear CZ
    function currentCZmark = clearCZ()
        currentCZmark = [];
        if ~isempty(CZ)
            selected_image_index = getSelectedImageIndex();
            selected_index_rows = CZ(:,3) == selected_image_index;
            currentCZmark = CZ(selected_index_rows,:);
            CZ(selected_index_rows,:) = [];
            if ishandle(CZplot)
                delete(CZplot);
            end
        end
    end

%% Clear Tumour
    function currentTumourmark = clearTumour()
        currentTumourmark = [];
        if ~isempty(Tumour)
            selected_image_index = getSelectedImageIndex();
            selected_index_rows = Tumour(:,3) == selected_image_index;
            currentTumourmark = Tumour(selected_index_rows,:);
            Tumour(selected_index_rows,:) = [];
            if ishandle(Tumourplot)
                delete(Tumourplot);
            end
        end
    end

%% Create Anonymized Directory
    function createDirectoryIfNotExist(dirpath)
        if ~exist(dirpath, 'dir')
            mkdir(dirpath);
        end
    end

%% Build New Metadata Header
    function metadata = buildNewHeader(metadata)
        set(findobj('Tag', 'familyNameEdit'),'String',metadata.PatientName.FamilyName);
        set(findobj('Tag', 'givenNameEdit'),'String',metadata.PatientName.GivenName);
        set(findobj('Tag', 'patientIDEdit'),'String',metadata.PatientID);
        metadata.PatientName.FamilyName = get(findobj('Tag', 'nFamilyNameEdit'),'String');
        metadata.PatientName.GivenName = get(findobj('Tag', 'nGivenNameEdit'),'String');
        metadata.PatientName.PatientID = get(findobj('Tag', 'nPatientIDEdit'),'String');
        birthdate = get(findobj('Tag', 'nPatientBirthDateEdit'),'String');
        birthdate = datestr(birthdate,inDateFormat);
        metadata.PatientName.PatientID = birthdate;
    end

    function selected_image_index = getSelectedImageIndex()
        imageListBox = findobj('Tag', 'imageListBox');
        selected_image_index = get(imageListBox,'Value');
    end

%% Get Selected Image Path
    function selected_image_path = getSelectedImagePath()
        loadImagesEdit = findobj('Tag', 'loadImagesEdit');
        imageListBox = findobj('Tag', 'imageListBox');
        images_names_list = get(imageListBox, 'String');
        selected_image_index = get(imageListBox,'Value');
        selected_image_name = images_names_list(selected_image_index);
        images_dir = get(loadImagesEdit,'string');
        selected_image_path = strcat(images_dir,filesep,selected_image_name);
        selected_image_path = selected_image_path{:};
    end

%% Get Selected Image with its Metadata and Index
    function [img, info, selected_image_index] = getSelectedImage()
        selected_image_index = 0;
        img = []; info = [];
        if ~isempty(imgs)
            imageListBox = findobj('Tag', 'imageListBox');
            selected_image_index = get(imageListBox,'Value');
            img = imgs(:,:,selected_image_index);
            info = infos(selected_image_index);
        end
    end


%% Display Image
    function displayImage(selected_image)
        % Default behavior is showing in default axes of current figure
        % imageAxes must be cleared every time before showing new image
        % Otherwise, large memory leak
        cla(imageAxes);
        imshow(selected_image, []);
    end

%% Display Image Info
    function displayImageInfo(metadata)
        %         metadata = dicominfo(selected_image_path);
        set(findobj('Tag', 'familyNameEdit'),'String',metadata.PatientName.FamilyName);
        set(findobj('Tag', 'givenNameEdit'),'String',metadata.PatientName.GivenName);
        set(findobj('Tag', 'patientIDEdit'),'String',metadata.PatientID);
        patientBirthDate = datenum(metadata.PatientBirthDate,inDateFormat);
        patientBirthDate = datestr(patientBirthDate,outDateFormat);
        set(findobj('Tag', 'patientBirthDateEdit'),'String',patientBirthDate);
        set(findobj('Tag', 'studyIDEdit'),'String',metadata.StudyID);
        studyDate = datenum(metadata.StudyDate,inDateFormat);
        studyDate = datestr(studyDate,outDateFormat);
        set(findobj('Tag', 'studyDateEdit'),'String',studyDate);
        set(findobj('Tag', 'sliceLocationEdit'),'String',metadata.SliceLocation);
        set(findobj('Tag', 'instanceNumberEdit'),'String',metadata.InstanceNumber);
    end

%% Display Image Marks
    function displayImageMarks(selected_image_index)
        if ~isempty(TZ)
            TZslice = TZ(TZ(:,3) == selected_image_index,:);
            xi = TZslice(:,1); yi = TZslice(:,2);
            hold on;
            TZplot = plot(imageAxes,xi,yi,TZcolor,'Linewidth', lineWidth);
        end
        
        if ~isempty(PZ)
            PZslice = PZ(PZ(:,3) == selected_image_index,:);
            xi = PZslice(:,1); yi = PZslice(:,2);
            hold on;
            PZplot = plot(imageAxes,xi,yi,PZcolor,'Linewidth', lineWidth);
        end
        
        if ~isempty(CZ)
            CZslice = CZ(CZ(:,3) == selected_image_index,:);
            xi = CZslice(:,1); yi = CZslice(:,2);
            hold on;
            CZplot = plot(imageAxes,xi,yi,CZcolor,'Linewidth', lineWidth);
        end
        
        if ~isempty(Tumour)
            Tumourslice = Tumour(Tumour(:,3) == selected_image_index,:);
            xi = Tumourslice(:,1); yi = Tumourslice(:,2);
            hold on;
            Tumourplot = plot(imageAxes,xi,yi,Tumourcolor,'Linewidth', lineWidth);
        end
        
        showAreaAndVolume();
    end

%% Read All Images
    function [imgs, infos] = readAllDICOMImages(images_dir,images_names_list)
        for i = 1:length(images_names_list)
            image_path = strcat(images_dir,filesep,images_names_list(i));
            image_path = image_path{:};
            img = dicomread(image_path);
            imgs(:,:,i) = img;
            infos(i) = dicominfo(image_path);
        end
    end


    function [imgs,infos] = readAllJPGImages(images_dir,images_names_list)
        for i = 1:length(images_names_list)
            image_path = strcat(images_dir,filesep,images_names_list(i));
            image_path = image_path{:};
            img = imread(image_path);
            imgs(:,:,i) = img;
            
            [filepath, filename, ~] = fileparts(image_path);
            info_path = strcat(filepath, filesep, filename);
            data = load(info_path);
            infos(i) = data.info;
        end
    end


%% Calculate and Show Area and Volume for each zone
    function showAreaAndVolume()
        [~, info, selected_image_index] = getSelectedImage();
        
        if selected_image_index == 0
            return
        end
        
        PixelSpacing = info.PixelSpacing;
        SliceThickness = info.SliceThickness;
        
        set(findobj('Tag', 'areaTZEdit'),'String',0);
        set(findobj('Tag', 'volumeTZEdit'),'String',0);
        set(findobj('Tag', 'areaPZEdit'),'String',0);
        set(findobj('Tag', 'volumePZEdit'),'String',0);
        set(findobj('Tag', 'areaCZEdit'),'String',0);
        set(findobj('Tag', 'volumeCZEdit'),'String',0);
        set(findobj('Tag', 'areaTumourEdit'),'String',0);
        set(findobj('Tag', 'volumeTumourEdit'),'String',0);
        
        if ~isempty(TZ)
            TZslice = TZ(TZ(:,3) == selected_image_index,:);
            xi = TZslice(:,1); yi = TZslice(:,2);
            areaTZ = polyarea(xi,yi) * PixelSpacing(1) * PixelSpacing(2);
            volumeTZ = areaTZ * SliceThickness;
            set(findobj('Tag', 'areaTZEdit'),'String',areaTZ);
            set(findobj('Tag', 'volumeTZEdit'),'String',volumeTZ);
        end
        
        if ~isempty(PZ)
            PZslice = PZ(PZ(:,3) == selected_image_index,:);
            xi = PZslice(:,1); yi = PZslice(:,2);
            areaPZ = polyarea(xi,yi) * PixelSpacing(1) * PixelSpacing(2);
            volumePZ = areaPZ * SliceThickness;
            set(findobj('Tag', 'areaPZEdit'),'String',areaPZ);
            set(findobj('Tag', 'volumePZEdit'),'String',volumePZ);
        end
        
        if ~isempty(CZ)
            CZslice = CZ(CZ(:,3) == selected_image_index,:);
            xi = CZslice(:,1); yi = CZslice(:,2);
            areaCZ = polyarea(xi,yi) * PixelSpacing(1) * PixelSpacing(2);
            volumeCZ = areaCZ * SliceThickness;
            set(findobj('Tag', 'areaCZEdit'),'String',areaCZ);
            set(findobj('Tag', 'volumeCZEdit'),'String',volumeCZ);
        end
        
        if ~isempty(Tumour)
            Tumourslice = Tumour(Tumour(:,3) == selected_image_index,:);
            xi = Tumourslice(:,1); yi = Tumourslice(:,2);
            areaTumour = polyarea(xi,yi) * PixelSpacing(1) * PixelSpacing(2);
            volumeTumour = areaTumour * SliceThickness;
            set(findobj('Tag', 'areaTumourEdit'),'String',areaTumour);
            set(findobj('Tag', 'volumeTumourEdit'),'String',volumeTumour);
        end
    end

%% All Globla Variables and GUI Construction

clear all;
clc;

% database_path = '/media/student/58801F1B801EFEE6/University/Medical Image Processing/Christian Mata/TP Lab/database';
database_path = 'D:\University\Medical Image Processing\Christian Mata\TP Lab\database';

%% Global Matricies

imgs = [];
infos = [];
TZ = [];
PZ = [];
CZ = [];
Tumour = [];

TZplot = [];
PZplot = [];
CZplot = [];
Tumourplot = [];

TZpolyposition = [];
PZpolyposition = [];
CZpolyposition = [];
Tumourpolyposition = [];

inDateFormat = 'yyyymmdd';
outDateFormat = 'dd/mm/yyyy';
lineWidth = 3;
TZcolor = 'r';
PZcolor = 'g';
CZcolor = 'b';
Tumourcolor = 'c';
slicessize = 0;

%% Figure
wMax = 100;
hMax = 100;

hFig = figure('Visible','off','Menu','none', 'Name',' MRI Prostate Post Processing Tool',...
    'Resize','on', 'Position', [0 0 1000 600]);

imageAxes = axes('Parent',hFig,'Units','normalized',...
    'position',[22/wMax 10/hMax 60/wMax 80/hMax]);

%% Image Directory
dirBG = uibuttongroup('Units','Normalized','Title','Images Directory',...
    'BackgroundColor',[1 0.5 0],'Position',[22/wMax 92/hMax 60/wMax 7/hMax]);

loadImagesEdit = uicontrol('Style','edit','Parent', dirBG,'Units','normalized',...
    'String',database_path,'Tag','loadImagesEdit',...
    'Position',[1/60 1/7 48/60 5/7]);

browseButton = uicontrol('Style','pushbutton','Parent',dirBG,'Units','normalized',...
    'String','Browse',...
    'Position',[50/60 1/7 8/60 5/7],'Callback',@browseButton_Callback);

%% Files Controllers
wFilesBG = 18;
hFilesBG = 11;

filesBG = uibuttongroup('Units','Normalized','Title','Files',...
    'BackgroundColor',[1 0.5 0],'Position',[1/wMax 88/hMax wFilesBG/wMax hFilesBG/hMax]);

loadDicomImagesButton = uicontrol('Style','pushbutton','Parent',filesBG,'Units','normalized',...
    'String','Load DICOM Images',...
    'Position',[1/wFilesBG 6/hFilesBG 16/wFilesBG 4/hFilesBG],'Callback',@loadDicomImagesButton_Callback);

loadJPGImagesButton = uicontrol('Style','pushbutton','Parent',filesBG,'Units','normalized',...
    'String','Load JPG Images',...
    'Position',[1/wFilesBG 1/hFilesBG 16/wFilesBG 4/hFilesBG],'Callback',@loadJPGImagesButton_Callback);

%% Image ListBox
wListBG = 18;
hListBG = 27;

imagelistBG = uibuttongroup('Units','Normalized','Title','Image List',...
    'Position',[1/wMax 60/hMax wFilesBG/wMax hListBG/hMax]);

imageListBox = uicontrol('Style','listbox','Parent',imagelistBG,'Units','normalized',...
    'BackgroundColor','white','Tag','imageListBox',...
    'Position',[1/wListBG 11/hListBG 16/wListBG 16/hListBG],'Callback',@imageListBox_Callback);

saveJPGButton = uicontrol('Style','pushbutton','Parent',imagelistBG,'Units','normalized',...
    'String','Save Slice As JPG',...
    'Position',[1/wListBG 6/hListBG 16/wListBG 4/hListBG],'Callback',@saveJPGButton_Callback);

saveDICOMButton = uicontrol('Style','pushbutton','Parent',imagelistBG,'Units','normalized',...
    'String','Save Slice As DICOM',...
    'Position',[1/wListBG 1/hListBG 16/wListBG 4/hListBG],'Callback',@saveDICOMButton_Callback);

%% Original Patient Parameters Handles
wOrgBG = 18;
hOrgBG = 35;

orgParameterBG = uibuttongroup('Units','Normalized','Title','Information',...
    'Position',[1/wMax 24/hMax wOrgBG/wMax hOrgBG/hMax]);

familyNameLabel = uicontrol('Style','text','Parent',orgParameterBG,'Units','normalized',...
    'String','Fimaly Name',...
    'Position',[1/wOrgBG 31/hOrgBG 7/wOrgBG 3/hOrgBG]);

familyNameEdit = uicontrol('Style','edit','Parent',orgParameterBG,'Units','normalized',...
    'Tag','familyNameEdit','Enable','off',...
    'Position',[9/wOrgBG 31/hOrgBG 8/wOrgBG 3/hOrgBG]);

givenNameLabel = uicontrol('Style','text','Parent',orgParameterBG,'Units','normalized',...
    'String','Given Name',...
    'Position',[1/wOrgBG 27/hOrgBG 7/wOrgBG 3/hOrgBG]);

givenNameEdit = uicontrol('Style','edit','Parent',orgParameterBG,'Units','normalized',...
    'Tag','givenNameEdit','Enable','off',...
    'Position',[9/wOrgBG 27/hOrgBG 8/wOrgBG 3/hOrgBG]);

patientIDLabel = uicontrol('Style','text','Parent',orgParameterBG,'Units','normalized',...
    'String','ID',...
    'Position',[1/wOrgBG 23/hOrgBG 7/wOrgBG 3/hOrgBG]);

patientIDEdit = uicontrol('Style','edit','Parent',orgParameterBG,'Units','normalized',...
    'Tag','patientIDEdit','Enable','off',...
    'Position',[9/wOrgBG 23/hOrgBG 8/wOrgBG 3/hOrgBG]);

patientBirthDateLabel = uicontrol('Style','text','Parent',orgParameterBG,'Units','normalized',...
    'String','Birthdate',...
    'Position',[1/wOrgBG 19/hOrgBG 7/wOrgBG 3/hOrgBG]);

patientBirthDateEdit = uicontrol('Style','edit','Parent',orgParameterBG,'Units','normalized',...
    'Tag','patientBirthDateEdit','Enable','off',...
    'Position',[9/wOrgBG 19/hOrgBG 8/wOrgBG 3/hOrgBG]);

studyIDLabel = uicontrol('Style','text','Parent',orgParameterBG,'Units','normalized',...
    'String','Study ID',...
    'Position',[1/wOrgBG 15/hOrgBG 7/wOrgBG 3/hOrgBG]);

studyIDEdit = uicontrol('Style','edit','Parent',orgParameterBG,'Units','normalized',...
    'Tag','studyIDEdit','Enable','off',...
    'Position',[9/wOrgBG 15/hOrgBG 8/wOrgBG 3/hOrgBG]);

studyDateLabel = uicontrol('Style','text','Parent',orgParameterBG,'Units','normalized',...
    'String','Study Date',...
    'Position',[1/wOrgBG 11/hOrgBG 7/wOrgBG 3/hOrgBG]);

studyDateEdit = uicontrol('Style','edit','Parent',orgParameterBG,'Units','normalized',...
    'Tag','studyDateEdit','Enable','off',...
    'Position',[9/wOrgBG 11/hOrgBG 8/wOrgBG 3/hOrgBG]);

sliceLocationLabel = uicontrol('Style','text','Parent',orgParameterBG,'Units','normalized',...
    'String','Slice Location',...
    'Position',[1/wOrgBG 7/hOrgBG 7/wOrgBG 3/hOrgBG]);

sliceLocationEdit = uicontrol('Style','edit','Parent',orgParameterBG,'Units','normalized',...
    'Tag','sliceLocationEdit','Enable','off',...
    'Position',[9/wOrgBG 7/hOrgBG 8/wOrgBG 3/hOrgBG]);

instanceNumberLabel = uicontrol('Style','text','Parent',orgParameterBG,'Units','normalized',...
    'String','Instance Number',...
    'Position',[1/wOrgBG 1/hOrgBG 7/wOrgBG 5/hOrgBG]);

instanceNumberEdit = uicontrol('Style','edit','Parent',orgParameterBG,'Units','normalized',...
    'Tag','instanceNumberEdit','Enable','off',...
    'Position',[9/wOrgBG 1/hOrgBG 8/wOrgBG 5/hOrgBG]);

%% New Patient Parameters Handles
wNewBG = 18;
hNewBG = 22;

newParameterBG = uibuttongroup('Units','Normalized','Title','Anonymized Information',...
    'Position',[1/wMax 1/hMax wNewBG/wMax hNewBG/hMax]);

nFamilyNameLabel = uicontrol('Style','text','Parent',newParameterBG,'Units','normalized',...
    'String','Fimaly Name',...
    'Position',[1/wNewBG 18/hNewBG 7/wNewBG 3/hNewBG]);

nFamilyNameEdit = uicontrol('Style','edit','Parent',newParameterBG,'Units','normalized',...
    'Tag','nFamilyNameEdit',...
    'Position',[9/wNewBG 18/hNewBG 8/wNewBG 3/hNewBG]);

nGivenNameLabel = uicontrol('Style','text','Parent',newParameterBG,'Units','normalized',...
    'String','Given Name',...
    'Position',[1/wNewBG 14/hNewBG 7/wNewBG 3/hNewBG]);

nGivenNameEdit = uicontrol('Style','edit','Parent',newParameterBG,'Units','normalized',...
    'Tag','nGivenNameEdit',...
    'Position',[9/wNewBG 14/hNewBG 8/wNewBG 3/hNewBG]);

nPatientIDLabel = uicontrol('Style','text','Parent',newParameterBG,'Units','normalized',...
    'String','ID',...
    'Position',[1/wNewBG 10/hNewBG 7/wNewBG 3/hNewBG]);

nPatientIDEdit = uicontrol('Style','edit','Parent',newParameterBG,'Units','normalized',...
    'Tag','nPatientIDEdit',...
    'Position',[9/wNewBG 10/hNewBG 8/wNewBG 3/hNewBG]);

nPatientBirthDateLabel = uicontrol('Style','text','Parent',newParameterBG,'Units','normalized',...
    'String','Birthdate',...
    'Position',[1/wNewBG 6/hNewBG 7/wNewBG 3/hNewBG]);

nPatientBirthDateEdit = uicontrol('Style','edit','Parent',newParameterBG,'Units','normalized',...
    'Tag','nPatientBirthDateEdit',...
    'Position',[9/wNewBG 6/hNewBG 8/wNewBG 3/hNewBG]);

saveAnonymizedButton = uicontrol('Style','pushbutton','Parent',newParameterBG,'Units','normalized',...
    'String','Save Anony. DICOM Images',...
    'Position',[1/wNewBG 1/hNewBG 16/wNewBG 4/hNewBG],'Callback',@saveAnonymizedButton_Callback);

%% Prostate Zones
wZoneBG = 16;
hZoneBG = 18;

%% TZ
tzBG = uibuttongroup('Units','Normalized','Title','Transitional Zone',...
    'BackgroundColor','red','Position',[83/wMax 81/hMax wZoneBG/wMax hZoneBG/hMax]);

markTZButton = uicontrol('Style','pushbutton','Parent',tzBG,'Units','normalized',...
    'String','Mark (Edit) TZ',...
    'Position',[1/wZoneBG 14/hZoneBG 14/wZoneBG 4/hZoneBG],'Callback',@markTZButton_Callback);

clearTZButton = uicontrol('Style','pushbutton','Parent',tzBG,'Units','normalized',...
    'String','Clear TZ',...
    'Position',[1/wZoneBG 9/hZoneBG 14/wZoneBG 4/hZoneBG],'Callback',@clearTZButton_Callback);

areaTZLabel = uicontrol('Style','text','Parent',tzBG,'Units','normalized',...
    'String','Area',...
    'Position',[1/wZoneBG 5/hZoneBG 6/wZoneBG 3/hZoneBG]);

areaTZEdit = uicontrol('Style','edit','Parent',tzBG,'Units','normalized',...
    'Tag','areaTZEdit','Enable','off',...
    'Position',[8/wZoneBG 5/hZoneBG 7/wZoneBG 3/hZoneBG]);

volumeTZLabel = uicontrol('Style','text','Parent',tzBG,'Units','normalized',...
    'String','Volume',...
    'Position',[1/wZoneBG 1/hZoneBG 6/wZoneBG 3/hZoneBG]);

volumeTZEdit = uicontrol('Style','edit','Parent',tzBG,'Units','normalized',...
    'Tag','volumeTZEdit','Enable','off',...
    'Position',[8/wZoneBG 1/hZoneBG 7/wZoneBG 3/hZoneBG]);

%% PZ
pzBG = uibuttongroup('Units','Normalized','Title','Peripheral Zone',...
    'BackgroundColor','green','Position',[83/wMax 62/hMax wZoneBG/wMax hZoneBG/hMax]);

markPZButton = uicontrol('Style','pushbutton','Parent',pzBG,'Units','normalized',...
    'String','Mark (Edit) PZ',...
    'Position',[1/wZoneBG 14/hZoneBG 14/wZoneBG 4/hZoneBG],'Callback',@markPZButton_Callback);

clearPZButton = uicontrol('Style','pushbutton','Parent',pzBG,'Units','normalized',...
    'String','Clear PZ',...
    'Position',[1/wZoneBG 9/hZoneBG 14/wZoneBG 4/hZoneBG],'Callback',@clearPZButton_Callback);

areaPZLabel = uicontrol('Style','text','Parent',pzBG,'Units','normalized',...
    'String','Area',...
    'Position',[1/wZoneBG 5/hZoneBG 6/wZoneBG 3/hZoneBG]);

areaPZEdit = uicontrol('Style','edit','Parent',pzBG,'Units','normalized',...
    'Tag','areaPZEdit','Enable','off',...
    'Position',[8/wZoneBG 5/hZoneBG 7/wZoneBG 3/hZoneBG]);

volumePZLabel = uicontrol('Style','text','Parent',pzBG,'Units','normalized',...
    'String','Volume',...
    'Position',[1/wZoneBG 1/hZoneBG 6/wZoneBG 3/hZoneBG]);

volumePZEdit = uicontrol('Style','edit','Parent',pzBG,'Units','normalized',...
    'Tag','volumePZEdit','Enable','off',...
    'Position',[8/wZoneBG 1/hZoneBG 7/wZoneBG 3/hZoneBG]);

%% CZ
czBG = uibuttongroup('Units','Normalized','Title','Central Zone',...
    'BackgroundColor','blue','Position',[83/wMax 43/hMax wZoneBG/wMax hZoneBG/hMax]);

markCZButton = uicontrol('Style','pushbutton','Parent',czBG,'Units','normalized',...
    'String','Mark (Edit) CZ',...
    'Position',[1/wZoneBG 14/hZoneBG 14/wZoneBG 4/hZoneBG],'Callback',@markCZButton_Callback);

clearCZButton = uicontrol('Style','pushbutton','Parent',czBG,'Units','normalized',...
    'String','Clear CZ',...
    'Position',[1/wZoneBG 9/hZoneBG 14/wZoneBG 4/hZoneBG],'Callback',@clearCZButton_Callback);

areaCZLabel = uicontrol('Style','text','Parent',czBG,'Units','normalized',...
    'String','Area',...
    'Position',[1/wZoneBG 5/hZoneBG 6/wZoneBG 3/hZoneBG]);

areaCZEdit = uicontrol('Style','edit','Parent',czBG,'Units','normalized',...
    'Tag','areaCZEdit','Enable','off',...
    'Position',[8/wZoneBG 5/hZoneBG 7/wZoneBG 3/hZoneBG]);

volumeCZLabel = uicontrol('Style','text','Parent',czBG,'Units','normalized',...
    'String','Volume',...
    'Position',[1/wZoneBG 1/hZoneBG 6/wZoneBG 3/hZoneBG]);

volumeCZEdit = uicontrol('Style','edit','Parent',czBG,'Units','normalized',...
    'Tag','volumeCZEdit','Enable','off',...
    'Position',[8/wZoneBG 1/hZoneBG 7/wZoneBG 3/hZoneBG]);

%% Tumour
tumourBG = uibuttongroup('Units','Normalized','Title','Tumour',...
    'BackgroundColor','cyan','Position',[83/wMax 24/hMax wZoneBG/wMax hZoneBG/hMax]);

markTumourButton = uicontrol('Style','pushbutton','Parent',tumourBG,'Units','normalized',...
    'String','Mark (Edit) Tumour',...
    'Position',[1/wZoneBG 14/hZoneBG 14/wZoneBG 4/hZoneBG],'Callback',@markTumourButton_Callback);

clearTumourButton = uicontrol('Style','pushbutton','Parent',tumourBG,'Units','normalized',...
    'String','Clear Tumour',...
    'Position',[1/wZoneBG 9/hZoneBG 14/wZoneBG 4/hZoneBG],'Callback',@clearTumourButton_Callback);

areaTumourLabel = uicontrol('Style','text','Parent',tumourBG,'Units','normalized',...
    'String','Area',...
    'Position',[1/wZoneBG 5/hZoneBG 6/wZoneBG 3/hZoneBG]);

areaTumourEdit = uicontrol('Style','edit','Parent',tumourBG,'Units','normalized',...
    'Tag','areaTumourEdit','Enable','off',...
    'Position',[8/wZoneBG 5/hZoneBG 7/wZoneBG 3/hZoneBG]);

volumeTumourLabel = uicontrol('Style','text','Parent',tumourBG,'Units','normalized',...
    'String','Volume',...
    'Position',[1/wZoneBG 1/hZoneBG 6/wZoneBG 3/hZoneBG]);

volumeTumourEdit = uicontrol('Style','edit','Parent',tumourBG,'Units','normalized',...
    'Tag','volumeTumourEdit','Enable','off',...
    'Position',[8/wZoneBG 1/hZoneBG 7/wZoneBG 3/hZoneBG]);

%% Save Marking
wMarkBG = 16;
hMarkBG = 22;

markBG = uibuttongroup('Units','Normalized','Title','Marking',...
    'BackgroundColor','magenta','Position',[83/wMax 1/hMax wMarkBG/wMax hMarkBG/hMax]);

saveSliceMarkButton = uicontrol('Style','pushbutton','Parent',markBG,'Units','normalized',...
    'String','Save for Current Slice',...
    'Position',[1/wMarkBG 18/hMarkBG 14/wMarkBG 3/hMarkBG],'Callback',@saveSliceMarksButton_Callback);

loadSliceMarkButton = uicontrol('Style','pushbutton','Parent',markBG,'Units','normalized',...
    'String','Load for Current Slice',...
    'Position',[1/wMarkBG 14/hMarkBG 14/wMarkBG 3/hMarkBG],'Callback',@loadSliceMarksButton_Callback);

saveAllMarkButton = uicontrol('Style','pushbutton','Parent',markBG,'Units','normalized',...
    'String','Save for All Slices',...
    'Position',[1/wMarkBG 10/hMarkBG 14/wMarkBG 3/hMarkBG],'Callback',@saveAllMarksButton_Callback);

loadAllMarkButton = uicontrol('Style','pushbutton','Parent',markBG,'Units','normalized',...
    'String','Load for All Slices',...
    'Position',[1/wMarkBG 6/hMarkBG 14/wMarkBG 3/hMarkBG],'Callback',@loadAllMarksButton_Callback);

show3DButton = uicontrol('Style','pushbutton','Parent',markBG,'Units','normalized',...
    'String','Show 3D',...
    'Position',[1/wMarkBG 1/hMarkBG 14/wMarkBG 4/hMarkBG],'Callback',@show3DButton_Callback);



set(hFig, 'Visible','on');

end