%% ==========================================================
% Permutation test comparing 2 groups of XY datasets (A vs B)
% Density maps are in points per unit area (e.g., points/µm²)
% Expects columns: AX1,AY1...AX10,AY10 and BX1,BY1...BX10,BY10
% Also plots each AXn,AYn and BXn,BYn as separate line figures
% All figures share the same axis limits and tick marks
% ==========================================================
clear; clc; close all;

%% --- FILE SELECTION ---
[filename, pathname] = uigetfile({'*.csv','CSV file (*.csv)'}, ...
    'Select CSV file with AX1,AY1...BX10,BY10');
if isequal(filename,0)
    error('No file selected.');
end
fullpath = fullfile(pathname, filename);
fprintf('Selected: %s\n', fullpath);

%% --- LOAD CSV ---
T = readtable(fullpath);

datasetsA = {}; datasetsB = {};
for i = 1:10
    xa = sprintf('AX%d',i); ya = sprintf('AY%d',i);
    if all(ismember({xa,ya},T.Properties.VariableNames))
        x = T.(xa); y = T.(ya);
        valid = isfinite(x) & isfinite(y);
        if any(valid), datasetsA{end+1} = [x(valid), y(valid)]; end
    end
    xb = sprintf('BX%d',i); yb = sprintf('BY%d',i);
    if all(ismember({xb,yb},T.Properties.VariableNames))
        x = T.(xb); y = T.(yb);
        valid = isfinite(x) & isfinite(y);
        if any(valid), datasetsB{end+1} = [x(valid), y(valid)]; end
    end
end

nA = numel(datasetsA);
nB = numel(datasetsB);
fprintf('Loaded %d A datasets, %d B datasets.\n', nA, nB);


%% --- COMMON GRID ---
allA = vertcat(datasetsA{:});
allB = vertcat(datasetsB{:});
allX = [allA(:,1); allB(:,1)];
allY = [allA(:,2); allB(:,2)];
gridSize = 120;
xv = linspace(min(allX),max(allX),gridSize);
yv = linspace(min(allY),max(allY),gridSize);
[Xgrid,Ygrid] = meshgrid(xv,yv);

%% --- COMPUTE INDIVIDUAL DENSITY MAPS ---
fprintf('Computing kernel densities (points per unit area)...\n');
densitiesA = zeros(gridSize,gridSize,nA);
densitiesB = zeros(gridSize,gridSize,nB);

for k = 1:nA
    Npoints = size(datasetsA{k},1);
    f = ksdensity(datasetsA{k}, [Xgrid(:),Ygrid(:)]);
    densitiesA(:,:,k) = reshape(f, size(Xgrid)) * Npoints;
end
for k = 1:nB
    Npoints = size(datasetsB{k},1);
    f = ksdensity(datasetsB{k}, [Xgrid(:),Ygrid(:)]);
    densitiesB(:,:,k) = reshape(f, size(Xgrid)) * Npoints;
end

%% --- AVERAGES ---
meanA = mean(densitiesA,3);
meanB = mean(densitiesB,3);
obsDiff = meanA - meanB;

%% --- PERMUTATION TEST ---
fprintf('Running permutation test...\n');
nPerm = 1000;
allMaps = cat(3, densitiesA, densitiesB);
labels = [ones(1,nA) 2*ones(1,nB)];
maxVals = zeros(1,nPerm);

for p = 1:nPerm
    permLabels = labels(randperm(length(labels)));
    permA = allMaps(:,:,permLabels==1);
    permB = allMaps(:,:,permLabels==2);
    diffMap = mean(permA,3) - mean(permB,3);
    maxVals(p) = max(abs(diffMap(:)));
end

thresh = prctile(maxVals, 95);
sigMask = abs(obsDiff) > thresh;
fprintf('Permutation complete: 95%% threshold = %.4f points/unit area\n', thresh);

%% --- SUMMARY METRICS ---
corrVal = corr(meanA(:), meanB(:), 'rows', 'complete');
rmseVal = sqrt(mean((meanA(:) - meanB(:)).^2));
meanDiff = mean(obsDiff(:));
meanAbsDiff = mean(abs(obsDiff(:)));
sigPct = 100 * (sum(sigMask(:)) / numel(sigMask));

summaryTable = table(corrVal, rmseVal, meanDiff, meanAbsDiff, sigPct, thresh, ...
    'VariableNames', {'Correlation','RMSE','MeanDiff','MeanAbsDiff','SigAreaPct','PermThreshold'});

disp('--- Summary metrics ---');
disp(summaryTable);

%% --- CUSTOM COLORMAPS ---
n = 256;
cmapA = [linspace(1,1,n)' linspace(1,0,n)' linspace(1,0,n)']; % white→red
cmapB = [linspace(1,0,n)' linspace(1,0,n)' linspace(1,1,n)']; % white→blue
half = n/2;
r = [linspace(0,1,half) ones(1,half)]';
g = [linspace(0,1,half) linspace(1,0,half)]';
b = [ones(1,half) linspace(1,0,half)]';
cmapBWR = [r g b];

%% --- COMMON AXIS LIMITS AND TICKS ---
allXY = [vertcat(datasetsA{:}); vertcat(datasetsB{:})];
unit = 10; % rounding unit
xLimits = [floor(min(allXY(:,1))/unit)*unit, ceil(max(allXY(:,1))/unit)*unit];
yLimits = [floor(min(allXY(:,2))/unit)*unit, ceil(max(allXY(:,2))/unit)*unit];
tickInterval = 10; % axis tick spacing
xTicks = xLimits(1):tickInterval:xLimits(2);
yTicks = yLimits(1):tickInterval:yLimits(2);

%% --- PLOTTING & SAVING ---
maxAbs = max(abs(obsDiff(:)));
[~, base, ~] = fileparts(filename);
saveOpts = {'-r300','-dpng'};

% === Group A Density ===
figA = figure('Color','w');
contourf(Xgrid,Ygrid,meanA,20,'LineColor','none');
colormap(figA,cmapA); colorbar;
axis equal; xlim(xLimits); ylim(yLimits);
set(gca,'XTick',xTicks,'YTick',yTicks);
title('Average Density — Group A (white→red)');
xlabel('X'); ylabel('Y');
clim([0 max(meanA(:))]);
savefig(figA, fullfile(pathname,[base '_GroupA.fig']));
print(figA, fullfile(pathname,[base '_GroupA.png']), saveOpts{:});

% === Group B Density ===
figB = figure('Color','w');
contourf(Xgrid,Ygrid,meanB,20,'LineColor','none');
colormap(figB,cmapB); colorbar;
axis equal; xlim(xLimits); ylim(yLimits);
set(gca,'XTick',xTicks,'YTick',yTicks);
title('Average Density — Group B (white→blue)');
xlabel('X'); ylabel('Y');
clim([0 max(meanB(:))]);
savefig(figB, fullfile(pathname,[base '_GroupB.fig']));
print(figB, fullfile(pathname,[base '_GroupB.png']), saveOpts{:});

% === Difference ===
figDiff = figure('Color','w');
contourf(Xgrid,Ygrid,obsDiff,20,'LineColor','none');
clim([-maxAbs maxAbs]);
colormap(figDiff,cmapBWR); colorbar;
axis equal; xlim(xLimits); ylim(yLimits);
set(gca,'XTick',xTicks,'YTick',yTicks);
title('A − B difference (points/unit area)');
xlabel('X'); ylabel('Y');
savefig(figDiff, fullfile(pathname,[base '_Diff.fig']));
print(figDiff, fullfile(pathname,[base '_Diff.png']), saveOpts{:});

% === Difference + Significance ===
figSig = figure('Color','w');
contourf(Xgrid,Ygrid,obsDiff,20,'LineColor','none');
hold on;
contour(Xgrid,Ygrid,sigMask,[1 1],'k','LineWidth',1.5);
clim([-maxAbs maxAbs]);
colormap(figSig,cmapBWR); colorbar;
axis equal; xlim(xLimits); ylim(yLimits);
set(gca,'XTick',xTicks,'YTick',yTicks);
title('A − B difference (black = significant)');
xlabel('X'); ylabel('Y');
savefig(figSig, fullfile(pathname,[base '_SigMask.fig']));
print(figSig, fullfile(pathname,[base '_SigMask.png']), saveOpts{:});

%% --- INDIVIDUAL TRAJECTORY PLOTS (A and B) ---
fprintf('Generating individual XY line plots for each dataset...\n');

for i = 1:nA
    figAi = figure('Color','w');
    plot(datasetsA{i}(:,1), datasetsA{i}(:,2), 'r-', 'LineWidth', 1.5);
    axis equal; xlim(xLimits); ylim(yLimits);
    set(gca,'XTick',xTicks,'YTick',yTicks);
    xlabel('X'); ylabel('Y');
    title(sprintf('Group A — Dataset %d (AX%d, AY%d)', i, i, i));
    savefig(figAi, fullfile(pathname, sprintf('%s_GroupA_%02d.fig', base, i)));
    print(figAi, fullfile(pathname, sprintf('%s_GroupA_%02d.png', base, i)), saveOpts{:});
end

for i = 1:nB
    figBi = figure('Color','w');
    plot(datasetsB{i}(:,1), datasetsB{i}(:,2), 'b-', 'LineWidth', 1.5);
    axis equal; xlim(xLimits); ylim(yLimits);
    set(gca,'XTick',xTicks,'YTick',yTicks);
    xlabel('X'); ylabel('Y');
    title(sprintf('Group B — Dataset %d (BX%d, BY%d)', i, i, i));
    savefig(figBi, fullfile(pathname, sprintf('%s_GroupB_%02d.fig', base, i)));
    print(figBi, fullfile(pathname, sprintf('%s_GroupB_%02d.png', base, i)), saveOpts{:});
end

%% --- SAVE OUTPUTS ---
outA = fullfile(pathname,[base '_GroupA_avg.csv']);
outB = fullfile(pathname,[base '_GroupB_avg.csv']);
outDiff = fullfile(pathname,[base '_Diff_avg.csv']);
outSig = fullfile(pathname,[base '_SigMask_avg.csv']);
outSummary = fullfile(pathname,[base '_Summary_avg.csv']);

writetable(table(Xgrid(:),Ygrid(:),meanA(:)), outA, 'WriteVariableNames', false);
writetable(table(Xgrid(:),Ygrid(:),meanB(:)), outB, 'WriteVariableNames', false);
writetable(table(Xgrid(:),Ygrid(:),obsDiff(:)), outDiff, 'WriteVariableNames', false);
writetable(table(Xgrid(:),Ygrid(:),sigMask(:)), outSig, 'WriteVariableNames', false);
writetable(summaryTable, outSummary);

fprintf('\nAll output files (.csv, .fig, .png) saved in:\n%s\n', pathname);
