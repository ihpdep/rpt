%
%   Reliable Patch Trackers: Robust Visual Tracking by Exploiting Reliable Patches
%
%   Yang Li, 2015
%   http://ihpdep.github.io
%
%   This is the research code of our RPT tracker. You can check the
%   details in our CVPR paper.

function [ contexts ] = addParts( im,particles,pos,target_sz,param )

n = size(particles,2);
if n==0
    contexts={};
    return
end

sigma = particles([3,4,3,4],:)/2;
sigma(3:4,:) = sigma(3:4,:)/2;
sigma(3:4,:) = repmat(sqrt(sum(sigma(3:4,:).^2,1)), [2,1]);
% sigma(1:2,:) = repmat(sqrt(sum(sigma(1:2,:).^2,1)), [2,1]);
par = particles + randn(4,n).*sigma;

for i=1:n
    contexts{i}={};
    p=round(par(1:2,i)');
    contexts{i}.pos = p;  
    sz=round(par(3:4,i)');
    
    if min(sz > [15 15]) > 0 && min(sz < 0.6*size(im)) > 0
        contexts{i}.target_sz =sz; %target_sz - [factor*target_sz(1) factor*target_sz(2)];
    else
        contexts{i}.target_sz = ceil([min(target_sz) min(target_sz)]);
    end
    
    
    if inBox(target_sz,pos,p,1) 
        contexts{i}.target=1;
    else
        contexts{i}.target=0;
    end
    
    contexts{i}.displace = pos - p;

end


end
