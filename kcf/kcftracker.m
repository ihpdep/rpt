function [ context] = kcftracker(im, context, param)

if ~isfield(context,'window_sz')

	%window size, taking padding into account
	context.window_sz = floor(context.target_sz * (1 + param.padding));
	
% 	%we could choose a size that is a power of two, for better FFT
% 	%performance. in practice it is slower, due to the larger window size.
% 	window_sz = 2 .^ nextpow2(window_sz);

	
	%create regression labels, gaussian shaped, with a bandwidth
	%proportional to target size
	output_sigma = sqrt(prod(context.target_sz)) * param.output_sigma_factor / param.cell_size;
	context.yf = fft2(gaussian_shaped_labels(output_sigma, floor(context.window_sz / param.cell_size)));

	%store pre-computed cosine window
    oldpadding= 1.5+1;
	context.cos_window = hann(size(context.yf,1)) * hann(size(context.yf,2))';	
    
    cos2 = hann(round(size(context.yf,1)/(1+ param.padding)*oldpadding)) * ...
        hann(round(size(context.yf,2)/(1+ param.padding)*oldpadding))';
    cos_window2=zeros(size(context.cos_window));
     a = ceil((size(context.yf)-size(cos2))/2)+1;
     b=ceil((size(context.yf)+size(cos2))/2);
%      a = (size(context.yf)-size(cos2))/2+1;
%      b=(size(context.yf)+size(cos2))/2;
    cos_window2(a(1):b(1),a(2):b(2))=cos2;
	context.cos_window2=cos_window2;
			%obtain a subwindow for training at newly estimated target position
    patch = get_subwindow(im, context.pos, context.window_sz);
    xf = fft2(get_features(patch, param.features, param.cell_size, context.cos_window2));

    %Kernel Ridge Regression, calculate alphas (in Fourier domain)
    switch param.kernel.type
    case 'gaussian',
        kf = gaussian_correlation(xf, xf, param.kernel.sigma);
    case 'polynomial',
        kf = polynomial_correlation(xf, xf, param.kernel.poly_a, kernel.poly_b);
    case 'linear',
        kf = linear_correlation(xf, xf);
    end
    alphaf = context.yf ./ (kf + param.lambda);   %equation for fast training


        context.model_alphaf = alphaf;
        context.model_xf = xf;
        context.psr=-1;
        context.traj=  [];
else
			%obtain a subwindow for detection at the position from last
			%frame, and convert to Fourier domain (its size is unchanged)
			patch = get_subwindow(im, context.pos, context.window_sz);
			zf = fft2(get_features(patch, param.features, param.cell_size, context.cos_window));
			
			%calculate response of the classifier at all shifts
			switch param.kernel.type
			case 'gaussian',
				kzf = gaussian_correlation(zf, context.model_xf, param.kernel.sigma);
			case 'polynomial',
				kzf = polynomial_correlation(zf, context.model_xf, param.kernel.poly_a, param.kernel.poly_b);
			case 'linear',
				kzf = linear_correlation(zf, context.model_xf);
			end
			response = real(ifft2(context.model_alphaf .* kzf));  %equation for fast detection
            context.psr=PSR(response,param.PSRange);
			%target location is at the maximum response. we must take into
			%account the fact that, if the target doesn't move, the peak
			%will appear at the top-left corner, not at the center (this is
			%discussed in the paper). the responses wrap around cyclically.
            maxresponse = max(response(:));
            [vert_delta, horiz_delta] = find(response == maxresponse, 1);
            

                
			if vert_delta > size(zf,1) / 2,  %wrap around to negative half-space of vertical axis
				vert_delta = vert_delta - size(zf,1);
			end
			if horiz_delta > size(zf,2) / 2,  %same for horizontal axis
				horiz_delta = horiz_delta - size(zf,2);
            end
            context.lastpos = context.pos;

            traj = [vert_delta - 1, horiz_delta - 1];
            context.traj=  [traj;context.traj];
			context.pos = context.pos + param.cell_size * [vert_delta - 1, horiz_delta - 1];
           
		%obtain a subwindow for training at newly estimated target position
		patch = get_subwindow(im, context.pos, context.window_sz);
		xf = fft2(get_features(patch, param.features, param.cell_size, context.cos_window2));

		%Kernel Ridge Regression, calculate alphas (in Fourier domain)
		switch param.kernel.type
		case 'gaussian',
			kf = gaussian_correlation(xf, xf, param.kernel.sigma);
		case 'polynomial',
			kf = polynomial_correlation(xf, xf, param.kernel.poly_a, param.kernel.poly_b);
		case 'linear',
			kf = linear_correlation(xf, xf);
		end
		alphaf = context.yf ./ (kf + param.lambda);   %equation for fast training


        %subsequent frames, interpolate model
        context.model_alphaf = (1 - param.interp_factor) * context.model_alphaf + param.interp_factor * alphaf;
        context.model_xf = (1 - param.interp_factor) * context.model_xf + param.interp_factor * xf;
        
        

end

