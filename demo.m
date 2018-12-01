clear;
tic
mkdir('result')
img_path=dir(fullfile('./image/*.jpg'));
fileNames={img_path.name}';
for img_idx=1:size(fileNames,1)
    I=im2double(imread(['./image/',fileNames{img_idx}]));
    [H,W,~]=size(I);
    WIN=round(sqrt(H*W)/50);
    I= imfilter(I, fspecial('gaussian', [round(WIN/2),round(WIN/2)],10), 'replicate');
    
    seedx=round(WIN/2):WIN:H;
    seedy=round(WIN/2):WIN:W;
    [seedx,seedy]=meshgrid(seedx,seedy);
    seedx=round(seedx+WIN*rand(size(seedx))-WIN/2);
    seedy=round(seedy+WIN*rand(size(seedy))-WIN/2);
    seedx(seedx<1)=1;seedx(seedx>H)=H;
    seedy(seedy<1)=1;seedy(seedy>W)=W;
    SEED=numel(seedx);
    
    I_weight=zeros(H,W);
    I_label=ones(H,W).*SEED;
    
    for idx=1:SEED
        sx=seedx(idx);
        sy=seedy(idx);
        bx=max(sx-WIN,1);
        ex=min(sx+WIN,H);
        by=max(sy-WIN,1);
        ey=min(sy+WIN,W);
        dx=bx:ex;
        dy=by:ey;
        
        C=sum((I(dx,dy,:)-I(sx,sy,:)).^2,3);
        dC=exp(-(C));
        [ddy,ddx]=meshgrid(dy,dx);
        dD=1./sqrt((ddx-sx).^2+(ddy-sy).^2);
        dW=dC+50*dD;
        sdW=I_weight(dx,dy);
        
        tdW=sdW;
        tdW(sdW<dW)=dW(sdW<dW);
        tdL=I_label(dx,dy);
        tdL(sdW<dW)=idx;
        
        I_weight(dx,dy)=tdW;
        I_label(dx,dy)=tdL;
    end
    IR=I(:,:,1);
    IG=I(:,:,2);
    IB=I(:,:,3);
    
    chC=abs(rand(SEED,3))./5;
    mR=arrayfun(@(i)IR(seedx(i),seedy(i)).*(1+chC(i,1)),1:SEED);
    mG=arrayfun(@(i)IG(seedx(i),seedy(i)).*(1+chC(i,2)),1:SEED);
    mB=arrayfun(@(i)IB(seedx(i),seedy(i)).*(1+chC(i,3)),1:SEED);
    
    bmR=mean(mR);
    bmG=mean(mG);
    bmB=mean(mB);
    
    for x=1:H
        for y=1:W
            IR(x,y)=mR(I_label(x,y));
            IB(x,y)=mB(I_label(x,y));
            IG(x,y)=mG(I_label(x,y));
        end
    end
    SE=strel('square',floor(sqrt(WIN)/2));
    label_edge=imdilate(bwmorph(edge(I_label,1e-5),'bridge'),SE);
    IR(label_edge)=bmR*1.3;
    IG(label_edge)=bmG*1.3;
    IB(label_edge)=bmB*1.3;
    II(:,:,1)=IR;
    II(:,:,2)=IG;
    II(:,:,3)=IB;
    imwrite(uint8(II.*255),['./result/',fileNames{img_idx}]);

    clearvars -except fileNames img_idx
    disp(img_idx)
end
toc
