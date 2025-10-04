
function data = cal_3D_pool_DD(data,infolder, CPool_3D,t1,t2,NPool_3D_factors,DD,D_lim)

for ii=1:length(CPool_3D)
    tmp=load([infolder,CPool_3D{ii}]);
    time3D=tmp.savedata.Time;
    tmp2=tmp.savedata.(CPool_3D{ii}).ColumnMass;
    tmp2(DD<=D_lim)=0;
    for tt=t1:t2  % calculate the daily-average C pool in the selected polygon
        inds=find(time3D>=tt & time3D <tt+1);
        data.(CPool_3D{ii})(tt-t1+1)=mean(sum(tmp2(:,inds),1))*NPool_3D_factors(ii);
    end
    disp(['mean ',CPool_3D{ii},' is:',num2str(mean(data.(CPool_3D{ii})))]);
end

end