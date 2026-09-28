x_in = [(x1-xd1); (x2-xd2); xd3];  % input vector for NN

[nn, x_out_uncon] = nnForward(nn, opt, x_in);       % NN forward propagation
[nn, x_out] = nnHNproj(nn, opt, x_out_uncon);       % NN output projection
u = x_out;
