

function data = cal_2D_pool(data,infolder, CPool_2D,t1,t2,NPool_2D_factors)
for ii=1:length(CPool_2D)
    
    tmp=load([infolder,CPool_2D{ii}]);
    time3D=tmp.savedata.Time;
    tmp2=tmp.savedata.(CPool_2D{ii}).Bot;
   % tmp2(DD<0.04)=0;
    area=tmp.savedata.(CPool_2D{ii}).Area;
    tmp3=tmp2'*area';
    for tt=t1:t2
        inds=find(time3D>=tt & time3D <tt+1);
        data.(CPool_2D{ii})(tt-t1+1)=mean(tmp3(inds));
    end
    
    disp(['mean ',CPool_2D{ii},' is:',num2str(mean(data.(CPool_2D{ii}))*NPool_2D_factors(ii))]);
end

Tarea=sum(area); % total area
disp(['Total area is : ',num2str(Tarea)]);

end
