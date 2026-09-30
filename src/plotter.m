

%%
SIM = true;
% SIM = false;
SAVE_FLAG = 1;
% SAVE_FLAG = 0;

uMax2 = 3.8;
u_ball = 11;
uMax1 = sqrt(u_ball^2 - uMax2^2);
th_max = [6,6,6]*10;

warmup_time = 11+3;
ep_time = 2*4;

global_start_t = warmup_time;
% global_end_t = T;
global_end_t = warmup_time + 2*ep_time;

start_t = 24.6; 
end_t   = 25.3;

% start_t = 32.4; 
% end_t   = 34.9;


%% VARIABLE MAPPING
if SIM
    load("RESULT.mat")
    T = dataSet{1}.T;
    t = dataSet{1}.t;
    obs_t = 1:length(t);

    warmup_start_t = find(t >= warmup_time, 1);
    epi_end_t = find(t >= warmup_time + 2*ep_time, 1);
    epi_idx = find(t >= warmup_time & t <= warmup_time + 2*ep_time);
    ctrl_obs_idx = find(t >= start_t & t <= end_t);
    ctrl_obs_idx2 = find(t >= start_t-0.5 & t <= end_t+0.5); %little longer

    t_max_idx = 1;
else
    dataSet = cell(4,1);

    data_path_4 = "20260728_161911"; % CONAC high - 1
    data_path_3 = "20260728_162454"; % CONAC low - 2
    data_path_2 = "20260728_151903"; % AUX - 3
    data_path_1 = "20260728_141636"; % NAC - 4

    dataSet{1} = loadFromMeas("meas_result/"+data_path_1+"/"+data_path_1+".mat", 4);
    dataSet{2} = loadFromMeas("meas_result/"+data_path_2+"/"+data_path_2+".mat", 3);
    dataSet{3} = loadFromMeas("meas_result/"+data_path_3+"/"+data_path_3+".mat", 2);
    dataSet{4} = loadFromMeas("meas_result/"+data_path_4+"/"+data_path_4+".mat", 1);

    [t_end_max, t_max_idx] = max([length(dataSet{1}.t), length(dataSet{2}.t), length(dataSet{3}.t), length(dataSet{4}.t)]);
    % fill nan values


    t = dataSet{t_max_idx}.t;
    T = dataSet{t_max_idx}.T;
    obs_t = 1:length(t);
    warmup_start_t = find(t >= warmup_time, 1);
    epi_end_t = find(t >= warmup_time + 2*ep_time, 1);
    epi_idx = find(t >= warmup_time & t <= warmup_time + 2*ep_time);
    ctrl_obs_idx = find(t >= start_t & t <= end_t);
    ctrl_obs_idx2 = find(t >= start_t-.5 & t <= end_t+.5); %little longer
    % ctrl_obs_idx2 = ctrl_obs_idx
end


CTRL_NUM = 4;
color_list = [ ...
    "#808080";
    "cyan";
    "blue";
    "magenta";
];
% color_list = [ ...
%     "#808080";
%     "magenta";
%     "cyan";
%     "blue";
% ];
tex_name_list = {
    "NAC";
    "AUX";
    "CONAClow";
    "CONAChigh";
};
name_list = {
    "(C$_4$)";
    "(C$_3$)";
    "(C$_2$)";
    "(C$_1$)";
};

%%
font_size = 12;
ax_font_size = 12;
line_width = 1;
lgd_size = 16;

fig_height = 200;
fig_width = 1000;
ax_height = fig_height * .9;
ax_width = fig_width * .9;

fig_unit = 'pixels';

norm_func = @(x) sqrt(sum(x.^2, 1));

%% FIG. 1-4
figW = 17;   % cm, one-column width 정도
figH = 5;
axSize = [2.0 2 14.3 5.1];

ax_list = {};
% maxVals = ones(5,1)*-inf; minVals = ones(5,1)*inf;
maxVals = [
    50
    60
    rad2deg(3)
    rad2deg(3)
    10.5
    4
    10.5
];
minVals = [
    -60
    -90
    rad2deg(-3)
    rad2deg(-3)
    6.5
    0
    % -10.4
    % -3.5
    6.5
];

for f_idx = [1:1:7]
    fig = figure(f_idx); clf;
    ax = axes(fig);
    hold(ax, 'on');
    grid(ax, 'on');
    grid(ax, 'minor');
    box(ax, 'on');

    set(fig, 'Units', 'centimeters');
    fig.Position(3:4) = [figW figH];
    % set(ax, 'Units', 'centimeters');
    % set(ax, 'Position', axSize);

    set(ax, 'FontName', 'Times New Roman');
    set(ax, 'FontSize', ax_font_size);
    set(ax, 'LineWidth', 1.1);
    set(ax, 'TickLabelInterpreter', 'latex');

    % set(fig, 'PaperUnits', 'centimeters');
    % set(fig, 'PaperSize', [figW figH]);
    % set(fig, 'PaperPosition', [0 0 figW figH]);
    % print(fig, 'fig_error.pdf', '-dpdf', '-painters');

    ax_list{f_idx} = ax;
end

% ============================
% before all data
zoom_color = [0, 134, 2] / 255;
zoom_alpha = 0.3;

for f_idx = 1:7
    ax = ax_list{f_idx};
    hold(ax, 'on');

    % Patch 때문에 y축 범위가 바뀌지 않도록 기존 범위 저장
    original_ylim = ylim(ax);

    h_region = patch( ...
        'Parent', ax, ...
        'XData', [start_t, end_t, end_t, start_t], ...
        'YData', [-1e10, -1e10, 1e10, 1e10], ...
        'FaceColor', zoom_color, ...
        'FaceAlpha', zoom_alpha, ...
        'EdgeColor', 'none', ...
        'HandleVisibility', 'off', ...
        'Clipping', 'on');

    % 기존 그래프 뒤로 이동
    uistack(h_region, 'bottom');

    % 기존 y축 범위 복원
    ylim(ax, original_ylim);
end

% ============================
% all data
for ctrl_idx = 1:1:length(dataSet)
    data = dataSet{ctrl_idx};
    CTRL_INFO = data.CTRL_INFO;

    x1_hist = rad2deg(data.x1_hist);
    x2_hist = rad2deg(data.x2_hist);
    xd1_hist = rad2deg(data.xd1_hist);
    xd2_hist = rad2deg(data.xd2_hist);
    u_hist = data.u_hist;
    uSat_hist = data.uSat_hist;
    color = color_list(ctrl_idx);

    % fill nan values for same length
    if length(t) > length(x1_hist)
        x1_hist = [x1_hist, nan(2, length(t)-length(x1_hist))];
        x2_hist = [x2_hist, nan(2, length(t)-length(x2_hist))];
        u_hist = [u_hist, nan(2, length(t)-length(u_hist))];
        uSat_hist = [uSat_hist, nan(2, length(t)-length(uSat_hist))];
    end
    
    plot(ax_list{1}, t, x1_hist(1,:),       "Color", color, "LineWidth", line_width, "LineStyle", "-"); 
    plot(ax_list{2}, t, x1_hist(2,:),       "Color", color, "LineWidth", line_width, "LineStyle", "-"); 
    plot(ax_list{3}, t, x2_hist(1,:),       "Color", color, "LineWidth", line_width, "LineStyle", "-"); 
    plot(ax_list{4}, t, x2_hist(2,:),       "Color", color, "LineWidth", line_width, "LineStyle", "-"); 
    plot(ax_list{5}, t, u_hist(1,:),        "Color", color, "LineWidth", line_width, "LineStyle", "-"); 
    plot(ax_list{5}, t, uSat_hist(1,:),     "Color", color, "LineWidth", line_width, "LineStyle", "-."); 
    plot(ax_list{6}, t, u_hist(2,:),        "Color", color, "LineWidth", line_width, "LineStyle", "-"); 
    plot(ax_list{6}, t, uSat_hist(2,:),     "Color", color, "LineWidth", line_width, "LineStyle", "-.");
    plot(ax_list{7}, t, norm_func(u_hist),  "Color", color, "LineWidth", line_width, "LineStyle", "-"); 
end

% ============================
% after all data
plot(ax_list{1}, t, rad2deg(dataSet{t_max_idx}.xd1_hist(1,:)), "Color", "red", "LineWidth", line_width, "LineStyle", "--"); 
plot(ax_list{2}, t, rad2deg(dataSet{t_max_idx}.xd1_hist(2,:)), "Color", "red", "LineWidth", line_width, "LineStyle", "--");
plot(ax_list{3}, t, rad2deg(dataSet{t_max_idx}.xd2_hist(1,:)), "Color", "red", "LineWidth", line_width, "LineStyle", "--"); 
plot(ax_list{4}, t, rad2deg(dataSet{t_max_idx}.xd2_hist(2,:)), "Color", "red", "LineWidth", line_width, "LineStyle", "--");

plot(ax_list{5}, [t(1) t(end)], [+1 +1]*uMax1, "Color", "black", "LineWidth", line_width, "LineStyle", "-."); hold on
plot(ax_list{5}, [t(1) t(end)], [-1 -1]*uMax1, "Color", "black", "LineWidth", line_width, "LineStyle", "-."); hold on
plot(ax_list{6}, [t(1) t(end)], [+1 +1]*uMax2, "Color", "black", "LineWidth", line_width, "LineStyle", "-."); hold on
plot(ax_list{6}, [t(1) t(end)], [-1 -1]*uMax2, "Color", "black", "LineWidth", line_width, "LineStyle", "-."); hold on
plot(ax_list{7}, [t(1) t(end)], [+1 +1]*u_ball, "Color", "black", "LineWidth", line_width, "LineStyle", "-."); hold on
plot(ax_list{7}, [t(1) t(end)], [-1 -1]*u_ball, "Color", "black", "LineWidth", line_width, "LineStyle", "-."); hold on

yticks(ax_list{2}, [-90 0 90]);  % 실제 0, 90 위치에 눈금


% 
zoom_color = "#008602"; % orange
for f_idx = 1:1:7
    % plot(ax_list{f_idx}, [warmup_time, warmup_time], [-5e2 5e2], "Color", "black", "LineWidth", line_width, "LineStyle", "-."); hold on
    plot(ax_list{f_idx}, [warmup_time+ep_time, warmup_time+ep_time], [-5e2 5e2], "Color", "black", "LineWidth", line_width, "LineStyle", "-."); hold on
    % plot(ax_list{f_idx}, [warmup_time+2*ep_time, warmup_time+2*ep_time], [-5e2 5e2], "Color", "black", "LineWidth", line_width, "LineStyle", "-."); hold on
    
    % plot(ax_list{f_idx}, [start_t, start_t], [-5e2 5e2], "Color", zoom_color, "LineWidth", line_width, "LineStyle", "--"); hold on
    % plot(ax_list{f_idx}, [end_t, end_t], [-5e2 5e2], "Color", zoom_color, "LineWidth", line_width, "LineStyle", "--"); hold on

    if f_idx <= 4
        text(ax_list{f_idx}, 0.02, 0.9, "Episode 1", "FontSize", font_size, "FontName", 'Times New Roman','Units','normalized')
        text(ax_list{f_idx}, 0.52, 0.9, "Episode 2", "FontSize", font_size, "FontName", 'Times New Roman','Units','normalized')
        % text(ax_list{f_idx}, 0.745, 0.9, "see, Zoomed-in view figure", "FontSize", font_size, "FontName", 'Times New Roman','Units','normalized', 'Color', zoom_color)
    else
        text(ax_list{f_idx}, 0.02, 0.1, "Episode 1", "FontSize", font_size, "FontName", 'Times New Roman','Units','normalized')
        text(ax_list{f_idx}, 0.52, 0.1, "Episode 2", "FontSize", font_size, "FontName", 'Times New Roman','Units','normalized')
        % text(ax_list{f_idx}, 0.845, 0.1, "see, Zoomed-in view figure", "FontSize", font_size, "FontName", 'Times New Roman','Units','normalized', 'Color', zoom_color)
    end

    len = maxVals(f_idx)-minVals(f_idx); ratio = .3;
    if len~=0
        ax_list{f_idx}.YLim = [minVals(f_idx)-len*ratio maxVals(f_idx)+len*ratio];
    end
    ax_list{f_idx}.XLim = [global_start_t global_end_t];
end

% label
ax_list{1}.XLabel.String = 'Time / s';
ax_list{1}.YLabel.String = '$q_1$ / deg';
ax_list{2}.XLabel.String = 'Time / s';
ax_list{2}.YLabel.String = '$q_2$ / deg';
ax_list{3}.XLabel.String = 'Time / s';
ax_list{3}.YLabel.String = '$\dot{q}_1$ / deg/s';
ax_list{4}.XLabel.String = 'Time / s';
ax_list{4}.YLabel.String = '$\dot{q}_2$ / deg/s';
ax_list{5}.XLabel.String = 'Time / s';
ax_list{5}.YLabel.String = '$\tau_1$ / Nm';
ax_list{6}.XLabel.String = 'Time / s';
ax_list{6}.YLabel.String = '$\tau_2$ / Nm';
ax_list{7}.XLabel.String = 'Time / s';
ax_list{7}.YLabel.String = '$\Vert\mbox{\boldmath $\tau$}\Vert$ / Nm';

for ax_idx = [1:1:7]
    ax_list{ax_idx}.XLabel.Interpreter = 'latex';
    ax_list{ax_idx}.YLabel.Interpreter = 'latex';
end

%% ============================
% Top view of the control input
% ============================
fig = figure(8); clf;
ax = axes(fig);
hold(ax, 'on');
grid(ax, 'on');
grid(ax, 'minor');
box(ax, 'on');

set(fig, 'Units', 'centimeters');
fig.Position(3:4) = [figW figH*1.5];
set(ax, 'FontName', 'Times New Roman');
set(ax, 'FontSize', ax_font_size);
set(ax, 'LineWidth', 1.1);
set(ax, 'TickLabelInterpreter', 'latex');

p = ax.Position;
axInset = axes( ...
    'Parent', fig, ...
    'Units', 'normalized', ...
    'Position', ...
    [p(1) + 0.50*p(3), ...
    p(2) + 0.50*p(4), ...
    0.45*p(3), ...
    0.43*p(4)]);

hold(axInset, 'on');
grid(axInset, 'on');
grid(axInset, 'minor');
box(axInset, 'on');

set(axInset, 'FontName', 'Times New Roman');
set(axInset, 'FontSize', ax_font_size);
set(axInset, 'LineWidth', 1.1);
set(axInset, 'TickLabelInterpreter', 'latex');

maxminX = [-inf inf]; maxminY = [-inf inf];
for ctrl_idx = 1:1:length(dataSet)
% for ctrl_idx = [2, 3, 4, 1]
    data = dataSet{ctrl_idx};
    CTRL_INFO = data.CTRL_INFO;

    u_hist = data.u_hist;
    u_hist = [u_hist, nan(2, length(t)-length(u_hist))];
    u_hist = u_hist(:, ctrl_obs_idx);
    color = color_list(ctrl_idx);

    if ctrl_idx == 1
        plot(axInset, u_hist(1,:), u_hist(2,:), "Color", color, "LineWidth", line_width, "LineStyle", "-");

        maxValX = [min(u_hist(1,:)) max(u_hist(1,:))];
        maxValY = [min(u_hist(2,:)) max(u_hist(2,:))];
        lenX = maxValX(2)-maxValX(1); lenY = maxValY(2)-maxValY(1);
        ratio = 0.1;
        axInset.XLim = [maxValX(1)-lenX*ratio maxValX(2)+lenX*ratio];
        axInset.YLim = [maxValY(1)-lenY*ratio maxValY(2)+lenY*ratio];


    else
        plot(ax, u_hist(1,:), u_hist(2,:), "Color", color, "LineWidth", line_width, "LineStyle", "-");

        maxminX = [min(u_hist(1,:)) max(u_hist(1,:))];
        maxminY = [min(u_hist(2,:)) max(u_hist(2,:))];
    end
end
plot(ax, u_ball*cos(0:0.01:2*pi), u_ball*sin(0:0.01:2*pi), "Color", "black", "LineWidth", line_width, "LineStyle", "-."); hold on
plot(ax, [-1000 1000], [+1 +1]*uMax2, "Color", "black", "LineWidth", line_width, "LineStyle", "-."); hold on
plot(ax, [-1000 1000], [-1 -1]*uMax2, "Color", "black", "LineWidth", line_width, "LineStyle", "-."); hold on
plot(ax, [1 1]*uMax1, [-10000, 10000], "Color", "black", "LineWidth", line_width, "LineStyle", "-."); hold on
ax.XLabel.String = '$\tau_1$ / Nm'; ax.XLabel.Interpreter = 'latex';
ax.YLabel.String = '$\tau_2$ / Nm'; ax.YLabel.Interpreter = 'latex';
maxminX = [-u_ball, u_ball];
maxminY = [-u_ball, u_ball];
ax.XLim = [9.5 14.5];
ax.XLim = [10 13];
ax.YLim = [0 4.2];

axInset.XLabel.String = '$\tau_1$ / Nm'; axInset.XLabel.Interpreter = 'latex';
axInset.YLabel.String = '$\tau_2$ / Nm'; axInset.YLabel.Interpreter = 'latex';


%% ============================
% [CONAC] Multipliers
% ============================

fig = figure(9); clf;
ax = axes(fig);

set(fig, 'Units', 'centimeters');
fig.Position(3:4) = [figW figH];

CONAC_u_ball_lbd = dataSet{2}.lbd_hist(4,:);
CONAC_u2_max_lbd = dataSet{2}.lbd_hist(7,:);

semilogy(ax, dataSet{2}.t, CONAC_u_ball_lbd, "Color", color_list(2), "LineWidth", line_width, "LineStyle", "-", "DisplayName", '$\lambda_{\overline{\tau}}$'); hold on
semilogy(ax, dataSet{2}.t, CONAC_u2_max_lbd, "Color", color_list(2), "LineWidth", line_width, "LineStyle", "-.", "DisplayName", "$\lambda_{\overline{\tau}_2}$"); hold on

hold(ax, 'on');
grid(ax, 'on');
box(ax, 'on');
grid(ax, 'minor');

% lgd = legend(ax);
% lgd.Location = 'southeast';
% lgd.Interpreter = 'latex';
% lgd.FontSize = 10;
% lgd.NumColumns = 2;
set(ax, 'FontName', 'Times New Roman');
set(ax, 'FontSize', ax_font_size);
set(ax, 'LineWidth', 1.1);
set(ax, 'TickLabelInterpreter', 'latex');
ax.XLabel.String = 'Time / s';
ax.YLabel.String = '$\lambda_{\overline{\tau}}$';
ax.XLabel.Interpreter = 'latex';
ax.YLabel.Interpreter = 'latex';

ax.XLim = [start_t end_t];
ax.YLim = [0.000078389151053,7.12744126403738];

%% ============================
%   Weight Norms
% ============================
fig = figure(10); clf;
ax = axes(fig);
set(fig, 'Units', 'centimeters');
fig.Position(3:4) = [figW figH];
hold(ax, 'on');
grid(ax, 'on');
box(ax, 'on');
grid(ax, 'minor');
set(ax, 'FontName', 'Times New Roman');
set(ax, 'FontSize', ax_font_size);
set(ax, 'LineWidth', 1.1);
set(ax, 'TickLabelInterpreter', 'latex');

for ctrl_idx = 1:1:length(dataSet)
    data = dataSet{ctrl_idx};
    CTRL_INFO = data.CTRL_INFO;
    color = color_list(ctrl_idx);
    
    t = data.t;

    th_hist = data.th_hist;
    th0 = th_hist(1,:);
    th1 = th_hist(2,:);
    th2 = th_hist(3,:);

    plot(ax, t, th0, "Color", color, "LineWidth", line_width, "LineStyle", "-", "HandleVisibility", "off"); hold on
    plot(ax, t, th1, "Color", color, "LineWidth", line_width, "LineStyle", "-.", "HandleVisibility", "off"); hold on
    plot(ax, t, th2, "Color", color, "LineWidth", line_width, "LineStyle", "--", "HandleVisibility", "off"); hold on
    
end
% dummy for legend (not plotted)
plot(ax, NaN, NaN, "Color", 'k', "LineWidth", line_width, "LineStyle", "-", "DisplayName", "$\Vert\widehat{\mbox{\boldmath $\theta$}}_0\Vert$"); hold on
plot(ax, NaN, NaN, "Color", 'k', "LineWidth", line_width, "LineStyle", "-.", "DisplayName", "$\Vert\widehat{\mbox{\boldmath $\theta$}}_1\Vert$"); hold on
plot(ax, NaN, NaN, "Color", 'k', "LineWidth", line_width, "LineStyle", "--", "DisplayName", "$\Vert\widehat{\mbox{\boldmath $\theta$}}_2\Vert$"); hold on
plot(ax, [0 T], [+1 +1]*th_max(1), "Color", "black", "LineWidth", line_width, "LineStyle", "-.", "HandleVisibility", "off"); hold on

lgd = legend(ax);
lgd.Location = 'northwest';
lgd.Interpreter = 'latex';
lgd.FontSize = 10;
lgd.NumColumns = 3;

ax.XLim = [global_start_t global_end_t];
ax.YLim = [0 14];
ax.XLabel.String = 'Time / s';
ax.YLabel.String = '$\Vert\widehat{\mbox{\boldmath $\theta$}}_i\Vert$';
ax.XLabel.Interpreter = 'latex';
ax.YLabel.Interpreter = 'latex';

%% HardNet (number of iterations)
fig = figure(11); clf;
ax = axes(fig);
set(fig, 'Units', 'centimeters');
fig.Position(3:4) = [figW figH];
hold(ax, 'on');
grid(ax, 'on');
box(ax, 'on');
grid(ax, 'minor');
set(ax, 'FontName', 'Times New Roman');
set(ax, 'FontSize', ax_font_size);
set(ax, 'LineWidth', 1.1);
set(ax, 'TickLabelInterpreter', 'latex');

data = dataSet{3};
color = color_list(3);
    
t = data.t;

n_iter_hist = data.iter_hist;

plot(ax, t, n_iter_hist, "Color", color, "LineWidth", line_width, "LineStyle", "-", "HandleVisibility", "off"); hold on

plot(ax, [warmup_time+ep_time, warmup_time+ep_time], [-5e2 5e2], "Color", "black", "LineWidth", line_width, "LineStyle", "-."); hold on
text(ax, 0.02, 0.9, "Episode 1", "FontSize", font_size, "FontName", 'Times New Roman','Units','normalized')
text(ax, 0.52, 0.9, "Episode 2", "FontSize", font_size, "FontName", 'Times New Roman','Units','normalized')
        
ax.XLim = [global_start_t global_end_t];
ax.YLim = [0 max(n_iter_hist)+.5];
ax.XLabel.String = 'Time / s';
ax.YLabel.String = '# of Lin. Proj. Step';
ax.XLabel.Interpreter = 'latex';
ax.YLabel.Interpreter = 'latex';

%% HardNet (number of iterations) — Zoomed-in view
fig = figure(12); clf;
ax = axes(fig);
set(fig, 'Units', 'centimeters');
fig.Position(3:4) = [figW figH];
hold(ax, 'on');
grid(ax, 'on');
box(ax, 'on');
grid(ax, 'minor');
set(ax, 'FontName', 'Times New Roman');
set(ax, 'FontSize', ax_font_size);
set(ax, 'LineWidth', 1.1);
set(ax, 'TickLabelInterpreter', 'latex');

data = dataSet{3};
color = color_list(3);
    
t = data.t;

n_iter_hist = data.iter_hist;

plot(ax, t, n_iter_hist, "Color", color, "LineWidth", line_width, "LineStyle", "-", "HandleVisibility", "off"); hold on
        
ax.XLim = [start_t end_t];
ax.YLim = [0 max(n_iter_hist)+.5];
ax.XLabel.String = 'Time / s';
ax.YLabel.String = '# of Lin. Proj. Step';
ax.XLabel.Interpreter = 'latex';
ax.YLabel.Interpreter = 'latex';

%% HardNet (convergence)
fig = figure(13); clf;
ax = axes(fig);
set(fig, 'Units', 'centimeters');
fig.Position(3:4) = [figW figH];
hold(ax, 'on');
grid(ax, 'on');
box(ax, 'on');
grid(ax, 'minor');
set(ax, 'FontName', 'Times New Roman');
set(ax, 'FontSize', ax_font_size);
set(ax, 'LineWidth', 1.1);
set(ax, 'TickLabelInterpreter', 'latex');

data = dataSet{3};
color = color_list(3);
    
t = data.t;
n_conv_hist = data.conv_hist;

plot(ax, t, n_conv_hist, "Color", color, "LineWidth", line_width, "LineStyle", "-", "HandleVisibility", "off"); hold on

plot(ax, [warmup_time+ep_time, warmup_time+ep_time], [-5e2 5e2], "Color", "black", "LineWidth", line_width, "LineStyle", "-."); hold on
text(ax, 0.02, 0.9, "Episode 1", "FontSize", font_size, "FontName", 'Times New Roman','Units','normalized')
text(ax, 0.52, 0.9, "Episode 2", "FontSize", font_size, "FontName", 'Times New Roman','Units','normalized')

% y tick (true false)
yticks(ax, [0 1]); yticklabels(ax, {'False', 'True'});
        
ax.XLim = [global_start_t global_end_t];
ax.YLim = [-.5 1.5];
ax.XLabel.String = 'Time / s';
ax.YLabel.String = 'Converged';
ax.XLabel.Interpreter = 'latex';
ax.YLabel.Interpreter = 'latex';


%% ZOOM TOP VIEW OF THE ERRORS
fig = figure(14); clf;
ax = axes(fig);
hold(ax, 'on');
grid(ax, 'on');
grid(ax, 'minor');
box(ax, 'on');

set(fig, 'Units', 'centimeters');
fig.Position(3:4) = [figW figH*1.5];
set(ax, 'FontName', 'Times New Roman');
set(ax, 'FontSize', ax_font_size);
set(ax, 'LineWidth', 1.1);
set(ax, 'TickLabelInterpreter', 'latex');
ax.XLabel.String = '$q_1-{q_d}_1$ / deg'; ax.XLabel.Interpreter = 'latex';
ax.YLabel.String = '$q_2-{q_d}_2$ / deg'; ax.YLabel.Interpreter = 'latex';

maxminX = [inf 0]; maxminY = [inf -inf];
for ctrl_idx = 1:1:length(dataSet)
    data = dataSet{ctrl_idx};
    CTRL_INFO = data.CTRL_INFO;

    e1_hist = data.x1_hist-data.xd1_hist;
    e1_hist = rad2deg(e1_hist);
    e1_hist = [e1_hist, nan(2, length(t)-length(e1_hist))];
    e1_hist = e1_hist(:, ctrl_obs_idx);
    color = color_list(ctrl_idx);

    plot(ax, e1_hist(1,:), e1_hist(2,:), "Color", color, "LineWidth", line_width, "LineStyle", "-");
    % marker_idx = round(linspace(1, length(x1_hist), 5));
    % plot(ax, x1_hist(1,marker_idx), x1_hist(2,marker_idx), "Color", color, "Marker", "o", "MarkerSize", 6, "LineStyle", "none");

    maxminX = [min(maxminX(1), min(e1_hist(1,:))) max(maxminX(2), max(e1_hist(1,:)))];
    maxminY = [min(maxminY(1), min(e1_hist(2,:))) max(maxminY(2), max(e1_hist(2,:)))];
end
len = maxminX(2)-maxminX(1); ratio = .1;
ax.XLim = [maxminX(1)-len*ratio maxminX(2)+len*ratio];
len = maxminY(2)-maxminY(1); ratio = .1;
ax.YLim = [maxminY(1)-len*ratio maxminY(2)+len*ratio];

backstep_list = [7,60,10,10];

for ctrl_idx = 1:1:length(dataSet)
    data = dataSet{ctrl_idx};
    CTRL_INFO = data.CTRL_INFO;

    e1_hist = data.x1_hist-data.xd1_hist;
    e1_hist = rad2deg(e1_hist);
    e1_hist = [e1_hist, nan(2, length(t)-length(e1_hist))];
    e1_hist = e1_hist(:, ctrl_obs_idx);
    color = color_list(ctrl_idx);

    backstep_for_arrow = backstep_list(ctrl_idx);
    smoothen_traj = smoothdata(e1_hist, 2, 'movmean', 10);
    % e1_hist(1,end-backstep_for_arrow), e1_hist(2,end-backstep_for_arrow),...
    drawArrow(ax,...
        smoothen_traj(1,end-backstep_for_arrow), smoothen_traj(2,end-backstep_for_arrow),...
        smoothen_traj(1,end), smoothen_traj(2,end),...
        color);
    hold on
end

yline(ax, 0, 'k--', 'LineWidth', line_width);
xline(ax, 0, 'k--', 'LineWidth', line_width);

%% SAVE FIGURES
if SAVE_FLAG
    FIG_SAVE_PATH = "figures";
    [~,~] = mkdir(FIG_SAVE_PATH);

    for idx = 1:14

        f_name = FIG_SAVE_PATH + "/Fig" + string(idx);

        saveas(figure(idx), f_name + ".png")

        figure(idx);
        % set(gcf, 'Position', [0, 0, fig_width, fig_height]); % [left, bottom, width, height] 
        exportgraphics(gcf, f_name+'.eps', 'ContentType', 'vector')
        % exportgraphics(figure(idx), f_name+'.eps',"Padding","figure")
    
        % matlab2tikz(char(f_name+".tex"))

        fprintf("Saved Figure %d\n", idx)
    end
end

beep()

%% LOCAL FUNCTIONS

function drawArrow(ax, x1, y1, x2, y2, color)

    % axes position (normalized in figure)
    axPos = ax.Position;

    % axis limits
    xl = xlim(ax);
    yl = ylim(ax);

    % data -> normalized axes
    xn1 = (x1-xl(1))/(xl(2)-xl(1));
    yn1 = (y1-yl(1))/(yl(2)-yl(1));

    xn2 = (x2-xl(1))/(xl(2)-xl(1));
    yn2 = (y2-yl(1))/(yl(2)-yl(1));

    % axes -> figure
    xf1 = axPos(1) + xn1*axPos(3);
    yf1 = axPos(2) + yn1*axPos(4);

    xf2 = axPos(1) + xn2*axPos(3);
    yf2 = axPos(2) + yn2*axPos(4);

    annotation(gcf,'arrow',...
        [xf1 xf2],...
        [yf1 yf2],...
        'Color',color,...
        'LineWidth',1.5,...
        'HeadLength',14,...
        'HeadWidth',14);

end