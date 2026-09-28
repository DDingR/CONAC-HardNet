function [nn, opt] = nnBackward(nn, opt, e, u_NN)

    %% NN GRADIENT CALCULATION
    nnGrad = nnGradient(nn, opt);

    % dead-zone
    if norm(e) < opt.e_tol
        return;
    end

    %% SOFT CONSTRAINTS (CONAC)
    % active set check
    [c, cd] = nnCstr(nn, opt, u_NN, nnGrad);
    
    ActSet  = double(c>0);
    ActSet = ones(size(ActSet)); % ignore constraints for now
    % ActSet = zeros(size(ActSet)); % ignore constraints for now
    lbd  = opt.lbd .* ActSet;
    
    %% HARD CONSTRAINTS (HardNet)
    grad_HNproj = nn.grad_HNproj;
    % grad_HNproj = grad_HNproj';
    HNnnGrad = grad_HNproj * nnGrad; % chain rule
    
    % HN_lbd = .0;
    % nnGrad = ((1-HN_lbd)*grad_HNproj + HN_lbd*eye(2,2)) * nnGrad; chain rule

    %% GRADIENT CALCULATION
    % find gradient; theta, lambda
    th_grad = - opt.alpha * (HNnnGrad'*opt.W*e + cd'*lbd);
    th_grad = th_grad + - opt.rho * nn.th;
    lbd_grad = diag(opt.beta) * c;

    th_grad = th_grad + - opt.alpha * (nn.drdy*nnGrad)'*nn.r;
    
    th_grad = th_grad * opt.dt;
    lbd_grad = lbd_grad * opt.dt;
    
    %% UPDATE
    nn.th = nn.th + th_grad;
    opt.lbd = lbd + lbd_grad;
    opt.lbd = max(opt.lbd, 0);

    %% TERMINATION
    
end