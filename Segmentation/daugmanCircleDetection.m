function [minX, minY, minR, image] = daugmanCircleDetection( image , varargin )
%LBDaugmans (LB = Limbus Boundary) function that segments the limbus in an eye 
%   image. This function finds the limbus boundary using the method as 
%   described by (1) and (2), commonly called Daugmans method.
%   
%   SYNOPSIS
%       - [minX, minY, minR, image] = SBDaugmans()
%       - [minX, minY, minR, image] = SBDaugmans( img )
%       - [minX, minY, minR, image] = SBDaugmans( img , 'Feature', 'limbus')
%       - [minX, minY, minR, image] = SBDaugmans( img , 'DebugMode', 1)
%       - [minX, minY, minR, image] = SBDaugmans( img , 'EstimatedCenter', [200,400])
%
%   INPUTS
%       - image <optional>, <double>
%           Eye image from the cassini, preferably a NIR image. If no image
%           is supplied, a pop up will ask to select one.
%       - varargin <optional>,  input scheme
%           'DebugMode': {0: off, 1: on} - if set to 1 shows extra info
%           'EstimatedCenter': <double 2x1> - position of the pupil center
%           'Feature': {'limbus', 'pupil'} - which feature need to be detected 
%           'ASSStepSize': <double> - Stepsize of the Shrinking in ASSStack
%           'ASSFinalSize': <double 2x1> - the maximum size of the smallest
%               layer in ASSStack
%
%   OUTPUT
%       - minX <double>
%            Containing the center x-position
%       - minY <double>
%            Containing the center y-position
%       - minR <double> 
%            Containing the radius
%       - image <double>
%            Input image plus detected limbus or pupil
%
%   DEPENDANCIES
%       - Class: ASSStack > StackBase
%       - Function: daugmanOperator
%
%   HISTORY
%       - 26th may 2017: cleaned up for the repository
%       - 4th june 2015: updated comment section, updated functionnames
%
%   REFERENCES
%       (1) Iris Boundary Detection Using An Ellipse Integro Differential
%           Method, Shamsi, M. et al. 
%       (2) How iris recognition works, Daugman, J.G.
%
%   AUTHOR
%       F.C. Martin <frank@grafikus.nl>
%       4th of may 2015 - 26th may 2017
%
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    % if no image is provided, gui to the file
    if nargin < 1
        [filename,pathname,~] = uigetfile({'*.png';'*.jpg'},'Select Eye-image');
        image = imread([pathname, filesep, filename]);
    end
    
    if(size(image, 3) == 3) % if RGB image is inputted
        image = rgb2gray(image);
    end
    
    % Check/read the input
    p = inputParser;
    addRequired(p, 'image', @ismatrix);
    addOptional(p, 'DebugMode', 0);
    addOptional(p, 'EstimatedCenter',0);
    addOptional(p, 'Feature', 'limbus', @(x) any(validatestring(x,{'pupil','limbus'})));
    addOptional(p, 'ASSStepSize',2,@isnumeric);
    addOptional(p, 'ASSFinalSize',0); 
    parse(p,image,varargin{:});
    
    debugMode = p.Results.DebugMode;
    estimatedCenter = p.Results.EstimatedCenter;
    feature = p.Results.Feature;
    stepSize = p.Results.ASSStepSize;
    finalSize = p.Results.ASSFinalSize;
    
    % set parameters according to feature
    if strcmp(feature,'pupil')
        finalSize_temp = [21, 21]; 
        minR = 2;
        rRange = [0.2, 1.2];
        sampleShape = 'circle';
    elseif strcmp(feature, 'limbus')
        finalSize_temp = [25, 25];
        minR = 9;
        rRange = [0.5, 1.5];
        sampleShape = 'bowtie';
    end
    
    if ~finalSize 
        finalSize = finalSize_temp;
    end
    
    % Save original image
    input_image = image;

    
    % pre-processing
    image=imcomplement(imfill(imcomplement(image),'holes'));
    
    % Save pre-processed image
    if debugMode
        pre_image = image;
    end
    
    % Create an Average Square Schrinking Stack, the maximum size of the
    % smallest shrunken image is 11x11 pixels.
    stack = ASSStack(image, finalSize, stepSize);
    
    % Check if the iris center needs to be estimated or that the pupil
    % center is profided.
    if estimatedCenter
        minX = estimatedCenter(1)/stepSize^stack.length();
        minY = estimatedCenter(2)/stepSize^stack.length();
    else
        % Assume that the pixel containing the highest value determines the
        % possible position for the pupil(/iris) center. 
        data = stack.getStack('end');
        [nd, md] = size(data);
        [minX, minY] = ind2sub([nd, md],find(data == min(min(data(5:end-5,5:end-5)))));
    end
    
    % Show extra information of stack
    if debugMode
        stackInfo = [nd,md,minX,minY,minR];
    end
    
    % For each layer in the stack compute the center and radius to keep
    % increasing the accuracy and narrowing the search region
    for N = (stack.length()-1):-1:1
        
        % Get previous stack size
        [n1,m1] = size(stack.getStack(N+1));
        
        % Retrieve current layer
        layer = stack.getStack(N);
        [n, m] = size(layer);
        
        % Trace back the indexes from the smallest image to the current layer image.
        % Assuming that all pixels have been used in the creation of the stack
        % and that no pixels where lost by croping
        idx = ((minX)/n1)*n;
        idy = ((minY)/m1)*m;
        idr = (minR/m1)*m;
        
        % For all possible center/radius canidates compute the energy as
        % described in Fast Algorithm for Iris Localization... from
        % Mahboubeh Shamsi.
        minE = -1;
        
        % possible positions
        x = idx-stepSize:idx+stepSize;
        y = idy-stepSize:idy+stepSize;
        
        for xp = x
            for yp = y
                
                % First itteration the puil radius search region needs to
                % be very wide as the pupil radius is hard to estimate
                % without image information
                if stack.length()-1 == N
                    lR = rRange(1)*idr;
                    if lR < 1
                        lR = 1;
                    end
                    rR = rRange(2)*idr;
                else
                    lR = 0.9*idr;
                    rR = 1.1*idr;
                end
                
                for rx = floor(lR):1:ceil(rR);
                   
                    % Calculate the Daugman Operator
                    E = daugmanOperator( layer , xp , yp , rx , 'sampleShape', sampleShape);

                    % If the new found energy is lower, save the center and
                    % radius. Also if this is the first calculated energy
                    % (-1) save the values. 
                    if minE == -1 || E > minE
                        minE = E;
                        minX = xp;
                        minY = yp;
                        minR = rx;
                    end 
                end
            end
        end        
    end
    
    % Draw result
    image = insertShape(input_image, 'circle', [minY,minX,minR]);
    
    % Show the resulting image/data in debugMode-mode
    if debugMode
        
        % Plot original image
        figure('name', 'Input Image (could be grayscaled)');
        imshow(input_image);
        
        % Plot pre-processed image
        figure('name', 'Pre-processed Image');
        imshow(pre_image);
        
        %Show stack
        disp(stack);
        
        % Create output image including segmented limbus
        figure('name', 'Segmentation Result');
        imshow(insertShape(input_image, 'circle', [minY,minX,minR]));
        
        % Show stack information
        disp('--------------------');
        disp('STACK INFORMATION');
        disp(['Final Size = [',num2str(stackInfo(1)),',',num2str(stackInfo(2)),']']);
        disp(['Estimated center = [',num2str(stackInfo(3)),',',num2str(stackInfo(4)),']']);
        disp(['Assumed Radius on Final Size = ',num2str(stackInfo(5))]);
        disp('--------------------');
    end
end