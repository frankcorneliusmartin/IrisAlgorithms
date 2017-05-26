function image = rubberSheetNormalisation( img, xPosPupil, yPosPupil, rPupil , xPosIris , yPosIris , rIris , varargin )
%rubberSheetNormalisation, function that normalizes the iris region. This is
%the region between the pupil boundary and the limbus. This is done
%according to the rubber sheet model proposed by Daugman (1).
%   
%   SYNOPSIS
%       - image = rubberSheetNormalisation( img, xPosPupil, yPosPupil, rPupil , xPosIris , yPosIris , rIris )
%       - image = rubberSheetNormalisation( img, xPosPupil, yPosPupil, rPupil , xPosIris , yPosIris , rIris , 'DebugMode' , 1 )
%
%   INPUTS
%       - img <double>
%           Eye image from the cassini, preferably a NIR image. If no image
%           is supplied, a pop up will ask to select one.
%       - xPosPupil <integer>, yPosPupil <integer>, rPupil <integer>
%           The x,y-position of the pupil center and the pupil radius
%       - xPosIris <integer>, yPosIris <integer>, rIris <integer>
%           The x,y-position of the iris center and the iris radius
%       - varargin <optional>,  input scheme
%           'DebugMode': {0: off, 1: on} - if set to 1 shows extra info
%           'AngleSamples': <integer> - number of radial samples
%           'RadiusSamples': <integer> - number of radius samples
%           'UseInterpolation': <boolean> - if 1, the samples will be
%              interpolated else nearest neighbor interpolation is used.
%
%   OUTPUT
%       - image, containing the normalized iris region
%
%   DEPENDANCIES
%       - Communications Toolbox
%       - Computer Vision System Toolbox (for debugmode)
%
%   HISTORY
%       - 26th may 2017: removed Communications Toolbox
%       - 19th June 2016: added the interpolation option
%
%   REFERENCES
%   (1) How iris recognition works, Daugman, J.G. 
%
%   AUTHOR
%       F.C. Martin <frank@grafikus.nl>
%       19th of May 2015 - 26th may 2017
%
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    %todo: remove for-loop for line detection
    if(size(img, 3) == 3) % if RGB image is inputted
       img = rgb2gray(img);
    end
    
    % parse input
    p = inputParser();
    addRequired( p , 'xPosPupil' , @isnumeric );
    addRequired( p , 'yPosPupil' , @isnumeric );
    addRequired( p , 'rPupil' , @isnumeric );
    addRequired( p , 'xPosIris' , @isnumeric );
    addRequired( p , 'yPosIris' , @isnumeric );
    addRequired( p , 'rIris' , @isnumeric );
    addOptional( p , 'AngleSamples', 360 ,@isnumeric );
    addOptional( p , 'RadiusSamples', 360 ,@isnumeric );
    addOptional( p , 'DebugMode', 0, @isnumeric );
    addOptional( p , 'UseInterpolation', 1, @isnumeric );
    parse( p , xPosPupil, yPosPupil, rPupil , xPosIris , yPosIris , rIris , varargin{:} )
    
    % Note that internally matrix coordinates are used
    xp = p.Results.yPosPupil;
    yp = p.Results.xPosPupil; 
    rp = p.Results.rPupil;
    xi = p.Results.yPosIris;
    yi = p.Results.xPosIris;
    ri = p.Results.rIris;
    angleSamples = p.Results.AngleSamples;
    RadiusSamples = p.Results.RadiusSamples;
    debug = p.Results.DebugMode;
    interpolateQ = p.Results.UseInterpolation;
    
    % Initialize samples 
    angles = (0:pi/angleSamples:pi-pi/angleSamples) + pi/(2*angleSamples);%avoiding infinite slope
    r = 0:1/RadiusSamples:1;
    nAngles = length(angles);
    
    % Calculate pupil points and iris points that are on the same line
    x1 = ones(size(angles))*xi;
    y1 = ones(size(angles))*yi;
    x2 = xi + 10*sin(angles);
    y2 = yi + 10*cos(angles);
    dx = x2 - x1;
    dy = y2 - y1;
    slope = dy./dx;
    intercept = yi - xi .* slope;
    
    xout = zeros(nAngles,2);
    yout = zeros(nAngles,2);
    for i = 1:nAngles
        [xout(i,:),yout(i,:)] = linecirc(slope(i),intercept(i),xp,yp,rp);
    end
       
    % Get samples on limbus boundary
    xRightIris = yi + ri * cos(angles);
    yRightIris = xi + ri * sin(angles);
    xLeftIris = yi - ri * cos(angles);
    yLeftIris = xi - ri * sin(angles);
    
    
    % Get samples in radius direction
    xrt = (1-r)' * xout(:,1)' + r' * yRightIris;
    yrt = (1-r)' * yout(:,1)' + r' * xRightIris;
    xlt = (1-r)' * xout(:,2)' + r' * yLeftIris;
    ylt = (1-r)' * yout(:,2)' + r' * xLeftIris;
    
    % Create Normalized Iris Image
    if interpolateQ
        image = uint8(reshape(interp2(double(img),[yrt(:);ylt(:)],[xrt(:);xlt(:)]),length(r), 2*length(angles))');
    else
        image = reshape(img(sub2ind(size(img),round([xrt(:);xlt(:)]),round([yrt(:);ylt(:)]))),length(r), 2*length(angles));
    end
       
    % Show all points on original input image
    if debug
        
        img = insertShape(img, 'circle', [yrt(:),xrt(:),2*ones(size(xrt(:)))],'Color','r');
        img = insertShape(img, 'circle', [ylt(:),xlt(:),2*ones(size(xrt(:)))],'Color','r');
        
        figure('name','Sample scheme of the rubber sheet normalization');
        imshow(img);
        drawnow;
        
    end
    
end