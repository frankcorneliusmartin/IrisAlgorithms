%% Find the Limbus boundary, with GUI
[minX, minY, minR, image] = daugmanCircleDetection();
imshow(image);

%% Find the Limbus boudary without GUI
im = imread('example.jpg');
[minX, minY, minR, image] = daugmanCircleDetection(im);
imshow(image);

%% Find the Pupil boudary 
im = imread('example.jpg');
[minX, minY, minR, image] = daugmanCircleDetection(im, 'Feature','pupil');
imshow(image);