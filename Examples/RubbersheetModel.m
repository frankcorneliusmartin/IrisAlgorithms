%%  Simple Usage - - - - - - - - - - - - - - - - - -

% Load the image
img = imread('example.jpg');

% Input parameters
xPosPupil = 625;
yPosPupil = 306;
rPupil = 70;
xPosIris = 625;
yPosIris = 306;
rIris = 250;

% Normalize the iris region according to daugmans model
irisRegion = rubberSheetNormalisation( img, xPosPupil, yPosPupil, rPupil , xPosIris , yPosIris , rIris, 'DebugMode', 1 );

% Show Resulting image
figure(2);
imshow(irisRegion);

%% Control Radial and Angular Samples - - - - - - - - - - - - - - - - - -
%  The following example show you how to define the number of samples in
%  angular and radial direction. Note that the number of the radial and
%  angular samples is unusable low, but good to demonstrate the parameters.

% Load the image
img = imread('example.jpg');

% Input parameters
xPosPupil = 625;
yPosPupil = 306;
rPupil = 70;
xPosIris = 625;
yPosIris = 306;
rIris = 250;

% Normalize the iris region according to daugmans model and defining the
% number of samples in radial and angular direction
irisRegion = rubberSheetNormalisation( img, xPosPupil, yPosPupil, rPupil , xPosIris , yPosIris , rIris, ...
    'DebugMode', 1,'RadiusSamples', 5,'AngleSamples', 10 ...
);

% Show Resulting image
figure(2);
imshow(irisRegion);

%% Turn Interpolation off - - - - - - - - - - - - - - - - - -
%  By default the samples are interpolated, however it is also possible to
%  use neirest neighbor interpolation (no interpolation). This speeds up
%  the computation, but is less preciese. 

% Load the image
img = imread('example.jpg');

% Input parameters
xPosPupil = 625;
yPosPupil = 306;
rPupil = 70;
xPosIris = 625;
yPosIris = 306;
rIris = 250;

% Normalize the iris region according to daugmans model and defining the
% number of samples in radial and angular direction
irisRegion = rubberSheetNormalisation( img, xPosPupil, yPosPupil, rPupil , xPosIris , yPosIris , rIris, ...
    'DebugMode', 0,'UseInterpolation', 0 ...
);

% Show Resulting image
figure(2);
imshow(irisRegion);