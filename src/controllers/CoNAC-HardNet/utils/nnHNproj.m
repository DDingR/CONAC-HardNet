function [nn, out] = nnHNproj(nn, opt, in)

%% PARAMETERS
max_iter = 15;
Epsilon = diag([1e-2, 1e1]);
tol = 1e-2;

uMax2  = opt.cstr.uMax2;
u_ball = opt.cstr.u_ball;

% assert(min(eig(Epsilon)) > 0, ...
%     'epsilon must be strictly positive.');

%% INITIALIZATION
y = in(:);

assert(numel(y) == 2, ...
    'nnHNproj input must be a 2-by-1 vector.');

% dout/din
grad_HNproj = eye(2, 'like', y);

n_updates = 0;

%% CONSTRAINT BOUNDS
% y와 동일한 자료형으로 맞춘다.
b_l = cast([-uMax2; 0], 'like', y);
b_u = cast([uMax2; u_ball^2], 'like', y);

%% HARDNET++ ITERATIONS
for iter = 1:max_iter

    %% Constraint function
    c = [
        y(2);
        y(1)^2 + y(2)^2
    ];

    %% Constraint Jacobian: dc/dy
    J = [
        0,       1;
        2*y(1), 2*y(2)
    ];

    %% Constraint residual
    r = max(0, c-b_u) ...
      - max(0, b_l-c);

    %% Early stopping
    if norm(r, inf) <= tol
        break;
    end

    %% Residual derivative: dr/dc
    %
    % PyTorch ReLU convention:
    % derivative is zero exactly at the boundary.

    active_upper = cast(c > b_u, 'like', y);
    active_lower = cast(c < b_l, 'like', y);

    D = diag(active_upper + active_lower);

    %% HardNet++ forward update
    H = J*J.' + Epsilon;

    % Remove small floating-point asymmetry
    H = 0.5*(H + H.');

    % H*alpha = r
    alpha = H \ r;

    % Save the forward output without modifying current y yet
    y_next = y - J.'*alpha;

    %% Exact local Jacobian
    %
    % A = dy_next/dy
    %
    % It is computed column-by-column using e1 and e2.

    A = zeros(2, 2, 'like', y);

    for j = 1:2

        %% Seed direction e_j
        dy = zeros(2, 1, 'like', y);
        dy(j) = 1;

        %% dc = J*dy
        dc = J*dy;

        %% dr = D*dc
        dr = D*dc;

        %% Differential of J
        %
        % J(y) = [0, 1;
        %         2*y1, 2*y2]
        %
        % dJ = [0, 0;
        %       2*dy1, 2*dy2]

        dJ = [
            0,       0;
            2*dy(1), 2*dy(2)
        ];

        %% Differential of H
        %
        % H = J*J' + epsilon*I
        %
        % dH = dJ*J' + J*dJ'

        dH = dJ*J.' + J*dJ.';
        dH = 0.5*(dH + dH.');

        %% Differential of alpha
        %
        % H*alpha = r
        %
        % dH*alpha + H*dalpha = dr
        %
        % dalpha = H\(dr - dH*alpha)

        dalpha = H \ (dr - dH*alpha);

        %% Differential of projection update
        %
        % y_next = y - J'*alpha
        %
        % dy_next = dy - dJ'*alpha - J'*dalpha

        dy_next = dy ...
                - dJ.'*alpha ...
                - J.'*dalpha;

        % dy=e_j, so this is column j of A
        A(:,j) = dy_next;
    end

    %% Chain rule over all projection iterations
    %
    % A:
    %   dy^[iter+1]/dy^[iter]
    %
    % grad_HNproj:
    %   dy^[iter]/dy^[0]
    %
    % New grad_HNproj:
    %   dy^[iter+1]/dy^[0]

    grad_HNproj = A * grad_HNproj;

    %% Forward-state update
    y = y_next;
    n_updates = n_updates + 1;
end

%% FINAL FEASIBILITY CHECK
c_final = [
    y(2);
    y(1)^2 + y(2)^2
];

r_final = max(0, c_final-b_u) ...
        - max(0, b_l-c_final);

violation = norm(r_final, inf);

%% OUTPUT
out = y;

% Stored convention:
% grad_HNproj(i,j) = dout_i/din_j
nn.grad_HNproj = grad_HNproj;

nn.proj_residual  = r_final;
nn.proj_violation = violation;
nn.proj_converged = violation <= tol;
nn.proj_iters     = n_updates;

% Diagnostics
nn.proj_grad_singular_values = svd(grad_HNproj);
nn.proj_grad_norm = norm(grad_HNproj, 2);

end