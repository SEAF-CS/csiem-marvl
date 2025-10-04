
function data = cal_3D_pool(data,infolder, CPool_3D,t1,t2,NPool_3D_factors)

for ii=1:length(CPool_3D)
    tmp=load([infolder,CPool_3D{ii}]);
    time3D=tmp.savedata.Time;
    tmp2=tmp.savedata.(CPool_3D{ii}).Column;
   % tmp2(DD<0.04)=0;
    for tt=t1:t2  % calculate the daily-average C pool in the selected polygon
        inds=find(time3D>=tt & time3D <tt+1);
        data.(CPool_3D{ii})(tt-t1+1)=mean(sum(tmp2(:,inds),1));
    end
    disp(['mean ',CPool_3D{ii},' is:',num2str(mean(data.(CPool_3D{ii}))*NPool_3D_factors(ii))]);
end

end