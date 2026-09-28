x_in = [(x1-xd1); (x2-xd2); xd3];  % input vector for NN

[nn, x_out] = nnForward(nn, opt, x_in);       % NN forward propagation
u = x_out;
