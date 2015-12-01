%
%   Reliable Patch Trackers: Robust Visual Tracking by Exploiting Reliable Patches
%
%   Yang Li, 2015
%   http://ihpdep.github.io
%
%   This is the research code of our RPT tracker. You can check the
%   details in our CVPR paper.

function  [position,target_sz] = voting(pos,target_sz,contexts,scale);%neighborCoeff,em);
%VOTING Summary of this function goes here
%   Detailed explanation goes here
    n=numel(contexts);
    position = pos;
    pos=[0,0];
    nn=0;
    points=[];
    psr=[];
    lifelong=[];

    for i=1:n
        if contexts{i}.target && isfield(contexts{i},'psr') && contexts{i}.psr >0 
            p=contexts{i}.pos;
            tmp =  p+ contexts{i}.displace*scale;
            points=[points; tmp];
            prob = contexts{i}.psr * size(contexts{i}.traj,1);
            if isfield(contexts{i},'motionP') 
                prob = prob* contexts{i}.motionP;
            end
            psr=[psr prob];
%             lifelong = [lifelong ];
            pos = tmp +pos;
            nn=nn+1;
        end
    end
%     std(points)
    if nn~=0
        psr=psr./sum(psr);
%         lifelong = lifelong./sum(lifelong);
        position = psr*points;
%      pos = pos /nn;
    end
                if min(~isnan(position)) == 0
                    position=[0 0];
                end
%     [mx,ix]=max(points);
%     [mn,in]=min(points);
%     points([ix in],:)=[];
%      target_sz=sqrt(prod(std(points-repmat(pos,[size(points,1),1])))).*scale;
    
     
%     
%     if pos+target_sz/2<mx
%         target_sz=(mx-pos)*2;
%     end
%     if pos-target_sz/2>mn
%         target_sz=(pos-mn)*2;
%     end
    
end

function b=inRect(t_sz,pos,point)
p=point-(pos-t_sz/2);
if prod(p<t_sz)*prod(  p > [1 1]) >0
    b=true;
else
    b=false;
end
end
