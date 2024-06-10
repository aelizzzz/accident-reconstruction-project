function output = generateKeyfile(inputFile, outputPath)
    addpath(outputPath)
    format long g

    Sim_Folder = outputPath;
    caseFile = strsplit(inputFile, '/');
    caseFile = caseFile{end};
    caseFile = strsplit(caseFile, '_');
    caseFile = caseFile(1:end-1);
    caseFile = strjoin(caseFile, '_');

    T = importdata(inputFile);
    joint_coordinates = []; joint_names = [];

    for i = [1:length(T)]
        coordinates = extractBetween(T(i), "(", ")");
        coordinates = split(coordinates, ",");
        coordinates = str2double(coordinates(:, 1))';

        % Seems that all joint cooridnates are rotated +90 deg in Z
        % They are also translated about 980 in Z
        xyz_corrected_coordinates = [coordinates(2) -coordinates(1) coordinates(3) - 980];
        joint_coordinates = [joint_coordinates; xyz_corrected_coordinates];

        name = extractBetween(T(i), ":", ",");
        joint_names = [joint_names; name(1)];
    end

    % Remove not needed joints
    joint_coordinates([1 3 7 19 24 25 27:35 38 43 44 46:54], :) = [];
    joint_names([1 3 7 19 24 25 27:35 38 43 44 46:54], :) = [];

    % List of corresponding nodes in THUMS
    THUMS_Nodes = [83010485 % pelvis
                   82076311 % left_knee
                   82000527 % left_ankle
                   82006712 % left_foot
                   81076311 % right_knee
                   81000527 % right_ankle
                   81006712 % right_foot
                   89563672 % spine1
                   89063523 % spine2
                   89062111 % spine3
                   89559754 % neck
                   88267038 % head
                   88264828 % jaw
                   88258190 % left_eye
                   88179928 % right_eye
                   86007149 % left_shoulder
                   86006142 % left_elbow
                   86002439 % left_wrist
                   86000600 % left_index1
                   86000667 % left_middle1
                   86000832 % left_thumb2
                   86000409 % left_thumb3
                   85007149 % right_shoulder
                   85006142 % right_elbow
                   85002439 % right_wrist
                   85000600 % right_index1
                   85000667 % right_middle1
                   85000832 % right_thumb2
                   85000409]; % right_thumb3

    %% Print a keyword

    Folder = char(strcat(Sim_Folder));
    cd(Folder)
    outputFile = fullfile(outputPath, strcat(caseFile, '_Positioning_cables.k')); % Construct path using fullfile
    Output = fopen(outputFile, 'w'); % Open file in write mode
    k = 1;
    Line{k} = ['*KEYWORD']; k = k + 1;
    Line{k} = ['*MAT_CABLE_DISCRETE_BEAM']; k = k + 1;
    Line{k} = ['   4736313    7.8E-6       0.0         0       0.5    1.0E13      10.0         0']; k = k + 1;
    Line{k} = ['$']; k = k + 1;
    Line{k} = ['*MAT_DAMPER_VISCOUS']; k = k + 1;
    Line{k} = ['   4736314       0.5']; k = k + 1;
    Line{k} = ['*SECTION_BEAM']; k = k + 1;
    Line{k} = ['   4736313         6       0.0       0.0       0.0       0.0       0.0']; k = k + 1;
    Line{k} = ['      10.0       0.0         0       1.0       0.0       0.0       0.0       0.0']; k = k + 1;
    Line{k} = ['$']; k = k + 1;
    Line{k} = ['*SECTION_DISCRETE']; k = k + 1;
    Line{k} = ['   4736314         0       0.0       0.0       0.0       0.0']; k = k + 1;
    Line{k} = ['       0.0       0.0']; k = k + 1;
    Line{k} = ['*PART']; k = k + 1;
    Line{k} = ['']; k = k + 1;
    Line{k} = ['   4736313   4736313   4736313         0         0         0         0         0']; k = k + 1;
    Line{k} = ['$']; k = k + 1;
    Line{k} = ['*PART']; k = k + 1;
    Line{k} = ['']; k = k + 1;
    Line{k} = ['   4736314   4736314   4736314         0         0         0         0         0']; k = k + 1;
    Line{k} = ['*NODE']; k = k + 1;

    % Write target node coordinates
    node_no = 44384093;

    for j = [1:1:length(joint_names)]
        Line{k} = [num2str(node_no), ',', num2str(joint_coordinates(j, 1)), ',', num2str(joint_coordinates(j, 2)), ',', num2str(joint_coordinates(j, 3)), ',7,0']; k = k + 1;
        node_no = node_no + 1;
    end

    Line{k} = ['*ELEMENT_BEAM']; k = k + 1;
    Line{k} = ['$    eid     pid     nid     nid       0']; k = k + 1;

    element_no = 4705122;
    node_no = 44384093;

    for j = [1:1:length(joint_names)]
        Line{k} = [' ', num2str(element_no), ' 4736313', num2str(node_no), num2str(THUMS_Nodes(j)), '       0']; k = k + 1;
        element_no = element_no + 1;
        node_no = node_no + 1;
    end

    Line{k} = ['*ELEMENT_DISCRETE']; k = k + 1;
    Line{k} = ['$    eid     pid     nid     nid       0             1.0       0             0.0']; k = k + 1;

    element_no = 4203010;
    node_no = 44384093;

    for j = [1:1:length(joint_names)]
        Line{k} = [' ', num2str(element_no), ' 4736314', num2str(node_no), num2str(THUMS_Nodes(j)), '       0']; k = k + 1;
        element_no = element_no + 1;
        node_no = node_no + 1;
    end

    Line{k} = ['*ELEMENT_MASS_NODE_SET']; k = k + 1;
    Line{k} = [' 463497145180041             0.5       0']; k = k + 1;
    Line{k} = ['*SET_NODE_LIST']; k = k + 1;
    Line{k} = ['  45180041       0.0       0.0       0.0       0.0']; k = k + 1;
    Line{k} = ['$      nid       nid       nid       nid       nid       nid       nid       nid']; k = k + 1;

    node_no = 44384093;
    bb = [(44384093:1:(length(THUMS_Nodes) + 44384092))]';
    bb = [THUMS_Nodes bb];
    Line{k} = ['  ', num2str(bb(1, 1)), '  ', num2str(bb(1, 2)), '  ', num2str(bb(2, 1)), '  ', num2str(bb(2, 2)), '  ', num2str(bb(3, 1)), '  ', num2str(bb(3, 2)), '  ', num2str(bb(4, 1)), '  ', num2str(bb(4, 2))]; k = k + 1;
    Line{k} = ['  ', num2str(bb(5, 1)), '  ', num2str(bb(5, 2)), '  ', num2str(bb(6, 1)), '  ', num2str(bb(6, 2)), '  ', num2str(bb(7, 1)), '  ', num2str(bb(7, 2)), '  ', num2str(bb(8, 1)), '  ', num2str(bb(8, 2))]; k = k + 1;
    Line{k} = ['  ', num2str(bb(9, 1)), '  ', num2str(bb(9, 2)), '  ', num2str(bb(10, 1)), '  ', num2str(bb(10, 2)), '  ', num2str(bb(11, 1)), '  ', num2str(bb(11, 2)), '  ', num2str(bb(12, 1)), '  ', num2str(bb(12, 2))]; k = k + 1;
    Line{k} = ['  ', num2str(bb(13, 1)), '  ', num2str(bb(13, 2)), '  ', num2str(bb(14, 1)), '  ', num2str(bb(14, 2)), '  ', num2str(bb(15, 1)), '  ', num2str(bb(15, 2)), '  ', num2str(bb(16, 1)), '  ', num2str(bb(16, 2))]; k = k + 1;
    Line{k} = ['  ', num2str(bb(17, 1)), '  ', num2str(bb(17, 2)), '  ', num2str(bb(18, 1)), '  ', num2str(bb(18, 2)), '  ', num2str(bb(19, 1)), '  ', num2str(bb(19, 2)), '  ', num2str(bb(20, 1)), '  ', num2str(bb(20, 2))]; k = k + 1;
    Line{k} = ['  ', num2str(bb(21, 1)), '  ', num2str(bb(21, 2)), '  ', num2str(bb(22, 1)), '  ', num2str(bb(22, 2)), '  ', num2str(bb(23, 1)), '  ', num2str(bb(23, 2)), '  ', num2str(bb(24, 1)), '  ', num2str(bb(24, 2))]; k = k + 1;
    Line{k} = ['  ', num2str(bb(25, 1)), '  ', num2str(bb(25, 2)), '  ', num2str(bb(26, 1)), '  ', num2str(bb(26, 2)), '  ', num2str(bb(27, 1)), '  ', num2str(bb(27, 2)), '  ', num2str(bb(28, 1)), '  ', num2str(bb(28, 2))]; k = k + 1;
    Line{k} = ['  ', num2str(bb(29, 1)), '  ', num2str(bb(29, 2))]; k = k + 1;
    Line{k} = ['*END']; k = k + 1;

    for m = 1:length(Line)
        fprintf(Output, '%s\n', Line{m});
    end

end
