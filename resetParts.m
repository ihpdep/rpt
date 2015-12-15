%
%   Reliable Patch Trackers: Robust Visual Tracking by Exploiting Reliable Patches
%
%   Yang Li, 2015
%   http://ihpdep.github.io
%
%   This is the research code of our RPT tracker. You can check the
%   details in our CVPR paper.

function [ contexts,changed ] = resetParts( im,pos,target_sz,contexts,param )
%RESETPARTS Summary of this function goes here
%   Detailed explanation goes here

scalePercent = 0.3;

frameRange = 5;

positivePercent = 0.8;

%delete the unstable patches
n=numel(contexts);
index = [];
trajs=[];
trajLabels=[];
trajTest=[];
target=[];
targetLabel=[];
psrP=[];
idP = [];
psrN=[];
idN= [];
posnum=0;
changed=1;
area= prod(target_sz);
areaS = [sqrt(area), sqrt(area)];
for i=1:n
    if contexts{i}.target>0
        
        if (contexts{i}.psr < param.deleteThresholdP && contexts{i}.psr>0)...
                || prod(contexts{i}.target_sz) > area ...
            || outImage(size(im),contexts{i}.pos) || ~inBox(target_sz,pos,contexts{i}.pos,param.yellowArea)
            index=[index i];
%             changed=changed+1;
        else
            
              if  size(contexts{i}.traj,1) >= frameRange 
                  psrP = [psrP contexts{i}.psr];
            idP = [idP i];
                    tmp=contexts{i}.traj(1:frameRange,:);%
%                     if  inBox(target_sz,pos,contexts{i}.pos,yellowArea) && ~inBox(target_sz,pos,contexts{i}.pos,greenArea)
%                         trajTest = [ trajTest tmp(:)];
%                          target=[target i];
%                          targetLabel=[targetLabel contexts{i}.target];
%                     else
                         trajs=[trajs tmp(:)];
                         trajLabels = [ trajLabels 1 ]; target=[target i];
%                     end
              end
        end
    else
        
        if (contexts{i}.psr < param.deleteThresholdN && contexts{i}.psr>0)...
            || outImage(size(im),contexts{i}.pos) ...
             || prod(contexts{i}.target_sz) > area  ...
            || ~inBox(areaS,pos,contexts{i}.pos,param.blueArea)...
            || inBox(target_sz,pos,contexts{i}.pos,param.yellowArea)
            index=[index i];
        else
            
             if  size(contexts{i}.traj,1) >= frameRange
                 psrN = [psrN contexts{i}.psr];
             idN = [idN i];
                    tmp=contexts{i}.traj(1:frameRange,:);%
                     trajs=[trajs tmp(:)];
                     trajLabels = [ trajLabels 0 ]; target=[target i];
              end
        end
    end

end

%     if ~isempty(target) && ~isempty(trajs) && size(unique(trajLabels),2) ~=1
%         y = knn(trajTest, trajs, trajLabels, 3);
%         for i=1:size(target,2)
%              contexts{target(i)}.target=y(i);
%                if y(i)~=targetLabel(i)
%                    index=[index target(i)];
%                end
%         end
%     end
psrPM=[];
psrNM=[];
lambda =1;
if size(unique(trajLabels),2) ~=1
   A = EuDist2(trajs');
   for i=1:size(target,2)
       pL=(trajLabels==1);
       pD = A(i,pL);
       pD = sum(pD)/size(pD,2);
       nD = A(i,~pL);
       nD = sum(nD)/size(nD,2);
        if contexts{target(i)}.target>0
            pMotion = nD - pD;
            ep=exp(lambda*pMotion);
            contexts{target(i)}.motionP=ep;
            psrPM = [psrPM ep*contexts{target(i)}.psr];
        else
            pMotion =  pD - nD;
            ep=exp(lambda*pMotion);
            contexts{target(i)}.motionP=ep;
            psrNM = [psrNM ep*contexts{target(i)}.psr];
        end
%        if (pMotion>0)~=trajLabels(i)
% %            index=[index target(i)];
%             if contexts{target(i)}.target
%                 contexts{target(i)}.target = ~trajLabels(i);
%        end
   end
   psrN = psrN .* psrNM;
   psrP= psrP.*psrPM;
end


    if  size(idP,2) > round(n*positivePercent)
         [~,iid] =sort(psrP);
        for i=1:size(idP,2) - round(n*positivePercent)
            index=[index idP(iid(i))];
        end
    else
        if  size(idN,2) > round(n*(1-positivePercent))
             [~,iid] =sort(psrN);
            for i=1:size(idN,2) - round(n*(1-positivePercent))
                index=[index idN(iid(i))];
            end
        end
    end


        psr =[];
        pars = zeros(4,1);
        k=1;
        positive = [];
        psrP=[];
        points=[];
        for i=1:n
            if sum(index==i) ==0 && contexts{i}.psr >0
                    ppp=contexts{i}.psr * size(contexts{i}.traj,1);
                    psr = [psr ppp];
                    pars(1:2,k) = contexts{i}.pos;
                    pars(3:4,k) = contexts{i}.target_sz;
                    k=k+1;
                    if contexts{i}.target >0 &&   isfield(contexts{i},'motionP') && contexts{i}.motionP >1
                        positive=[positive i];
                    end

            end
        end
        
        if size(positive,2)>scalePercent*n
            scale =[];
            for i=1:size(positive,2)
                for j=i+1:size(positive,2)
                    a = sqrt(sum((contexts{positive(i)}.pos - contexts{positive(j)}.pos).^2));
                    r =  sqrt(sum((contexts{positive(i)}.displace - contexts{positive(j)}.displace).^2));
                    scale = [scale a/r];
                end
            end
            [s, ~] = sort(scale);

            changed = s(round(size(s,2)/2)+1);
        end
        
        
    if ~isempty(index)
        if isempty(psr)
         psr=1;
         pars(1:2,1) = pos;
         pars(3:4,1) = 0.6*target_sz;
        end
        k=size(index,2);
        psr = psr./sum(psr);
      cumconf = cumsum(psr);
      a=repmat(rand(1,size(cumconf,2)),[k,1]);
      b=repmat(cumconf',[1,k]);
      idx = floor(sum( a'> b,1))+1;
      pars = pars(:,idx);

        addContexts=addParts(im,pars,pos,target_sz,param);

        for i=1:size(index,2)
            contexts{index(i)} = addContexts{i};
        end
    end


    
end

function b=outImage(WinSize,p)

    if min(p < WinSize - [1 1]) * min(p > [2 2]) > 0
        b=false;
    else
        b=true;
    end
end
% if ~isempty(trajX)
%     minX=min(trajX);
%     maxX=max(trajX);
%     minY=min(trajY);
%     maxY=max(trajY);
%     bin = zeros([maxX-minX+1,maxY-minY+1]);
%     inTarget=zeros(size(trajX, 1));
%     for i=1:size(trajX,1)
%         if contexts{target(i)}.target==1 || contexts{target(i)}.target==2
%             bin(trajX(i)-minX+1,trajY(i)-minY+1)=bin(trajX(i)-minX+1,trajY(i)-minY+1)+1;
%         end
%         inTarget(i)=(trajX(i)-minX)*size(bin,1) + trajY(i)-minY+1;
%     end
%     [dx dy]=find(bin==max(bin(:)),1);
%     flag = (dx-1)*size(bin,1) +dy;
%     for i=1:size(trajX,1)
%         if contexts{target(i)}.target ==4
%             if inTarget(i)==flag
%                 contexts{target(i)}.target=1;
%             else
%                 contexts{target(i)}.target=0;
%             end
%         end
%     end
% end
