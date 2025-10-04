clear; close;

wl=350:10:700;

a = 2.98e-4 * exp(-0.014 * (wl - 443)); % * 12.0107

plot(wl,a);

a2 = 8e-5 * exp(-0.013 * (wl - 440)); % * 12.0107

hold on;
plot(wl,a2);
legend('DOC','Detritus')
