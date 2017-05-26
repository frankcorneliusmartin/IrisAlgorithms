classdef ASSStack < StackBase
%AverageSquareShrinking function that creates a shrunken image.
%   The Average Square Shrinking (ASS) process will divide the original
%   image into squares. The average intensity of this square is calculated
%   and this is then the new pixel value of the schrunken image.
%   
%   INPUT
%       - image, image that needs to be shrunk
%       - finalSize, [w h] for the final shrunken image
%       - stepSize, value that indicates which factor the image should be
%           shrunken for each step.

% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% PUBLIC METHODS
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    methods(Access = public)
        
        % Constructor
        function this = ASSStack( image , finalSize , stepSize )
            
            
            % Check input parameters
            if nargin < 3
                stepSize = 3;
            end
            
            if nargin < 2
                finalSize = [11, 11];
            end
            
            % if no image is provided, gui to the file
            if nargin < 1
                %[filename,pathname,~] = uigetfile({'*.png','*.jpg'},'Select Image That Needs to be ASS Stacked');
                filename = '1.png';
                pathname = 'C:\Users\s102099\Google Drive\_iOptics Afstuderen\_Data\IR Monochrome';
                image = imread([pathname, filesep, filename]);
            end
            
            if(size(image, 3) == 3) % if RGB image is inputted
                image = rgb2gray(image);
            end
            
            % call super constructor
            this@StackBase( image , finalSize , stepSize );
           
        end 
        
        % getStack - returns the image_stack propertie. Note that shrunken
        % images are padded with zeros. By supplying the argument layer =
        % 'end' only the lowest of the stack is returned.
        function stack = getStack( this , layer )
            
            % Get the full stack
            stack = this.stack;
            
            % Only if layer is specified
            if nargin > 1
                % If only the lowest layer is required
                if strcmp(layer,'end')
                    stack = this.stack(1:this.x(end),1:this.y(end),end);
                end

                if isnumeric(layer)
                    if layer > 0 && layer <= this.z
                        stack = this.stack(1:this.x(layer),1:this.y(layer),layer);
                    else
                        warning('The specified layer is not within the domain! The full stack is returned!');
                    end
                end
            end
        end
        
         % getLayer - returns the layer specified by j.
        function r = getLayer( this )
            r = this.stack(1:this.x(this.j),1:this.y(this.j),this.j);
        end
        
        % setLayer set layer specified by j
        function setLayer( this , layer )
             this.stack(1:this.x(this.j),1:this.y(this.j),this.j) = layer;
        end
    end
        

    
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% PROTECTED METHODS
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
methods(Access = protected)
    
    % constructStack - according to the Average Square Shrinking process.
    function constructStack( this , image , varargin )
        % Initialize properties
        [this.x(1), this.y(1)] = size( image );
        this.stack = zeros(this.x(1), this.y(1), 1);

        % Add original layer to the stack
        this.z = 1;
        this.stack(:,:,this.z ) = double(image)/double(max(image(:)));

        cur_image = this.stack(:,:,this.z );

        % load arguments
        finalSize = varargin{1}; %todo: make this right in the constructor
        stepSize = varargin{2};
        
        % Construct stack
        while ( this.x(this.z) > finalSize(1) || this.y(this.z) > finalSize(2) ) 
            this.z  = this.z + 1;
            this.stack(:,:,this.z ) = this.Shrink( cur_image, stepSize, this.z  );
            cur_image = this.stack(:,:,this.z);
        end
    end
    
end



% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% PRIVATE METHODS
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    methods(Access = private)
        
        % Single Shrink step, this could be replaced by a superclass
        % method. Todo: extend this function to also include the last bit
        % of the image, now the new image is slightly cropped if the d
        % value and the image dimensions do not result in a 0 % division.
        function I = Shrink( this, image, d, layer )
    
            %todo: http://stackoverflow.com/questions/8036019/matlab-imresize-with-a-custom-interpolation-kernel
            %instead of the method used below. Should improve performance
            
            % Extract parameters for shrinking
            k = floor(this.x(layer-1)/d);
            l = floor(this.y(layer-1)/d);
            I = zeros(this.x(1),this.y(1))-1;
            this.x(layer) = k;
            this.y(layer) = l;
            xLeft = mod(this.x(layer-1),d);
            yLeft = mod(this.y(layer-1),d);
            
            % Calculate Shrinked Image
            for j = 1:l
                for i = 1:k
                    I(i,j) = sum(sum(image(((i-1)*d)+(1:d),((j-1)*d)+(1:d))))/(d^2);
                end
                
                % Check if no x-pixels are left behind
                if xLeft ~= 0
                    I(k+1,j) = sum(sum(image(k+(1:xLeft),((j-1)*d)+(1:d))))/(d*yLeft);
                end
                
            end
            
            if yLeft ~= 0
                I(k+1,l+1) = sum(sum(image(k+(1:xLeft),l+(1:yLeft))))/(xLeft*yLeft);
            end
        end
        
    end
    
end

