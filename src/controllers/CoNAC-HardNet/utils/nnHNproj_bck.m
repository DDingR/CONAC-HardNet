function [nn, out] = nnHNproj(nn, opt, in)

    %% PARAMETERS
    max_iter = 100;     % maximum iteration for projection
    epsilon = 0e-3;     % damping factor for Hessian matrix
    tol = 1e-6;         % tolerance for constraint satisfaction

    uMax2 = opt.cstr.uMax2;     % control input 2 max constraint
    u_ball = opt.cstr.u_ball;   % control input ball constraint

    %% MAIN LOOP
    grad_HNproj = eye(2);

    y = in; % initial output
    for iter = 1:1:max_iter
    % This function calculates the Jacobian matrix and residual vector for the projection step.
    %
    %   b_l <= c(y) <= b_u
    %
    %   - y = [u1; u2]
    %   - c(y) = [u2; u1^2+u2^2]
    %   - b_l = [-uMax2; 0];
    %   - b_u = [uMax2; u_ball^2];
    %

        % Hard constraint definitions
        b_l = [-uMax2; 0];              % lower bound
        b_u = [uMax2; u_ball^2];        % upper bound
        c = [y(2); y(1)^2 + y(2)^2];    % constraint function

        % Jacobian matrix and residual vector calculation
        J = [
            0 1;
            2*y(1) 2*y(2)
        ];
        r = max(0, c-b_u) - max(0, b_l-c); % residual vector

        % constraints satisfied, exit loop
        if norm(r) < tol
            break; 
        end

        % project!
        H = J*J' + epsilon*eye(2); % Hessian matrix
        y = y - J'*(H\r);

        % HardNet projection gradient calculation
        drdy = (grad_ReLU(c-b_u) + grad_ReLU(b_l-c)) * J; 
        iter_grad_HNproj = eye(2) - J'*(H\drdy);
        grad_HNproj = iter_grad_HNproj * grad_HNproj; % chain rule
    end

    %% FINAL OUTPUT
    out = y; % final output after projection    
    nn.grad_HNproj = grad_HNproj; % store the projection gradient in the neural network structure
end

%% LOCAL FUNCTION
function dydx = grad_ReLU(x)
    dydx = double(x>0);
    dydx = diag(dydx);
end