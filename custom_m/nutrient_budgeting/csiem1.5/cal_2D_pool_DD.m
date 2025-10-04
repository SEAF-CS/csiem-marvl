

function data = cal_2D_pool_DD(data,infolder, CPool_2D,t1,t2,NPool_2D_factors,DD,D_lim)
for ii=1:length(CPool_2D)
    
    tmp=load([infolder,CPool_2D{ii}]);
    time3D=tmp.savedata.Time;
    tmp2=tmp.savedata.(CPool_2D{ii}).Bot;
    tmp2(DD<=D_lim)=0;
    area=tmp.savedata.(CPool_2D{ii}).Area;
    tmp3=tmp2'*area';
    for tt=t1:t2
        inds=find(time3D>=tt & time3D <tt+1);
        data.(CPool_2D{ii})(tt-t1+1)=mean(tmp3(inds))*NPool_2D_factors(ii);
    end
    
    disp(['mean ',CPool_2D{ii},' is:',num2str(mean(data.(CPool_2D{ii})))]);
end

Tarea=sum(area); % total area
disp(['Total area is : ',num2str(Tarea)]);

end
