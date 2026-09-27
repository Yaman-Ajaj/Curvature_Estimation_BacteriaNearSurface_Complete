clear; close all; clc;
%% Generate a trajectory with spatially varying curvature
N = 401;
t = linspace(0,20,N)';
dt = t(2)-t(1);
% Smooth trajectory with multiple bending scales
x = t + 0.35*sin(0.8*t) + 0.12*sin(2.2*t);
y = 1.2*sin(0.55*t) + 0.35*sin(1.4*t);
% True derivatives
dx_true = 1 + 0.35*0.8*cos(0.8*t) + 0.12*2.2*cos(2.2*t);
dy_true = 1.2*0.55*cos(0.55*t) + 0.35*1.4*cos(1.4*t);
ddx_true = -0.35*0.8^2*sin(0.8*t) - 0.12*2.2^2*sin(2.2*t);
ddy_true = -1.2*0.55^2*sin(0.55*t) - 0.35*1.4^2*sin(1.4*t);
kappa_true = abs(dx_true.*ddy_true-dy_true.*ddx_true)./(dx_true.^2+dy_true.^2).^(3/2);
%% Add measurement noise
noiseLevel = 0.015;
rng(1);
x_noisy = x + noiseLevel*randn(size(x));
y_noisy = y + noiseLevel*randn(size(y));
%% 3-point central difference
dx3 = nan(N,1);
dy3 = nan(N,1);
ddx3 = nan(N,1);
ddy3 = nan(N,1);
dx3(2:end-1) = (x_noisy(3:end)-x_noisy(1:end-2))/(2*dt);
dy3(2:end-1) = (y_noisy(3:end)-y_noisy(1:end-2))/(2*dt);
ddx3(2:end-1) = (x_noisy(3:end)-2*x_noisy(2:end-1)+x_noisy(1:end-2))/dt^2;
ddy3(2:end-1) = (y_noisy(3:end)-2*y_noisy(2:end-1)+y_noisy(1:end-2))/dt^2;
kappa3 = abs(dx3.*ddy3-dy3.*ddx3)./(dx3.^2+dy3.^2).^(3/2);
%% 5-point, fourth-order central difference
dx5 = nan(N,1);
dy5 = nan(N,1);
ddx5 = nan(N,1);
ddy5 = nan(N,1);
idx5 = 3:N-2;
dx5(idx5) = (x_noisy(idx5-2)-8*x_noisy(idx5-1)+8*x_noisy(idx5+1)-x_noisy(idx5+2))/(12*dt);
dy5(idx5) = (y_noisy(idx5-2)-8*y_noisy(idx5-1)+8*y_noisy(idx5+1)-y_noisy(idx5+2))/(12*dt);
ddx5(idx5) = (-x_noisy(idx5+2)+16*x_noisy(idx5+1)-30*x_noisy(idx5)+16*x_noisy(idx5-1)-x_noisy(idx5-2))/(12*dt^2);
ddy5(idx5) = (-y_noisy(idx5+2)+16*y_noisy(idx5+1)-30*y_noisy(idx5)+16*y_noisy(idx5-1)-y_noisy(idx5-2))/(12*dt^2);
kappa5 = abs(dx5.*ddy5-dy5.*ddx5)./(dx5.^2+dy5.^2).^(3/2);
%% 7-point, sixth-order central difference
dx7 = nan(N,1);
dy7 = nan(N,1);
ddx7 = nan(N,1);
ddy7 = nan(N,1);
idx7 = 4:N-3;
dx7(idx7) = (-x_noisy(idx7-3)+9*x_noisy(idx7-2)-45*x_noisy(idx7-1)+45*x_noisy(idx7+1)-9*x_noisy(idx7+2)+x_noisy(idx7+3))/(60*dt);
dy7(idx7) = (-y_noisy(idx7-3)+9*y_noisy(idx7-2)-45*y_noisy(idx7-1)+45*y_noisy(idx7+1)-9*y_noisy(idx7+2)+y_noisy(idx7+3))/(60*dt);
ddx7(idx7) = (2*x_noisy(idx7-3)-27*x_noisy(idx7-2)+270*x_noisy(idx7-1)-490*x_noisy(idx7)+270*x_noisy(idx7+1)-27*x_noisy(idx7+2)+2*x_noisy(idx7+3))/(180*dt^2);
ddy7(idx7) = (2*y_noisy(idx7-3)-27*y_noisy(idx7-2)+270*y_noisy(idx7-1)-490*y_noisy(idx7)+270*y_noisy(idx7+1)-27*y_noisy(idx7+2)+2*y_noisy(idx7+3))/(180*dt^2);
kappa7 = abs(dx7.*ddy7-dy7.*ddx7)./(dx7.^2+dy7.^2).^(3/2);
%% Local polynomial fitting
window = 11;
polyOrder = 3;
halfWindow = floor(window/2);
kappaPoly = nan(N,1);
for i = halfWindow+1:N-halfWindow
    ind = i-halfWindow:i+halfWindow;
    tau = t(ind)-t(i);
    px = polyfit(tau,x_noisy(ind),polyOrder);
    py = polyfit(tau,y_noisy(ind),polyOrder);
    dx = polyval(polyder(px),0);
    dy = polyval(polyder(py),0);
    ddx = polyval(polyder(polyder(px)),0);
    ddy = polyval(polyder(polyder(py)),0);
    kappaPoly(i) = abs(dx*ddy-dy*ddx)/(dx^2+dy^2)^(3/2);
end
%% Error calculation
valid3 = ~isnan(kappa3);
valid5 = ~isnan(kappa5);
valid7 = ~isnan(kappa7);
validP = ~isnan(kappaPoly);
RMSE3 = sqrt(mean((kappa3(valid3)-kappa_true(valid3)).^2));
RMSE5 = sqrt(mean((kappa5(valid5)-kappa_true(valid5)).^2));
RMSE7 = sqrt(mean((kappa7(valid7)-kappa_true(valid7)).^2));
RMSEP = sqrt(mean((kappaPoly(validP)-kappa_true(validP)).^2));
fprintf('\nCurvature estimation RMSE\n');
fprintf('3-point central difference       : %.5f\n',RMSE3);
fprintf('5-point 4th-order difference     : %.5f\n',RMSE5);
fprintf('7-point 6th-order difference     : %.5f\n',RMSE7);
fprintf('11-point local polynomial        : %.5f\n',RMSEP);
%% Figure 1: trajectory
figure('Color','w');
plot(x,y,'k-','LineWidth',2); hold on;
plot(x_noisy,y_noisy,'.','MarkerSize',5);
axis equal;
xlabel('x');
ylabel('y');
legend('True trajectory','Noisy trajectory','Location','best');
title('Synthetic trajectory');
grid on;
%% Figure 2: curvature comparison
figure('Color','w');
plot(t,kappa_true,'k-','LineWidth',2); hold on;
plot(t,kappa3,'LineWidth',1);
plot(t,kappa5,'LineWidth',1);
plot(t,kappa7,'LineWidth',1);
plot(t,kappaPoly,'LineWidth',1.5);
xlabel('Trajectory parameter, t');
ylabel('\kappa');
legend('True curvature','3-point','5-point, 4th order','7-point, 6th order','11-point polynomial','Location','best');
title('Curvature estimation');
grid on;
%% Figure 3: zoom into a representative region
figure('Color','w');
region = t>=5 & t<=10;
plot(t(region),kappa_true(region),'k-','LineWidth',2); hold on;
plot(t(region),kappa3(region),'LineWidth',1);
plot(t(region),kappa5(region),'LineWidth',1);
plot(t(region),kappa7(region),'LineWidth',1);
plot(t(region),kappaPoly(region),'LineWidth',1.5);
xlabel('Trajectory parameter, t');
ylabel('\kappa');
legend('True','3-point','5-point','7-point','Polynomial','Location','best');
title('Curvature comparison: zoomed region');
grid on;
%% Figure 4: effect of noise
noiseLevels = [0 0.005 0.01 0.02 0.04 0.08];
rmse3 = zeros(size(noiseLevels));
rmse5 = zeros(size(noiseLevels));
rmse7 = zeros(size(noiseLevels));
rmseP = zeros(size(noiseLevels));
for q = 1:numel(noiseLevels)
    xn = x + noiseLevels(q)*randn(size(x));
    yn = y + noiseLevels(q)*randn(size(y));
    % 3-point
    d1x = nan(N,1); d1y = nan(N,1);
    d2x = nan(N,1); d2y = nan(N,1);
    d1x(2:end-1) = (xn(3:end)-xn(1:end-2))/(2*dt);
    d1y(2:end-1) = (yn(3:end)-yn(1:end-2))/(2*dt);
    d2x(2:end-1) = (xn(3:end)-2*xn(2:end-1)+xn(1:end-2))/dt^2;
    d2y(2:end-1) = (yn(3:end)-2*yn(2:end-1)+yn(1:end-2))/dt^2;
    k3 = abs(d1x.*d2y-d1y.*d2x)./(d1x.^2+d1y.^2).^(3/2);
    % 5-point
    d1x = nan(N,1); d1y = nan(N,1);
    d2x = nan(N,1); d2y = nan(N,1);
    d1x(idx5) = (xn(idx5-2)-8*xn(idx5-1)+8*xn(idx5+1)-xn(idx5+2))/(12*dt);
    d1y(idx5) = (yn(idx5-2)-8*yn(idx5-1)+8*yn(idx5+1)-yn(idx5+2))/(12*dt);
    d2x(idx5) = (-xn(idx5+2)+16*xn(idx5+1)-30*xn(idx5)+16*xn(idx5-1)-xn(idx5-2))/(12*dt^2);
    d2y(idx5) = (-yn(idx5+2)+16*yn(idx5+1)-30*yn(idx5)+16*yn(idx5-1)-yn(idx5-2))/(12*dt^2);
    k5 = abs(d1x.*d2y-d1y.*d2x)./(d1x.^2+d1y.^2).^(3/2);
    % 7-point
    d1x = nan(N,1); d1y = nan(N,1);
    d2x = nan(N,1); d2y = nan(N,1);
    d1x(idx7) = (-xn(idx7-3)+9*xn(idx7-2)-45*xn(idx7-1)+45*xn(idx7+1)-9*xn(idx7+2)+xn(idx7+3))/(60*dt);
    d1y(idx7) = (-yn(idx7-3)+9*yn(idx7-2)-45*yn(idx7-1)+45*yn(idx7+1)-9*yn(idx7+2)+yn(idx7+3))/(60*dt);
    d2x(idx7) = (2*xn(idx7-3)-27*xn(idx7-2)+270*xn(idx7-1)-490*xn(idx7)+270*xn(idx7+1)-27*xn(idx7+2)+2*xn(idx7+3))/(180*dt^2);
    d2y(idx7) = (2*yn(idx7-3)-27*yn(idx7-2)+270*yn(idx7-1)-490*yn(idx7)+270*yn(idx7+1)-27*yn(idx7+2)+2*yn(idx7+3))/(180*dt^2);
    k7 = abs(d1x.*d2y-d1y.*d2x)./(d1x.^2+d1y.^2).^(3/2);
    % Polynomial
    kp = nan(N,1);
    for i = halfWindow+1:N-halfWindow
        ind = i-halfWindow:i+halfWindow;
        tau = t(ind)-t(i);
        px = polyfit(tau,xn(ind),polyOrder);
        py = polyfit(tau,yn(ind),polyOrder);
        dx = polyval(polyder(px),0);
        dy = polyval(polyder(py),0);
        ddx = polyval(polyder(polyder(px)),0);
        ddy = polyval(polyder(polyder(py)),0);
        kp(i) = abs(dx*ddy-dy*ddx)/(dx^2+dy^2)^(3/2);
    end
    rmse3(q) = sqrt(mean((k3(valid3)-kappa_true(valid3)).^2,'omitnan'));
    rmse5(q) = sqrt(mean((k5(valid5)-kappa_true(valid5)).^2,'omitnan'));
    rmse7(q) = sqrt(mean((k7(valid7)-kappa_true(valid7)).^2,'omitnan'));
    rmseP(q) = sqrt(mean((kp(validP)-kappa_true(validP)).^2,'omitnan'));
end
figure('Color','w');
plot(noiseLevels,rmse3,'o-','LineWidth',1.5); hold on;
plot(noiseLevels,rmse5,'o-','LineWidth',1.5);
plot(noiseLevels,rmse7,'o-','LineWidth',1.5);
plot(noiseLevels,rmseP,'o-','LineWidth',1.5);
xlabel('Position noise amplitude');
ylabel('Curvature RMSE');
legend('3-point','5-point','7-point','11-point polynomial','Location','northwest');
title('Sensitivity of curvature estimation to trajectory noise');
grid on;








%% ============================================================
%  Synthetic trajectory
%  =============================================================
N = 401;
t = linspace(0,20,N)';
dt = t(2)-t(1);
x = t + 0.35*sin(0.8*t) + 0.12*sin(2.2*t);
y = 1.2*sin(0.55*t) + 0.35*sin(1.4*t);
% Analytic derivatives
dx_true = 1 + 0.35*0.8*cos(0.8*t) + 0.12*2.2*cos(2.2*t);
dy_true = 1.2*0.55*cos(0.55*t) + 0.35*1.4*cos(1.4*t);
ddx_true = -0.35*0.8^2*sin(0.8*t) - 0.12*2.2^2*sin(2.2*t);
ddy_true = -1.2*0.55^2*sin(0.55*t) - 0.35*1.4^2*sin(1.4*t);
kappa_true = abs(dx_true.*ddy_true-dy_true.*ddx_true)./(dx_true.^2+dy_true.^2).^(3/2);
%% ============================================================
%  Add trajectory measurement noise
%  =============================================================
noiseLevel = 0.015;
rng(1);
x_noisy = x + noiseLevel*randn(size(x));
y_noisy = y + noiseLevel*randn(size(y));
%% ============================================================
%  Parameters to test
%  =============================================================
windowSizes = [5 7 9 11 15 21 31];
polyOrders = 2:6;
nW = numel(windowSizes);
nP = numel(polyOrders);
% Store curvature and RMSE
K = cell(nW,nP);
RMSE = nan(nW,nP);
%% ============================================================
%  Estimate curvature for every window/order combination
%  =============================================================
for iw = 1:nW
    window = windowSizes(iw);
    halfWindow = floor(window/2);
    for ip = 1:nP
        order = polyOrders(ip);
        if order >= window
            continue;
        end
        kappa = estimateLocalPolynomialCurvature(t,x_noisy,y_noisy,window,order);
        K{iw,ip} = kappa;
        valid = ~isnan(kappa);
        RMSE(iw,ip) = sqrt(mean((kappa(valid)-kappa_true(valid)).^2));
    end
end
%% ============================================================
% Figure 1: trajectory
% =============================================================
figure('Color','w');
plot(x,y,'k-','LineWidth',2); hold on;
plot(x_noisy,y_noisy,'.','MarkerSize',5);
axis equal;
xlabel('x');
ylabel('y');
legend('True trajectory','Noisy trajectory','Location','best');
title('Synthetic trajectory');
grid on;
%% ============================================================
% Figure 2: curvature for different polynomial orders
% =============================================================
figure('Color','w');
windowToShow = 11;
iw = find(windowSizes==windowToShow,1);
plot(t,kappa_true,'k-','LineWidth',2); hold on;
for ip = 1:nP
    if ~isempty(K{iw,ip})
        plot(t,K{iw,ip},'LineWidth',1.2);
    end
end
xlabel('Trajectory parameter, t');
ylabel('\kappa');
legendEntries = [{'True curvature'}, ...
    arrayfun(@(p)sprintf('Order %d',p),polyOrders,'UniformOutput',false)];
legend(legendEntries{:},'Location','best');
title(sprintf('Curvature estimation with %d-point window',windowToShow));
grid on;
%% ============================================================
% Figure 3: effect of window size for one polynomial order
% =============================================================
figure('Color','w');
orderToShow = 3;
plot(t,kappa_true,'k-','LineWidth',2); hold on;
for iw = 1:nW
    ip = find(polyOrders==orderToShow,1);
    if ~isempty(K{iw,ip})
        plot(t,K{iw,ip},'LineWidth',1);
    end
end
xlabel('Trajectory parameter, t');
ylabel('\kappa');
legendEntries = [{'True curvature'}, ...
    arrayfun(@(w)sprintf('Window %d',w),windowSizes,'UniformOutput',false)];
legend(legendEntries{:},'Location','best');
title(sprintf('Effect of window size, polynomial order = %d',orderToShow));
grid on;
%% ============================================================
% Figure 4: RMSE heatmap
% =============================================================
figure('Color','w');
imagesc(polyOrders,windowSizes,RMSE);
set(gca,'YDir','normal');
xlabel('Polynomial order');
ylabel('Window size');
title('Curvature estimation RMSE');
colorbar;
xticks(polyOrders);
yticks(windowSizes);
%% ============================================================
% Figure 5: curvature estimate at one trajectory position
% =============================================================
tTarget = 10;
[~,iTarget] = min(abs(t-tTarget));
figure('Color','w');
hold on;
for iw = 1:nW
    for ip = 1:nP
        if ~isempty(K{iw,ip})
            plot(polyOrders(ip),K{iw,ip}(iTarget),'o','MarkerSize',7);
        end
    end
end
yline(kappa_true(iTarget),'k--','LineWidth',2);
xlabel('Polynomial order');
ylabel('\kappa at selected position');
title(sprintf('Curvature at t = %.2f',t(iTarget)));
grid on;
%% ============================================================
% Print RMSE table
% =============================================================
fprintf('\nCurvature RMSE\n');
fprintf('---------------------------------------------\n');
fprintf('Window ');
for ip = 1:nP
    fprintf('   Order %d',polyOrders(ip));
end
fprintf('\n');
for iw = 1:nW
    fprintf('%6d ',windowSizes(iw));
    for ip = 1:nP
        if isnan(RMSE(iw,ip))
            fprintf('      ---');
        else
            fprintf('   %.5f',RMSE(iw,ip));
        end
    end
    fprintf('\n');
end
%% ============================================================
% Local polynomial curvature function
% =============================================================
function kappa = estimateLocalPolynomialCurvature(t,x,y,window,order)
N = numel(t);
kappa = nan(N,1);
halfWindow = floor(window/2);
for i = halfWindow+1:N-halfWindow
    ind = i-halfWindow:i+halfWindow;
    % Local coordinate centered at the current point
    tau = t(ind)-t(i);
    % Polynomial fitting
    px = polyfit(tau,x(ind),order);
    py = polyfit(tau,y(ind),order);
    % First derivative coefficients
    dpx = polyder(px);
    dpy = polyder(py);
    % Second derivative coefficients
    ddpx = polyder(dpx);
    ddpy = polyder(dpy);
    % Evaluate derivatives at the center
    dx = polyval(dpx,0);
    dy = polyval(dpy,0);
    ddx = polyval(ddpx,0);
    ddy = polyval(ddpy,0);
    % Curvature
    denominator = (dx^2+dy^2)^(3/2);
    if denominator > eps
        kappa(i) = abs(dx*ddy-dy*ddx)/denominator;
    end
end
end
