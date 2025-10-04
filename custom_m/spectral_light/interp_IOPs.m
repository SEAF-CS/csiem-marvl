
 if iop_type==6 
         a = 8e-5 * exp(-0.013 * (lambda - 440)) * 12.0107 * 2.6;
         b = 0.00115 * (550. / lambda)^0.5 * 12.0107 * 2.6;
         b_b = 0.005;
         b_p = 1.0;
 elseif iop_type==8
         a = 2.98e-4 * exp(-0.014 * (lambda - 443)) * 12.0107;
         b = 0;
         b_b = 0;
         b_p = 1.0;
elseif iop_type==9
     lambda_he6chl = [2.500000e+02, 3.250000e+02, 3.500000e+02, 3.750000e+02, 4.000000e+02, 4.250000e+02, 4.500000e+02, 4.750000e+02, 5.000000e+02, 5.250000e+02, ...
      5.500000e+02, 5.750000e+02, 6.000000e+02, 6.250000e+02, 6.500000e+02, 6.750000e+02, 7.000000e+02, 7.250000e+02, 7.500000e+02];

     a_he6chl = [2.800000e-03, 2.800000e-02, 2.800000e-02, 3.000000e-02, 3.635000e-02, 4.695000e-02, 4.720000e-02, 4.195000e-02, 3.340000e-02, 2.520000e-02, ...
      1.785000e-02, 1.340000e-02, 1.180000e-02, 1.495000e-02, 1.780000e-02, 2.720000e-02, 1.075000e-02, 1.500000e-03, 0.000000e+00];

     b_he6chl = [6.600000e-01, 5.076923e-01, 4.714286e-01, 4.400000e-01, 4.125000e-01, 3.882353e-01, 3.666667e-01, 3.473684e-01, 3.300000e-01, 3.142857e-01, ...
      3.000000e-01, 2.869565e-01, 2.750000e-01, 2.640000e-01, 2.538462e-01, 2.444444e-01, 2.357143e-01, 2.275862e-01, 2.200000e-01];

     a=interp1(lambda_he6chl, a_he6chl, lambda);
     b=interp1(lambda_he6chl, b_he6chl, lambda);

     %    CALL interp(size(lambda_he6chl ), lambda_he6chl, a_he6chl, nlambda, data%lambda, data%iops(i_iop)%a)
     %    CALL interp(size(lambda_he6chl ), lambda_he6chl, b_he6chl, nlambda, data%lambda, data%iops(i_iop)%b)
         b_b = 0.02;
         b_p = 0.62;
elseif iop_type==10

    lambda_Averagesediment = [2.500000e+02, 3.250000e+02, 3.500000e+02, 3.750000e+02, 4.000000e+02, 4.250000e+02, 4.500000e+02, 4.750000e+02, 5.000000e+02, 5.250000e+02, ...
      5.500000e+02, 5.750000e+02, 6.000000e+02, 6.250000e+02, 6.500000e+02, 6.750000e+02, 7.000000e+02, 7.250000e+02, 7.500000e+02];

    a_Averagesediment = [1.511500e-01, 1.362900e-01, 1.187500e-01, 1.024100e-01, 8.750000e-02, 7.325000e-02, 5.775000e-02, 4.925000e-02, 4.150000e-02, 3.350000e-02, ...
      2.625000e-02, 1.975000e-02, 1.650000e-02, 1.475000e-02, 1.375000e-02, 1.250000e-02, 1.162000e-02, 1.111000e-02, 1.078000e-02];

   b_Averagesediment = [7.888200e-01, 7.960000e-01, 8.075000e-01, 8.212800e-01, 8.435000e-01, 8.762500e-01, 8.945000e-01, 8.867500e-01, 8.655000e-01, 8.485000e-01, ...
      8.297500e-01, 8.045000e-01, 7.742500e-01, 7.357500e-01, 6.962500e-01, 6.537500e-01, 6.290000e-01, 5.946400e-01, 5.695400e-01];

     a=interp1(lambda_Averagesediment, a_Averagesediment, lambda);
     b=interp1(lambda_Averagesediment, b_Averagesediment, lambda);

     %    CALL interp(size(lambda_Averagesediment ), lambda_Averagesediment, a_Averagesediment, nlambda, data%lambda, data%iops(i_iop)%a)
         CALL interp(size(lambda_Averagesediment ), lambda_Averagesediment, b_Averagesediment, nlambda, data%lambda, data%iops(i_iop)%b)
     %    b_b = 0.01;
         b_p = 1.0;
 end