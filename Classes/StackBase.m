classdef StackBase < handle

    
    
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% PRIVATE PROPERTIES
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    properties(Access = protected)
        stack               % contains the stack
        x                   % contains the heights (x-direction)
        y                   % contains the widths (y-direction)
        z                   % contains the stackheight (z-direction)
        layer               % contains the current layer (display)
        j                   % contains the current layer (itteration)
    end

    
    
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% PUBLIC METHODS
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -    
    methods(Access = public)
        
        % Constructor calls the function to create a stack from the
        % inputted image.
        function this = StackBase( image , varargin )
            
            % if input is 3D, no need to create a stack
            if size(image,3) == 3
                this.stack = image;
            else
                this.constructStack( image , varargin{:} );
            end
            
            this.j = 1;
            
        end
        
        % getStack - returns the current stack
        function r = getStack( this )
            
            r = this.stack;
            
        end
        
        % length returns the number of layers
        function l = length( this )
            
            l = this.z;
            
        end
        
        % disp - overloading the display function to use the scrollstack
        % In this way you can scroll through the stack.
        function disp( this )
            
            this.layer = 1;
            
            % Create figure
            hf = figure('name','Stack');
            set(hf, 'Position', [100 100 640 700])
            
            ha = axes('position',[0,0.2,1,0.8]);
            set(hf,'CurrentAxes',ha)
           
            imshow(this.stack(:,:,this.layer));
            title(['StackBase, layer = ',num2str(this.layer),'/',num2str(this.z)]);
            
            % Attach scroll event to the figure
            set(hf, 'WindowScrollWheelFcn', @this.mouseScroll);
            
        end
        
        % next - returns 1 if there is a next element
        function b = next( this )
            
            b = 0;
            if this.j + 1 <= this.z
                b = 1;
            end
            
            this.j = this.j + 1;
            
        end
        
        % getLayer - returns the layer specified by j.
        function r = getLayer( this )
            r = this.stack(:,:,this.j);
        end
        
        % setLayer set layer specified by j
        function setLayer( this , layer )
            this.stack(:,:,this.j) = layer;
        end
        
        % convolveLayers - use a filter on all layers
        function convolveLayers(this, kernel)
            
            %todo: make this work again for all kernels
            this.setLayer(edge(this.getLayer(),'Canny'));
            
            while this.next()
%                 size(imfilter(this.getLayer(),kernel))
%                 size(this.stack(:,:,this.j))
%                 size(this.getLayer())
                if strcmp(kernel,'Canny')
                    I = this.getLayer();
%                     F = fspecial('gaussian',[3,3],2);
%                     I = imfilter( I , F );
                    this.setLayer(edge(I,'Canny'));
                else
                    this.setLayer(imfilter(this.getLayer(),kernel));
                end
                
            end
        end
    end

    
    
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% PROTECTED METHODS
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -        
    methods(Access = protected)
        
        % constuctStack - method that creates a specific stack, in the base class a simple
        % stack of the same images is created. The child-classes are
        % required to implement this function to their needs.
        function constructStack( this , image , varargin )
            image = double(image) / double(max(image(:)));
            [this.x, this.y] = size(image);
            this.stack = zeros([this.x, this.y, 2]);
            this.stack(:,:,1) = image;
            this.z = 2;
        end
        
        % mouseScroll - method that is called when the user scrolls on the
        % stack figure.
        function mouseScroll( this , ~ , eventdata )
            
            % Get scroll info from event
            UPDN = eventdata.VerticalScrollCount;
            this.layer = this.layer - UPDN;
            
            % make circular
            if this.layer < 1
                this.layer = 1;
            elseif this.layer > this.z
                this.layer = this.z;
            end
            
            % cut out image
            img = this.stack(:,:,this.layer);
            mask = img ~= -1;
            w = sum(mask(:,1));
            l = sum(mask(1,:));
            
            % Display image
            imshow(img(1:w,1:l));
            
            % update title
            title(['ScrollStack, layer = ',num2str(this.layer),'/',num2str(this.z)]);
            
        end
        
    end
    
end