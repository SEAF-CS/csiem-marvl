function [xdata,ydata,ydata_max,ydata_min] = get_field_at_depth_thresh(mDate,mData,mDepth,level,thresh)

xdata = [];
ydata_max = [];
ydata_min = [];
ydata = [];

inc = 1;

if strcmpi(level,'surface')
    % maxdepth = max(mDepth);
    
    % sss = find(mDepth > (maxdepth-1));
    sss = find(mDepth >= thresh);
    
    if ~isempty(sss)
        
        mDate_b = mDate(sss);
        mData_b = mData(sss);
        mDepth_b = mDepth(sss);
        
        udep=unique(mDepth_b);
        
        for k=1:length(udep)
            sssk = find(mDepth_b == udep(k));
            
            mDate_k = mDate_b(sssk);
            mData_k = mData_b(sssk);
            %  mDepth_k = mDepth_b(sssk);
            
            fdate = floor(mDate_k);
            udate = unique(fdate);
            
       %     save('check_raw.mat','udep','udate','mDepth_b','mDate_k','-mat','-v7.3');
            
            for j = 1:length(udate)
                if ~isnan(udate(j))
                    sss2 = find(fdate == udate(j));
                    
                    xdata(inc,1) = mean(mDate_k(sss2));

                    y = prctile(mData_k(sss2),[10,90]);
                    ydata_min(inc,1) = y(1);
                    ydata_max(inc,1) = y(2);

                    ydata(inc,1) = mean(mData_k(sss2));

                    inc = inc + 1;
                end
            end
        end
        
    end
    
else
    
    %    mindepth = min(mDepth);
    %
    %    if mindepth < -1
    %        if mindepth < -5
    %             mindepth = mindepth + 3;
    %        else
    %            mindepth = mindepth + 1;
    %        end
    %    else
    %        mindepth = -1;
    %    end
    %     sss = find(mDepth < (mindepth));
    sss = find(mDepth < thresh);
    
    if ~isempty(sss)
        
        mDate_b = mDate(sss);
        mData_b = mData(sss);
        mDepth_b = mDepth(sss);
        
        udep=unique(mDepth_b);
        
        for k=1:length(udep)
            sssk = find(mDepth_b == udep(k));
            
            mDate_k = mDate_b(sssk);
            mData_k = mData_b(sssk);
            
            fdate = floor(mDate_k);
            udate = unique(fdate);
            
            for j = 1:length(udate)
                if ~isnan(udate(j))
                    sss2 = find(fdate == udate(j));
                    
                    xdata(inc,1) = mean(mDate_k(sss2));
                    ydata(inc,1) = mean(mData_k(sss2));

                    y = prctile(mData_k(sss2),[10,90]);
                    ydata_min(inc,1) = y(1);
                    ydata_max(inc,1) = y(2);

                    inc = inc + 1;
                end
            end
        end
    end
    
end

