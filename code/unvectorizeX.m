% Converts the primal optimization variable into something more readable
function xx = unvectorizeX(params,idx,x)
    % Extract the variables one step at a time
    for t = 1:params.ntime
        if params.nboost > 0
            xx.u_A{t}=x(idx.X.u_A{t});
            xx.i_A{t}=x(idx.X.i_A{t});
            xx.i_A_dot{t}=x(idx.X.i_A_dot{t});
            xx.lambda_A{t}=x(idx.X.lambda_A{t});
            xx.lambda_A_dot{t}=x(idx.X.lambda_A_dot{t});
            xx.p_A{t}=x(idx.X.p_A{t});
            xx.e_A{t}=x(idx.X.e_A{t});
        end

        if params.ndc > 0
            xx.v_B{t}=x(idx.X.v_B{t});
            xx.v_B_dot{t}=x(idx.X.v_B_dot{t});
            xx.u_B{t}=x(idx.X.u_B{t});
            xx.p_B{t}=x(idx.X.p_B{t});
            xx.e_B{t}=x(idx.X.e_B{t});
        end

        if params.ndcdc > 0
            xx.u_C{t}=x(idx.X.u_C{t});
            xx.lambda_C{t}=x(idx.X.lambda_C{t});
            xx.lambda_C_dot{t}=x(idx.X.lambda_C_dot{t});
            xx.i_C{t}=x(idx.X.i_C{t});
            xx.i_C_dot{t}=x(idx.X.i_C_dot{t});
            xx.p_C{t}=x(idx.X.p_C{t});
            xx.e_C{t}=x(idx.X.e_C{t});
        end

        if params.nacdc > 0
            xx.i_E_d{t}=x(idx.X.i_E_d{t});
            xx.i_E_q{t}=x(idx.X.i_E_q{t});
            xx.i_E_d_dot{t}=x(idx.X.i_E_d_dot{t});
            xx.i_E_q_dot{t}=x(idx.X.i_E_q_dot{t});
            xx.lambda_E{t}=x(idx.X.lambda_E{t});
            xx.lambda_E_dot{t}=x(idx.X.lambda_E_dot{t});
            xx.xi_E_s{t}=x(idx.X.xi_E_s{t});
            xx.xi_E_c{t}=x(idx.X.xi_E_c{t});
        end

        if params.nac > 0
            xx.v_F_d{t}=x(idx.X.v_F_d{t});
            xx.v_F_q{t}=x(idx.X.v_F_q{t});
            xx.v_F_d_dot{t}=x(idx.X.v_F_d_dot{t});
            xx.v_F_q_dot{t}=x(idx.X.v_F_q_dot{t});
            xx.u_F_d{t}=x(idx.X.u_F_d{t});
            xx.u_F_q{t}=x(idx.X.u_F_q{t});
            xx.p_F{t}=x(idx.X.p_F{t});
            xx.e_F{t}=x(idx.X.e_F{t});
        end

        if params.ninv > 0
            xx.u_G{t}=x(idx.X.u_G{t});
            xx.i_G{t}=x(idx.X.i_G{t});
            xx.v_G_dc{t}=x(idx.X.v_G_dc{t});
            xx.v_G_dc_dot{t}=x(idx.X.v_G_dc_dot{t});
            xx.i_G_d{t}=x(idx.X.i_G_d{t});
            xx.i_G_q{t}=x(idx.X.i_G_q{t});
            xx.i_G_d_dot{t}=x(idx.X.i_G_d_dot{t});
            xx.i_G_q_dot{t}=x(idx.X.i_G_q_dot{t});
            xx.lambda_G{t}=x(idx.X.lambda_G{t});
            xx.lambda_G_dot{t}=x(idx.X.lambda_G_dot{t});
            xx.xi_G_s{t}=x(idx.X.xi_G_s{t});
            xx.xi_G_c{t}=x(idx.X.xi_G_c{t});
            xx.p_G{t}=x(idx.X.p_G{t});
            xx.e_G{t}=x(idx.X.e_G{t});
        end
    end
end
