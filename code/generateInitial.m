% Generates an initial guess for x

function x = generateInitial(params,idx)

% Initialize memory
x = zeros(idx.X.size,1);

for t = 1:params.ntime

    % Boost
    if params.nboost > 0
        x(idx.X.u_A{t}) = (params.u_A_max{t}+params.u_A_min{t})/2 .* ...
            params.u_A_switch{t};
        x(idx.X.lambda_A{t}) = params.lambda_A_0;
        x(idx.X.lambda_A_dot{t}) = zeros(params.nboost,1);
        x(idx.X.i_A{t}) = (params.i_A_max{t}+params.i_A_min{t})/2;
        x(idx.X.i_A_dot{t}) = zeros(params.nboost,1);
        x(idx.X.p_A{t}) = zeros(params.nboost,1);
        x(idx.X.e_A{t}) = params.e_A_0 .* params.u_A_switch{t};
    end

    % DC buses
    if(params.ndc > 0)
        x(idx.X.v_B{t}) = params.v_B_0;
        x(idx.X.v_B_dot{t}) = zeros(params.ndc,1);
        x(idx.X.u_B{t}) = (params.u_B_max{t}+params.u_B_min{t})/2 .* ...
            params.u_B_switch{t};
        x(idx.X.p_B{t}) = zeros(params.ndc,1);
        x(idx.X.e_B{t}) = params.e_B_0 .* params.u_B_switch{t};
    end

    % Connections between DC buses
    if(params.ndcdc > 0)
        x(idx.X.u_C{t})=(params.u_C_max{t}+params.u_C_min{t})/2 .* ...
            params.u_C_switch{t};
        x(idx.X.lambda_C{t})= params.lambda_C_0;
        x(idx.X.lambda_C_dot{t}) = zeros(params.ndcdc,1);
        x(idx.X.i_C{t})=(params.i_C_max{t}+params.i_C_min{t})/2;
        x(idx.X.i_C_dot{t}) = zeros(params.ndcdc,1);
        x(idx.X.p_C{t}) = zeros(params.ndcdc,1);
        x(idx.X.e_C{t}) = params.e_C_0 .* params.u_C_switch{t};
    end

    % Connections between AC and DC buses
    if(params.nacdc > 0)
        x(idx.X.i_E_d{t}) = params.i_E_d_0;
        x(idx.X.i_E_q{t}) = params.i_E_q_0;
        x(idx.X.i_E_d_dot{t}) = zeros(params.nacdc,1);
        x(idx.X.i_E_q_dot{t}) = zeros(params.nacdc,1);
        x(idx.X.lambda_E{t}) = params.lambda_E_0;
        x(idx.X.lambda_E_dot{t}) = zeros(params.nacdc,1);
        x(idx.X.xi_E_s{t}) = ones(params.nacdc,1);
        x(idx.X.xi_E_c{t}) = ones(params.nacdc,1);
    end

    % AC bus
    if(params.nac > 0)
        x(idx.X.v_F_d{t}) = params.v_F_d_0;
        x(idx.X.v_F_q{t}) = params.v_F_q_0;
        x(idx.X.v_F_d_dot{t}) = zeros(params.nac,1);
        x(idx.X.v_F_q_dot{t}) = zeros(params.nac,1);
        x(idx.X.u_F_d{t}) = (params.u_F_d_max{t}+params.u_F_d_min{t})/2 .* ...
            params.u_F_switch{t};
        x(idx.X.u_F_q{t}) = (params.u_F_d_max{t}+params.u_F_d_min{t})/2 .* ...
            params.u_F_switch{t};
        x(idx.X.p_F{t}) = zeros(params.nac,1);
        x(idx.X.e_F{t}) = params.e_F_0 .* params.u_F_switch{t};
    end

    % Inverters
    if(params.ninv > 0)
        x(idx.X.u_G{t}) = (params.u_G_max{t}+params.u_G_min{t})/2 .* ...
            params.u_G_switch{t};
        x(idx.X.v_G_dc{t}) = params.v_G_dc_0;
        x(idx.X.v_G_dc_dot{t}) = zeros(params.ninv,1);
        x(idx.X.i_G_d{t}) = params.i_G_d_0;
        x(idx.X.i_G_q{t}) = params.i_G_q_0;
        x(idx.X.i_G_d_dot{t}) = zeros(params.ninv,1);
        x(idx.X.i_G_q_dot{t}) = zeros(params.ninv,1);
        x(idx.X.lambda_G{t}) = params.lambda_G_0;
        x(idx.X.lambda_G_dot{t}) = zeros(params.ninv,1);
        x(idx.X.xi_G_s{t}) = ones(params.ninv,1);
        x(idx.X.xi_G_c{t}) = ones(params.ninv,1);
        x(idx.X.p_G{t}) = zeros(params.ninv,1);
        x(idx.X.e_G{t}) = params.e_G_0 .* params.u_G_switch{t};
    end
end
