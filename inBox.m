%
%   Reliable Patch Trackers: Robust Visual Tracking by Exploiting Reliable Patches
%
%   Yang Li, 2015
%   http://ihpdep.github.io
%
%   This is the research code of our RPT tracker. You can check the
%   details in our CVPR paper.
function b=inBox(WinSize,pos,p,rate)
    BoundUR = pos + rate*WinSize/2;
    BoundDL = pos - rate*WinSize/2;

    if min(p < BoundUR) * min(p > BoundDL) == 0
        b=false;
    else
        b=true;
    end
end
