function energy = daugmanOperator( image , x , y , r , varargin )
%daugmanOperator, function that estimates the daugman integral. This can be
%used to detect the pupil, and iris boundary. (but can also be used in more
%general to detect circles in images. To estimate the integral a finite
%number of samples (default 36) on the circle is computed. In case of
%eyelid occlusion (covering the upper and lower part of the limbus boundary) 
%the bow-tie sample scheme should be used, which is the default. By the
%default setting a circle is used, but it is also possible to use an
%Ellipse instead.
%   
%   SYNOPSIS
%       - energy = daugmanOperator( image, 100, 100, 10)
%
%   INPUTS
%       - image <double>, the image opun which the integral is computed.
%       - x <integer>, x-position in px of the center from the circle
%       - y <integer>, y-position in px of the center from the circle
%       - r <integer>, radius in px for the circle
%
%   OUTPUT
%       - energy <double>, the total value of the integral for the
%       specified circle.
%
%   DEPENDANCIES
%       - 
%
%   HISTORY
%       - 1 february 2017, cleaned for the repository
%
%   REFERENCES
%       (1) How iris recognition works, Daugman, J.G. 
%
%   AUTHOR
%       F.C. Martin <frank@grafikus.nl>
%       19th of May 2015
%
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -    
    
    % Check/read the input
    p = inputParser;
    addRequired(p, 'image', @ismatrix);
    addRequired(p, 'x', @isnumeric);
    addRequired(p, 'y', @isnumeric);
    addRequired(p, 'r', @isnumeric);
    addOptional(p, 'sampleShape', 'circle');
    addOptional(p, 'ry', -1, @isnumeric);
    addOptional(p, 'sampleFrequency', 36, @isnumeric);
    addOptional(p, 'debug', 0);
    parse(p,image,x,y,r,varargin{:});
    
    nSamples = p.Results.sampleFrequency;
    sampleShape = p.Results.sampleShape;
    elipseY = p.Results.ry;
    debug = p.Results.debug;
    
    % Calculate angles on which the circle is sampled
    [n, m] = size(image);
    j = 1:nSamples; % number of samples in array
    alpha = (360/nSamples)*j;
    
    % if the limbus is used, only the left and right part is used
    if strcmp(sampleShape,'bowtie')
        alpha = alpha( (alpha > 45 & alpha < 135) | (alpha > 225 & alpha < 315) );
    end
    
    % rotate system 22.5 degrees to set -22.5 to zero (needed for creating
    % the M matrix, see below.
    theta = 45*((alpha + 22.5)/45); % rotate system 22.5 degrees
    
    % Construct sample positions
    x = round(x + r * cosd(alpha));
    if elipseY ~= -1 % if elipse is used
        y = round(y + elipseY * sind(alpha));
    else % use the default circle
        y = round(y + r * sind(alpha));
    end
    
    % filter out of image x and y's
    s = x > 2 & x < n-1 & y > 2 & y < m-1;
    x = x( s );
    y = y( s );
    theta = theta( s );
    g = sum(s); % numer of samples
   
    % Compute gradient matrixes for all angles
    M = [   sind(theta - 45),    sind(theta),           sind(theta + 45); 
            sind(theta - 90),    zeros(size(theta)),    sind(theta + 90);
            sind(theta - 135),   sind(-theta),          sind(theta + 135)];

    % Extract pixel values  
    I = [   image(sub2ind([n, m],x-1,y-1)),     image(sub2ind([n, m],x,y-1)),   image(sub2ind([n, m],x+1,y-1));
            image(sub2ind([n, m],x-1,y)),       image(sub2ind([n, m],x,y)),     image(sub2ind([n, m],x+1,y));
            image(sub2ind([n, m],x-1,y+1)),     image(sub2ind([n, m],x,y+1)),   image(sub2ind([n, m],x+1,y+1))];

    % Compute difference funcion
    diff = M.*double(I);
    
    % Calculate the energy of this potential center/radius
    energy = 0;
    for k = 1:g
        energy = energy + abs(sum(sum(diff(:,[k k+g k+2*g]))));
    end
    
     % display the selection pattern
    if debug
        henk = insertShape(image,'circle',[y',x',ones(size(x'))],'Color','red','LineWidth',1);
        imshow(henk);
    end
                    
end