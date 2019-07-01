function update_visualization_func = show_video(img_files, video_path, resize_image)
%SHOW_VIDEO
%   Visualizes a tracker in an interactive figure, given a cell array of
%   image file names, their path, and whether to resize the images to
%   half size or not.
%
%   This function returns an UPDATE_VISUALIZATION function handle, that
%   can be called with a frame number and a bounding box [x, y, width,
%   height], as soon as the results for a new frame have been calculated.
%   This way, your results are shown in real-time, but they are also
%   remembered so you can navigate and inspect the video afterwards.
%   Press 'Esc' to send a stop signal (returned by UPDATE_VISUALIZATION).
%
%   Joao F. Henriques, 2014
%   http://www.isr.uc.pt/~henriques/


	%store one instance per frame
	num_frames = numel(img_files);
	boxes = cell(100,num_frames,1);
    numP=0;

	%create window
	[fig_h, axes_h, unused, scroll] = videofig(num_frames, @redraw, [], [], @on_key_press);  %#ok, unused outputs
	set(fig_h, 'Name', ['Tracker - ' video_path])
	axis off;
	
	%image and rectangle handles start empty, they are initialized later
	im_h = [];
	rect_h = {};
    numN = 0;
	
	update_visualization_func = @update_visualization;
	stop_tracker = false;
	

	function stop = update_visualization(frame, box)
		%store the tracker instance for one frame, and show it. returns
		%true if processing should stop (user pressed 'Esc').
        numP=size(box,1);
        for i=1:numP
            boxes{i,frame} = box(i,:);
        end
		scroll(frame);
		stop = stop_tracker;
	end

	function redraw(frame)
		%render main image
		im = imread([video_path img_files{frame}]);
% 		if size(im,3) > 1,
% 			im = rgb2gray(im);
% 		end
		if resize_image,
			im = imresize(im, 0.5);
		end
		
		if isempty(im_h),  %create image
            
			im_h = imshow(im, 'Border','tight', 'InitialMag',200, 'Parent',axes_h);
            
		else  %just update it
			set(im_h, 'CData', im)
		end
		
		%render target bounding box for this frame
		if isempty(rect_h),  %create it for the first time
            for i=1:numP
			rect_h{i} = rectangle('Position',[0,0,1,1], 'EdgeColor','y', 'Parent',axes_h);
            end
%             rect_b = rectangle('Position',[0,0,1,1], 'EdgeColor','b', 'Parent',axes_h);
        end
        for i=1:numN
			set(rect_h{i}, 'Visible', 'off');
        end
        
		if ~isempty(boxes{1,frame}),
            for i=1:numP
                bb = boxes{i,frame};
                switch bb(5) 
                    case 0
                        set(rect_h{i}, 'EdgeColor','g', 'Visible', 'on','lineStyle','--', 'LineWidth',1.2, 'Position', bb(1:4));
                    case 1
                        set(rect_h{i}, 'EdgeColor','r', 'Visible', 'on','lineStyle','--', 'LineWidth',1.2,'Position', bb(1:4));
                    case 2
                        set(rect_h{i}, 'EdgeColor','b', 'Visible', 'on', 'lineStyle','--','LineWidth',1,'Position', bb(1:4));
                    case 3
                        set(rect_h{i}, 'EdgeColor','y', 'Visible', 'on','lineStyle','-','LineWidth',2.5, 'Position', bb(1:4));
                        uistack(rect_h{i},'top');
                    case 4
                        set(rect_h{i}, 'EdgeColor','c', 'Visible', 'on','lineStyle','--', 'LineWidth',1,'Position', bb(1:4));
                    case 5
                        set(rect_h{i}, 'EdgeColor','m', 'Visible', 'on','lineStyle','--','LineWidth',1, 'Position', bb(1:4));
                end
            end
            numN=numP;
%             tmp =boxes{frame};
%             tmp(1:2) = tmp(1:2) - 0.75*tmp(3:4);
%             tmp(3:4)=tmp(3:4)*2.5;
            
%             set(rect_b, 'Visible', 'on', 'Position',boxes{2,frame});
		end
	end

	function on_key_press(key)
		if strcmp(key, 'escape'),  %stop on 'Esc'
			stop_tracker = true;
		end
	end

end

