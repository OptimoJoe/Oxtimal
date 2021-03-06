% Generates the equality constraint for the microgrid
function [g PSchur_left] = generateEquality(params,idx)
    % Grab our core equality functions
    g.eval=@(x)eval_g(params,idx,x);
    g.p=@(x,dx)eval_gp(params,idx,x)*dx;
    g.ps=@(x,y)eval_gp(params,idx,x)'*y;
    g.pps=@(x,dx,y)eval_gpp_dx(params,idx,x,dx)'*y;
    PSchur_left.eval = @(state,dy) eval_schur(params,idx,state.x,dy);
end

% Creates a sparse diagonal matrix from a vector
function A=mydiag(x)
    A=spdiags(x,0,length(x),length(x));
end

% Find the equality constraint
function result = eval_g(params,idx,x)
    % Initialize our result
    result = zeros(idx.Y.size,1);

    % Do the equations for timestep t
    for t=1:params.ntime
        % Boost converter
        if params.nboost > 0
            result(idx.Y.boost{t}) = ...
                params.L_A{t}.*x(idx.X.i_A_dot{t}) ...
                    + params.R_A{t}.*x(idx.X.i_A{t}) ...
                    + params.P_A{t} ./ x(idx.X.i_A{t}) ...
                    - params.v_A{t} ...
                    - x(idx.X.u_A{t}).*params.u_A_switch{t};
            if params.ndc > 0
                result(idx.Y.boost{t}) = result(idx.Y.boost{t}) ...
                    + x(idx.X.lambda_A{t}) .* ...
                        (params.Phi_boost_dc_1*x(idx.X.v_B{t}));
            end
        end

        % DC Bus
        if params.ndc > 0
            result(idx.Y.dc{t}) = ...
                params.C_B{t}.*x(idx.X.v_B_dot{t}) ...
                    + x(idx.X.v_B{t}) ./ params.R_B{t} ...
                    + params.P_B{t} ./ x(idx.X.v_B{t}) ...
                    - x(idx.X.u_B{t}).*params.u_B_switch{t};
            if params.nboost > 0
                result(idx.Y.dc{t}) = result(idx.Y.dc{t}) ...
                    - params.Phi_boost_dc_1'*(x(idx.X.lambda_A{t}) .* ...
                        x(idx.X.i_A{t}));
            end
            if params.ndcdc > 0
                result(idx.Y.dc{t}) = result(idx.Y.dc{t}) ...
                    + params.Phi_dcdc_dc_2' * x(idx.X.i_C{t}) ...
                    - params.Phi_dcdc_dc_3' * (x(idx.X.lambda_C{t}) .* ...
                        x(idx.X.i_C{t}));
            end
            if params.nacdc > 0
                result(idx.Y.dc{t}) = result(idx.Y.dc{t}) ...
                    + params.Xi * params.Phi_acdc_dc_5' * ( ...
                        x(idx.X.lambda_E{t}) .* ( ...
                            x(idx.X.xi_E_c{t}) .* x(idx.X.i_E_d{t}) + ...
                            x(idx.X.xi_E_s{t}) .* x(idx.X.i_E_q{t})));
            end
        end

        % DC-DC connector
        if params.ndcdc > 0
            result(idx.Y.dcdc{t}) = ...
                params.L_C{t} .* x(idx.X.i_C_dot{t}) ...
                    + params.R_C{t} .* x(idx.X.i_C{t}) ...
                    - x(idx.X.u_C{t}) .* params.u_C_switch{t};
            if params.ndc > 0
                result(idx.Y.dcdc{t}) = result(idx.Y.dcdc{t}) ...
                    - params.Phi_dcdc_dc_2*x(idx.X.v_B{t}) ...
                    + x(idx.X.lambda_C{t}) .* ...
                        (params.Phi_dcdc_dc_3*x(idx.X.v_B{t}));
            end
        end

        % AC-DC connector
        if params.nacdc > 0
            result(idx.Y.acdc_d{t}) = ...
                params.L_E{t} .* x(idx.X.i_E_d_dot{t}) ...
                + params.R_E{t} .* x(idx.X.i_E_d{t});
            if params.ndc > 0
                result(idx.Y.acdc_d{t}) = result(idx.Y.acdc_d{t}) + ...
                    - params.Xi * x(idx.X.lambda_E{t}) .* x(idx.X.xi_E_c{t}) ...
                        .* (params.Phi_acdc_dc_5 * x(idx.X.v_B{t}));
            end
            if params.nac > 0
                result(idx.Y.acdc_d{t}) = result(idx.Y.acdc_d{t}) + ...
                    - params.L_E{t} .* x(idx.X.i_E_q{t}) ...
                        .* (params.Phi_acdc_ac_6*params.omega_F{t}) ...
                    + params.Phi_acdc_ac_6 * x(idx.X.v_F_d{t});
            end
            result(idx.Y.acdc_q{t}) = ...
                params.L_E{t} .* x(idx.X.i_E_q_dot{t}) ...
                + params.R_E{t} .* x(idx.X.i_E_q{t});
            if params.ndc > 0
                result(idx.Y.acdc_q{t}) = result(idx.Y.acdc_q{t}) + ...
                    - params.Xi * x(idx.X.lambda_E{t}) .* x(idx.X.xi_E_s{t}) ...
                        .* (params.Phi_acdc_dc_5 * x(idx.X.v_B{t}));
            end
            if params.nac > 0
                result(idx.Y.acdc_q{t}) = result(idx.Y.acdc_q{t}) + ...
                    + params.L_E{t} .* x(idx.X.i_E_d{t}) ...
                        .* (params.Phi_acdc_ac_6*params.omega_F{t}) ...
                    + params.Phi_acdc_ac_6 * x(idx.X.v_F_q{t});
            end
        end

        % AC bus
        if params.nac > 0
            result(idx.Y.ac_d{t}) = ...
                params.C_F{t} .* x(idx.X.v_F_d_dot{t}) ...
                + x(idx.X.v_F_d{t}) ./ params.R_F{t} ...
                + params.P_F_d{t} ./ x(idx.X.v_F_d{t}) ...
                - params.omega_F{t}.*params.C_F{t}.*x(idx.X.v_F_q{t}) ...
                - x(idx.X.u_F_d{t}) .* params.u_F_switch{t};
            if params.nacdc > 0
                result(idx.Y.ac_d{t}) = result(idx.Y.ac_d{t}) ...
                    - params.Phi_acdc_ac_6' * x(idx.X.i_E_d{t});
            end
            if params.ninv > 0
                result(idx.Y.ac_d{t}) = result(idx.Y.ac_d{t}) ...
                    - params.Phi_inv_ac_7' * x(idx.X.i_G_d{t});
            end
            result(idx.Y.ac_q{t}) = ...
                params.C_F{t} .* x(idx.X.v_F_q_dot{t}) ...
                + x(idx.X.v_F_q{t}) ./ params.R_F{t} ...
                + params.P_F_q{t} ./ x(idx.X.v_F_q{t}) ...
                + params.omega_F{t}.*params.C_F{t}.*x(idx.X.v_F_d{t}) ...
                - x(idx.X.u_F_q{t}) .* params.u_F_switch{t};
            if params.nacdc > 0
                result(idx.Y.ac_q{t}) = result(idx.Y.ac_q{t}) ...
                    - params.Phi_acdc_ac_6' * x(idx.X.i_E_q{t});
            end
            if params.ninv > 0
                result(idx.Y.ac_q{t}) = result(idx.Y.ac_q{t}) ...
                    - params.Phi_inv_ac_7' * x(idx.X.i_G_q{t});
            end
        end

        % Inverters
        if params.ninv > 0
            result(idx.Y.inv_gen{t}) = ...
                params.R_G_dc{t} .* x(idx.X.i_G{t}) ...
                - params.v_G{t} ...
                - x(idx.X.u_G{t}) .* params.u_G_switch{t} ...
                + x(idx.X.v_G_dc{t});
            result(idx.Y.inv_dc{t}) = ...
                params.C_G_dc{t} .* x(idx.X.v_G_dc_dot{t}) ...
                - x(idx.X.i_G{t}) ...
                + params.Xi * x(idx.X.lambda_G{t}) .* ( ...
                    x(idx.X.xi_G_c{t}) .* x(idx.X.i_G_d{t}) + ...
                    x(idx.X.xi_G_s{t}) .* x(idx.X.i_G_q{t}));
            result(idx.Y.inv_d{t}) = ...
                params.L_G{t} .* x(idx.X.i_G_d_dot{t}) ...
                + params.R_G{t} .* x(idx.X.i_G_d{t}) ...
                - params.Xi * x(idx.X.lambda_G{t}) .* x(idx.X.xi_G_c{t}) ...
                    .* x(idx.X.v_G_dc{t});
            if params.nac > 0
                result(idx.Y.inv_d{t}) = result(idx.Y.inv_d{t}) + ...
                    - params.L_G{t} .* x(idx.X.i_G_q{t}) ...
                        .* (params.Phi_inv_ac_7*params.omega_F{t}) ...
                    + params.Phi_inv_ac_7 * x(idx.X.v_F_d{t});
            end
            result(idx.Y.inv_q{t}) = ...
                params.L_G{t} .* x(idx.X.i_G_q_dot{t}) ...
                + params.R_G{t} .* x(idx.X.i_G_q{t}) ...
                - params.Xi * x(idx.X.lambda_G{t}) .* x(idx.X.xi_G_s{t}) ...
                    .* x(idx.X.v_G_dc{t});
            if params.nac > 0
                result(idx.Y.inv_q{t}) = result(idx.Y.inv_q{t}) + ...
                    + params.L_G{t} .* x(idx.X.i_G_d{t}) ...
                        .* (params.Phi_inv_ac_7*params.omega_F{t}) ...
                    + params.Phi_inv_ac_7 * x(idx.X.v_F_q{t});
            end
        end

        % Trigonometric
        names = trig_names(params);
        for i = 1:length(names)
            result = trig_eval(params,idx,x,names{i},t,result);
        end

        % Discretization
        names = disc_names(params);
        for i = 1:size(names,1)
            result = disc_eval(params,idx,x,names{i,1},names{i,2},names{i,3},...
                t,result);
        end

        % Power
        names = power_names(params);
        for i = 1:size(names,1)
            result = power_eval(params,idx,x,names{i,1},names{i,2}, ...
                names{i,3},names{i,4},t,result);
        end
        names = power_dq0_names(params);
        for i = 1:size(names,1)
            result = power_dq0_eval(params,idx,x,names{i,1},names{i,2}, ...
                names{i,3},names{i,4},t,result);
        end
    end

    % Scale the result by the number of time steps
    result = result / params.ntime;
end

% Find the total derivative of g
function gp = eval_gp(params,idx,x)

    % Cache our results
    persistent cache

    % Grab our result from cache if possible
    [gp cache] = getCached(cache,struct('x',x),'gp');
    if ~isempty(gp)
        return;
    end

    % Initialize everything to zero
    gp=sparse(idx.Y.size,idx.X.size);

    % Do the equations for timestep t
    for t=1:params.ntime

        % Boost converter
        if params.nboost > 0
            gp(idx.Y.boost{t},idx.X.i_A_dot{t}) = ...
                mydiag(params.L_A{t});
            gp(idx.Y.boost{t},idx.X.i_A{t}) = ...
                mydiag(params.R_A{t}) ...
                - mydiag(params.P_A{t} ./ x(idx.X.i_A{t}).^2);
            gp(idx.Y.boost{t},idx.X.u_A{t}) = ...
                -mydiag(params.u_A_switch{t});
            if params.ndc > 0
                gp(idx.Y.boost{t},idx.X.v_B{t}) = ...
                    mydiag(x(idx.X.lambda_A{t}))*params.Phi_boost_dc_1;
                gp(idx.Y.boost{t},idx.X.lambda_A{t}) = ...
                    mydiag(params.Phi_boost_dc_1*x(idx.X.v_B{t}));
            end
        end

        % DC bus
        if params.ndc > 0
            gp(idx.Y.dc{t},idx.X.v_B_dot{t}) = mydiag(params.C_B{t});
            gp(idx.Y.dc{t},idx.X.u_B{t}) = ...
                -mydiag(params.u_B_switch{t});
            gp(idx.Y.dc{t},idx.X.v_B{t}) = ...
                mydiag(1./params.R_B{t}) ...
                - mydiag(params.P_B{t} ./ x(idx.X.v_B{t}).^2);
            if params.nboost > 0
                gp(idx.Y.dc{t},idx.X.lambda_A{t}) = ...
                    - params.Phi_boost_dc_1'*mydiag(x(idx.X.i_A{t}));
                gp(idx.Y.dc{t},idx.X.i_A{t}) = ...
                    - params.Phi_boost_dc_1'*mydiag(x(idx.X.lambda_A{t}));
            end
            if params.ndcdc > 0
                gp(idx.Y.dc{t},idx.X.i_C{t}) = ...
                    + params.Phi_dcdc_dc_2' ...
                    - params.Phi_dcdc_dc_3' * mydiag(x(idx.X.lambda_C{t}));
                gp(idx.Y.dc{t},idx.X.lambda_C{t}) = ...
                    - params.Phi_dcdc_dc_3' * mydiag(x(idx.X.i_C{t}));
            end
            if params.nacdc > 0
                gp(idx.Y.dc{t},idx.X.lambda_E{t}) = ...
                    params.Xi * params.Phi_acdc_dc_5' * ...
                    mydiag(x(idx.X.xi_E_c{t}).*x(idx.X.i_E_d{t}) + ...
                           x(idx.X.xi_E_s{t}).*x(idx.X.i_E_q{t}));
                gp(idx.Y.dc{t},idx.X.xi_E_c{t}) = ...
                    params.Xi * params.Phi_acdc_dc_5' * ...
                    mydiag(x(idx.X.lambda_E{t}).*x(idx.X.i_E_d{t}));
                gp(idx.Y.dc{t},idx.X.i_E_d{t}) = ...
                    params.Xi * params.Phi_acdc_dc_5' * ...
                    mydiag(x(idx.X.lambda_E{t}).*x(idx.X.xi_E_c{t}));
                gp(idx.Y.dc{t},idx.X.xi_E_s{t}) = ...
                    params.Xi * params.Phi_acdc_dc_5' * ...
                    mydiag(x(idx.X.lambda_E{t}).*x(idx.X.i_E_q{t}));
                gp(idx.Y.dc{t},idx.X.i_E_q{t}) = ...
                    params.Xi * params.Phi_acdc_dc_5' * ...
                    mydiag(x(idx.X.lambda_E{t}).*x(idx.X.xi_E_s{t}));
            end
        end

        % DC-DC connector
        if params.ndcdc > 0
            gp(idx.Y.dcdc{t},idx.X.i_C_dot{t})=mydiag(params.L_C{t});
            gp(idx.Y.dcdc{t},idx.X.i_C{t}) = ...
                mydiag(params.R_C{t});
            gp(idx.Y.dcdc{t},idx.X.u_C{t}) = ...
                -mydiag(params.u_C_switch{t});

            if params.ndc > 0
                gp(idx.Y.dcdc{t},idx.X.v_B{t}) = ...
                    - params.Phi_dcdc_dc_2 ...
                    + mydiag(x(idx.X.lambda_C{t})) * params.Phi_dcdc_dc_3;
                gp(idx.Y.dcdc{t},idx.X.lambda_C{t}) = ...
                    + mydiag(params.Phi_dcdc_dc_3 * x(idx.X.v_B{t}));
            end
        end

        % AC-DC connector
        if params.nacdc > 0
            gp(idx.Y.acdc_d{t},idx.X.i_E_d_dot{t}) = ...
                mydiag(params.L_E{t});
            gp(idx.Y.acdc_d{t},idx.X.i_E_d{t}) = ...
                mydiag(params.R_E{t});
            if params.ndc > 0
                gp(idx.Y.acdc_d{t},idx.X.lambda_E{t}) = ...
                    - params.Xi * mydiag( ...
                        x(idx.X.xi_E_c{t}) .* ...
                        (params.Phi_acdc_dc_5 * x(idx.X.v_B{t})));
                gp(idx.Y.acdc_d{t},idx.X.xi_E_c{t}) = ...
                    - params.Xi * mydiag( ...
                        x(idx.X.lambda_E{t}) .* ...
                        (params.Phi_acdc_dc_5 * x(idx.X.v_B{t})));
                gp(idx.Y.acdc_d{t},idx.X.v_B{t}) = ...
                    - params.Xi * mydiag( ...
                        x(idx.X.lambda_E{t}) .* x(idx.X.xi_E_c{t})) * ...
                    params.Phi_acdc_dc_5;
            end
            if params.nac > 0
                gp(idx.Y.acdc_d{t},idx.X.i_E_q{t}) = ...
                    - mydiag( ...
                        params.L_E{t} .* ...
                        (params.Phi_acdc_ac_6*params.omega_F{t}));
                gp(idx.Y.acdc_d{t},idx.X.v_F_d{t}) = ...
                    params.Phi_acdc_ac_6;
            end

            gp(idx.Y.acdc_q{t},idx.X.i_E_q_dot{t}) = ...
                mydiag(params.L_E{t});
            gp(idx.Y.acdc_q{t},idx.X.i_E_q{t}) = ...
                mydiag(params.R_E{t});
            if params.ndc > 0
                gp(idx.Y.acdc_q{t},idx.X.lambda_E{t}) = ...
                    - params.Xi * mydiag( ...
                        x(idx.X.xi_E_s{t}) .* ...
                        (params.Phi_acdc_dc_5 * x(idx.X.v_B{t})));
                gp(idx.Y.acdc_q{t},idx.X.xi_E_s{t}) = ...
                    - params.Xi * mydiag( ...
                        x(idx.X.lambda_E{t}) .* ...
                        (params.Phi_acdc_dc_5 * x(idx.X.v_B{t})));
                gp(idx.Y.acdc_q{t},idx.X.v_B{t}) = ...
                    - params.Xi * mydiag( ...
                        x(idx.X.lambda_E{t}) .* x(idx.X.xi_E_s{t})) * ...
                    params.Phi_acdc_dc_5;
            end
            if params.nac > 0
                gp(idx.Y.acdc_q{t},idx.X.i_E_d{t}) = ...
                    mydiag( ...
                        params.L_E{t} .* ...
                        (params.Phi_acdc_ac_6*params.omega_F{t}));
                gp(idx.Y.acdc_q{t},idx.X.v_F_q{t}) = ...
                    params.Phi_acdc_ac_6;
            end
        end

        % AC bus
        if params.nac > 0
            gp(idx.Y.ac_d{t},idx.X.v_F_d_dot{t}) = ...
                mydiag(params.C_F{t});
            gp(idx.Y.ac_d{t},idx.X.v_F_d{t}) = ...
                mydiag(1./params.R_F{t}) ...
                - mydiag(params.P_F_d{t} ./ x(idx.X.v_F_d{t}).^2);
            gp(idx.Y.ac_d{t},idx.X.v_F_q{t}) = ...
                -mydiag(params.omega_F{t}.*params.C_F{t});
            gp(idx.Y.ac_d{t},idx.X.u_F_d{t}) = ...
                -mydiag(params.u_F_switch{t});
            if params.nacdc > 0
                gp(idx.Y.ac_d{t},idx.X.i_E_d{t}) = ...
                    -params.Phi_acdc_ac_6';
            end
            if params.ninv > 0
                gp(idx.Y.ac_d{t},idx.X.i_G_d{t}) = ...
                    -params.Phi_inv_ac_7';
            end

            gp(idx.Y.ac_q{t},idx.X.v_F_q_dot{t}) = ...
                mydiag(params.C_F{t});
            gp(idx.Y.ac_q{t},idx.X.v_F_q{t}) = ...
                mydiag(1./params.R_F{t}) ...
                - mydiag(params.P_F_q{t} ./ x(idx.X.v_F_q{t}).^2);
            gp(idx.Y.ac_q{t},idx.X.v_F_d{t}) = ...
                mydiag(params.omega_F{t}.*params.C_F{t});
            gp(idx.Y.ac_q{t},idx.X.u_F_q{t}) = ...
                -mydiag(params.u_F_switch{t});
            if params.nacdc > 0
                gp(idx.Y.ac_q{t},idx.X.i_E_q{t}) = ...
                    -params.Phi_acdc_ac_6';
            end
            if params.ninv > 0
                gp(idx.Y.ac_q{t},idx.X.i_G_q{t}) = ...
                    -params.Phi_inv_ac_7';
            end
        end

        % Inverters
        if params.ninv > 0
            gp(idx.Y.inv_gen{t},idx.X.i_G{t}) = ...
                mydiag(params.R_G_dc{t});
            gp(idx.Y.inv_gen{t},idx.X.u_G{t}) = ...
                -mydiag(params.u_G_switch{t});
            gp(idx.Y.inv_gen{t},idx.X.v_G_dc{t}) = ...
                mydiag(ones(params.ninv,1));

            gp(idx.Y.inv_dc{t},idx.X.v_G_dc_dot{t}) = ...
                mydiag(params.C_G_dc{t});
            gp(idx.Y.inv_dc{t},idx.X.i_G{t}) = ...
                -mydiag(ones(params.ninv,1));
            gp(idx.Y.inv_dc{t},idx.X.lambda_G{t}) = ...
                params.Xi * ...
                mydiag(x(idx.X.xi_G_c{t}).*x(idx.X.i_G_d{t}) + ...
                       x(idx.X.xi_G_s{t}).*x(idx.X.i_G_q{t}));
            gp(idx.Y.inv_dc{t},idx.X.xi_G_c{t}) = ...
                params.Xi * mydiag(x(idx.X.lambda_G{t}).*x(idx.X.i_G_d{t}));
            gp(idx.Y.inv_dc{t},idx.X.i_G_d{t}) = ...
                params.Xi *mydiag(x(idx.X.lambda_G{t}).*x(idx.X.xi_G_c{t}));
            gp(idx.Y.inv_dc{t},idx.X.xi_G_s{t}) = ...
                params.Xi * mydiag(x(idx.X.lambda_G{t}).*x(idx.X.i_G_q{t}));
            gp(idx.Y.inv_dc{t},idx.X.i_G_q{t}) = ...
                params.Xi* mydiag(x(idx.X.lambda_G{t}).*x(idx.X.xi_G_s{t}));

            gp(idx.Y.inv_d{t},idx.X.i_G_d_dot{t}) = ...
                mydiag(params.L_G{t});
            gp(idx.Y.inv_d{t},idx.X.i_G_d{t}) = ...
                mydiag(params.R_G{t});
            gp(idx.Y.inv_d{t},idx.X.lambda_G{t}) = ...
                - params.Xi*mydiag(x(idx.X.xi_G_c{t}) .*x(idx.X.v_G_dc{t}));
            gp(idx.Y.inv_d{t},idx.X.xi_G_c{t}) = ...
                -params.Xi*mydiag(x(idx.X.lambda_G{t}).*x(idx.X.v_G_dc{t}));
            gp(idx.Y.inv_d{t},idx.X.v_G_dc{t}) = ...
                -params.Xi*mydiag(x(idx.X.lambda_G{t}).*x(idx.X.xi_G_c{t}));
            if params.nac > 0
                gp(idx.Y.inv_d{t},idx.X.i_G_q{t}) = ...
                    - mydiag(params.L_G{t} .* ...
                        (params.Phi_inv_ac_7*params.omega_F{t}));
                gp(idx.Y.inv_d{t},idx.X.v_F_d{t}) = ...
                    params.Phi_inv_ac_7;
            end

            gp(idx.Y.inv_q{t},idx.X.i_G_q_dot{t}) = ...
                mydiag(params.L_G{t});
            gp(idx.Y.inv_q{t},idx.X.i_G_q{t}) = ...
                mydiag(params.R_G{t});
            gp(idx.Y.inv_q{t},idx.X.lambda_G{t}) = ...
                - params.Xi*mydiag(x(idx.X.xi_G_s{t}) .*x(idx.X.v_G_dc{t}));
            gp(idx.Y.inv_q{t},idx.X.xi_G_s{t}) = ...
                -params.Xi*mydiag(x(idx.X.lambda_G{t}).*x(idx.X.v_G_dc{t}));
            gp(idx.Y.inv_q{t},idx.X.v_G_dc{t}) = ...
                -params.Xi*mydiag(x(idx.X.lambda_G{t}).*x(idx.X.xi_G_s{t}));
            if params.nac > 0
                gp(idx.Y.inv_q{t},idx.X.i_G_d{t}) = ...
                    + mydiag(params.L_G{t} .* ...
                        (params.Phi_inv_ac_7*params.omega_F{t}));
                gp(idx.Y.inv_q{t},idx.X.v_F_q{t}) = ...
                    params.Phi_inv_ac_7;
            end
        end

        % Trigonometric
        names = trig_names(params);
        for i = 1:length(names)
            gp = trig_p(params,idx,x,names{i},t,gp);
        end

        % Discretization
        names = disc_names(params);
        for i = 1:size(names,1)
            gp = disc_p(params,idx,names{i,1},names{i,2},names{i,3}, ...
                t,gp);
        end

        % Power
        names = power_names(params);
        for i = 1:size(names,1)
            gp = power_p(params,idx,x,names{i,1},names{i,2}, ...
                names{i,3},names{i,4},t,gp);
        end
        names = power_dq0_names(params);
        for i = 1:size(names,1)
            gp = power_dq0_p(params,idx,x,names{i,1},names{i,2}, ...
                names{i,3},names{i,4},t,gp);
        end
    end

    % Scale the result by the number of time steps
    gp = gp / params.ntime;

    % Cache the result
    cache = storeCached(cache,struct('x',x),struct('gp',gp),2);
end

% Find the second total derivative of g in the direction dx
function gpp_dx = eval_gpp_dx(params,idx,x,dx)

    % Initialize everything to zero
    gpp_dx=sparse(idx.Y.size,idx.X.size);

    % Do the equations for timestep t
    for t=1:params.ntime

        % Boost converter
        if params.nboost > 0
            gpp_dx(idx.Y.boost{t},idx.X.i_A{t}) = ...
                2.* mydiag( ...
                    params.P_A{t} .* dx(idx.X.i_A{t}) ./ x(idx.X.i_A{t}).^3);
            if params.ndc > 0
                gpp_dx(idx.Y.boost{t},idx.X.v_B{t}) = ...
                    mydiag(dx(idx.X.lambda_A{t}))*params.Phi_boost_dc_1;
                gpp_dx(idx.Y.boost{t},idx.X.lambda_A{t}) = ...
                    mydiag(params.Phi_boost_dc_1*dx(idx.X.v_B{t}));
            end
        end

        % DC bus
        if params.ndc > 0
            gpp_dx(idx.Y.dc{t},idx.X.v_B{t}) = ...
                2.* mydiag( ...
                    params.P_B{t} .* dx(idx.X.v_B{t}) ./ x(idx.X.v_B{t}).^3);
            if params.nboost > 0
                gpp_dx(idx.Y.dc{t},idx.X.lambda_A{t}) = ...
                    - params.Phi_boost_dc_1'*mydiag(dx(idx.X.i_A{t}));
                gpp_dx(idx.Y.dc{t},idx.X.i_A{t}) = ...
                    - params.Phi_boost_dc_1'*mydiag(dx(idx.X.lambda_A{t}));
            end
            if params.ndcdc > 0
                gpp_dx(idx.Y.dc{t},idx.X.i_C{t}) = ...
                    - params.Phi_dcdc_dc_3' * mydiag(dx(idx.X.lambda_C{t}));
                gpp_dx(idx.Y.dc{t},idx.X.lambda_C{t}) = ...
                    - params.Phi_dcdc_dc_3' * mydiag(dx(idx.X.i_C{t}));
            end
            if params.nacdc > 0
                gpp_dx(idx.Y.dc{t},idx.X.lambda_E{t}) = ...
                    params.Xi * params.Phi_acdc_dc_5' * ...
                    mydiag( ...
                        dx(idx.X.xi_E_c{t}).*x(idx.X.i_E_d{t}) + ...
                        x(idx.X.xi_E_c{t}).*dx(idx.X.i_E_d{t}) + ...
                        dx(idx.X.xi_E_s{t}).*x(idx.X.i_E_q{t}) + ...
                        x(idx.X.xi_E_s{t}).*dx(idx.X.i_E_q{t}));
                gpp_dx(idx.Y.dc{t},idx.X.xi_E_c{t}) = ...
                    params.Xi * params.Phi_acdc_dc_5' * ...
                    mydiag( ...
                        dx(idx.X.lambda_E{t}).*x(idx.X.i_E_d{t}) + ...
                        x(idx.X.lambda_E{t}).*dx(idx.X.i_E_d{t}));
                gpp_dx(idx.Y.dc{t},idx.X.i_E_d{t}) = ...
                    params.Xi * params.Phi_acdc_dc_5' * ...
                    mydiag( ...
                        dx(idx.X.lambda_E{t}).*x(idx.X.xi_E_c{t}) + ...
                        x(idx.X.lambda_E{t}).*dx(idx.X.xi_E_c{t}));
                gpp_dx(idx.Y.dc{t},idx.X.xi_E_s{t}) = ...
                    params.Xi * params.Phi_acdc_dc_5' * ...
                    mydiag( ...
                        dx(idx.X.lambda_E{t}).*x(idx.X.i_E_q{t}) + ...
                        x(idx.X.lambda_E{t}).*dx(idx.X.i_E_q{t}));
                gpp_dx(idx.Y.dc{t},idx.X.i_E_q{t}) = ...
                    params.Xi * params.Phi_acdc_dc_5' * ...
                    mydiag( ...
                        dx(idx.X.lambda_E{t}).*x(idx.X.xi_E_s{t}) + ...
                        x(idx.X.lambda_E{t}).*dx(idx.X.xi_E_s{t}));
            end
        end

        % DC-DC connection
        if params.ndcdc > 0
            if params.ndc > 0
                gpp_dx(idx.Y.dcdc{t},idx.X.v_B{t}) = ...
                    + mydiag(dx(idx.X.lambda_C{t})) * params.Phi_dcdc_dc_3;
                gpp_dx(idx.Y.dcdc{t},idx.X.lambda_C{t}) = ...
                    + mydiag(params.Phi_dcdc_dc_3 * dx(idx.X.v_B{t}));
            end
        end

        % AC-DC connector
        if params.nacdc > 0
            if params.ndc > 0
                gpp_dx(idx.Y.acdc_d{t},idx.X.lambda_E{t}) = ...
                    - params.Xi * mydiag( ...
                        dx(idx.X.xi_E_c{t}) .* ...
                        (params.Phi_acdc_dc_5 * x(idx.X.v_B{t})) + ...
                        x(idx.X.xi_E_c{t}) .* ...
                        (params.Phi_acdc_dc_5 * dx(idx.X.v_B{t})));
                gpp_dx(idx.Y.acdc_d{t},idx.X.xi_E_c{t}) = ...
                    - params.Xi * mydiag( ...
                        dx(idx.X.lambda_E{t}) .* ...
                        (params.Phi_acdc_dc_5 * x(idx.X.v_B{t})) + ...
                        x(idx.X.lambda_E{t}) .* ...
                        (params.Phi_acdc_dc_5 * dx(idx.X.v_B{t})));
                gpp_dx(idx.Y.acdc_d{t},idx.X.v_B{t}) = ...
                    - params.Xi * mydiag( ...
                        dx(idx.X.lambda_E{t}) .* x(idx.X.xi_E_c{t}) + ...
                        x(idx.X.lambda_E{t}) .* dx(idx.X.xi_E_c{t})) * ...
                    params.Phi_acdc_dc_5;
            end

            if params.ndc > 0
                gpp_dx(idx.Y.acdc_q{t},idx.X.lambda_E{t}) = ...
                    - params.Xi * mydiag( ...
                        dx(idx.X.xi_E_s{t}) .* ...
                        (params.Phi_acdc_dc_5 * x(idx.X.v_B{t})) + ...
                        x(idx.X.xi_E_s{t}) .* ...
                        (params.Phi_acdc_dc_5 * dx(idx.X.v_B{t})));
                gpp_dx(idx.Y.acdc_q{t},idx.X.xi_E_s{t}) = ...
                    - params.Xi * mydiag( ...
                        dx(idx.X.lambda_E{t}) .* ...
                        (params.Phi_acdc_dc_5 * x(idx.X.v_B{t})) + ...
                        x(idx.X.lambda_E{t}) .* ...
                        (params.Phi_acdc_dc_5 * dx(idx.X.v_B{t})));
                gpp_dx(idx.Y.acdc_q{t},idx.X.v_B{t}) = ...
                    - params.Xi * mydiag( ...
                        dx(idx.X.lambda_E{t}) .* x(idx.X.xi_E_s{t}) + ...
                        x(idx.X.lambda_E{t}) .* dx(idx.X.xi_E_s{t})) * ...
                    params.Phi_acdc_dc_5;
            end
        end

        % AC bus
        if params.nac > 0
            gpp_dx(idx.Y.ac_d{t},idx.X.v_F_d{t}) = ...
                2.* mydiag( ...
                    params.P_F_d{t}.*dx(idx.X.v_F_d{t}) ./x(idx.X.v_F_d{t}).^3);
            gpp_dx(idx.Y.ac_q{t},idx.X.v_F_q{t}) = ...
                2.* mydiag( ...
                    params.P_F_q{t}.*dx(idx.X.v_F_q{t}) ./x(idx.X.v_F_q{t}).^3);
        end

        % Inverters
        if params.ninv > 0
            gpp_dx(idx.Y.inv_dc{t},idx.X.lambda_G{t}) = ...
                params.Xi * ...
                mydiag( ...
                    dx(idx.X.xi_G_c{t}).*x(idx.X.i_G_d{t}) + ...
                    x(idx.X.xi_G_c{t}).*dx(idx.X.i_G_d{t}) + ...
                    dx(idx.X.xi_G_s{t}).*x(idx.X.i_G_q{t}) + ...
                    x(idx.X.xi_G_s{t}).*dx(idx.X.i_G_q{t}));
            gpp_dx(idx.Y.inv_dc{t},idx.X.xi_G_c{t}) = ...
                params.Xi * ...
                mydiag( ...
                    dx(idx.X.lambda_G{t}).*x(idx.X.i_G_d{t}) + ...
                    x(idx.X.lambda_G{t}).*dx(idx.X.i_G_d{t}));
            gpp_dx(idx.Y.inv_dc{t},idx.X.i_G_d{t}) = ...
                params.Xi * ...
                mydiag( ...
                    dx(idx.X.lambda_G{t}).*x(idx.X.xi_G_c{t}) + ...
                    x(idx.X.lambda_G{t}).*dx(idx.X.xi_G_c{t}));
            gpp_dx(idx.Y.inv_dc{t},idx.X.xi_G_s{t}) = ...
                params.Xi * ...
                mydiag( ...
                    dx(idx.X.lambda_G{t}).*x(idx.X.i_G_q{t}) + ...
                    x(idx.X.lambda_G{t}).*dx(idx.X.i_G_q{t}));
            gpp_dx(idx.Y.inv_dc{t},idx.X.i_G_q{t}) = ...
                params.Xi * ...
                mydiag( ...
                    dx(idx.X.lambda_G{t}).*x(idx.X.xi_G_s{t}) + ...
                    x(idx.X.lambda_G{t}).*dx(idx.X.xi_G_s{t}));

            gpp_dx(idx.Y.inv_d{t},idx.X.lambda_G{t}) = ...
                - params.Xi*mydiag( ...
                    dx(idx.X.xi_G_c{t}) .* x(idx.X.v_G_dc{t}) + ...
                    x(idx.X.xi_G_c{t}) .* dx(idx.X.v_G_dc{t}));
            gpp_dx(idx.Y.inv_d{t},idx.X.xi_G_c{t}) = ...
                -params.Xi*mydiag( ...
                    dx(idx.X.lambda_G{t}).*x(idx.X.v_G_dc{t}) + ...
                    x(idx.X.lambda_G{t}).*dx(idx.X.v_G_dc{t}));
            gpp_dx(idx.Y.inv_d{t},idx.X.v_G_dc{t}) = ...
                -params.Xi*mydiag( ...
                    dx(idx.X.lambda_G{t}).*x(idx.X.xi_G_c{t}) + ...
                    x(idx.X.lambda_G{t}).*dx(idx.X.xi_G_c{t}));

            gpp_dx(idx.Y.inv_q{t},idx.X.lambda_G{t}) = ...
                - params.Xi*mydiag( ...
                    dx(idx.X.xi_G_s{t}) .* x(idx.X.v_G_dc{t}) + ...
                    x(idx.X.xi_G_s{t}) .* dx(idx.X.v_G_dc{t}));
            gpp_dx(idx.Y.inv_q{t},idx.X.xi_G_s{t}) = ...
                -params.Xi*mydiag( ...
                    dx(idx.X.lambda_G{t}).*x(idx.X.v_G_dc{t}) + ...
                    x(idx.X.lambda_G{t}).*dx(idx.X.v_G_dc{t}));
            gpp_dx(idx.Y.inv_q{t},idx.X.v_G_dc{t}) = ...
                -params.Xi*mydiag( ...
                    dx(idx.X.lambda_G{t}).*x(idx.X.xi_G_s{t}) + ...
                    x(idx.X.lambda_G{t}).*dx(idx.X.xi_G_s{t}));
        end

        % Trigonometric
        names = trig_names(params);
        for i = 1:length(names)
            gpp_dx=trig_pp(params,idx,x,dx,names{i},t,gpp_dx);
        end

        % Discretization (none)

        % Power
        names = power_names(params);
        for i = 1:size(names,1)
            gpp_dx=power_pp(params,idx,x,dx,names{i,1},names{i,2},...
                names{i,3},names{i,4},t,gpp_dx);
        end
        names = power_dq0_names(params);
        for i = 1:size(names,1)
            gpp_dx=power_dq0_pp(params,idx,x,dx,names{i,1},names{i,2},...
                names{i,3},names{i,4},t,gpp_dx);
        end
    end

    % Scale the result by the number of time steps
    gpp_dx = gpp_dx / params.ntime;
end

% Grabs all of the discretization names
function names = disc_names(params)
    names = {};
    if params.nboost > 0
        names = [names; ...
            {'i_A'},{'i_A_dot'},1; ...
            {'e_A'},{'p_A'},-1; ...
            {'lambda_A'},{'lambda_A_dot'},1];
    end
    if params.ndc > 0
        names = [names; ...
            {'v_B'},{'v_B_dot'},1; ...
            {'e_B'},{'p_B'},-1];
    end
    if params.ndcdc > 0
        names = [names; ...
            {'i_C'},{'i_C_dot'},1; ...
            {'lambda_C'},{'lambda_C_dot'},1; ...
            {'e_C'},{'p_C'},-1];
    end
    if params.nacdc > 0
        names = [names; ...
            {'i_E_d'},{'i_E_d_dot'},1; ...
            {'i_E_q'},{'i_E_q_dot'},1; ...
            {'lambda_E'},{'lambda_E_dot'},1];
    end
    if params.nac > 0
        names = [names; ...
            {'v_F_d'},{'v_F_d_dot'},1; ...
            {'v_F_q'},{'v_F_q_dot'},1; ...
            {'e_F'},{'p_F'},-1];
    end
    if params.ninv > 0
        names = [names; ...
            {'i_G_d'},{'i_G_d_dot'},1; ...
            {'i_G_q'},{'i_G_q_dot'},1; ...
            {'v_G_dc'},{'v_G_dc_dot'},1; ...
            {'lambda_G'},{'lambda_G_dot'},1; ...
            {'e_G'},{'p_G'},-1];
    end
end

% Sets a discretization evaluation
function result = disc_eval(params,idx,x,var,var_dot,dir,t,result)
    % Grab the indices
    idx_x = getfield(idx.X,var); idx_x=idx_x{t};
    idx_x_dot = getfield(idx.X,var_dot); idx_x_dot=idx_x_dot{t};
    idx_y = getfield(idx.Y,sprintf('%s_disc',var)); idx_y=idx_y{t};

    % Grab the starting point
    var_0 = getfield(params,sprintf('%s_0',var));

    % Grab the number of x variables
    nvar = length(idx_x);

    % Set evaluation
    if t == 1
        result(idx_y) = x(idx_x) - var_0 - dir * params.Delta_t * x(idx_x_dot);
    else
        idx_x_prior = getfield(idx.X,var); idx_x_prior=idx_x_prior{t-1};
        result(idx_y) = x(idx_x) - x(idx_x_prior) ...
            - dir * params.Delta_t * x(idx_x_dot);
    end
end

% Sets a discretization derivative
function gp = disc_p(params,idx,var,var_dot,dir,t,gp)
    % Grab the indices
    idx_x = getfield(idx.X,var); idx_x=idx_x{t};
    idx_x_dot = getfield(idx.X,var_dot); idx_x_dot=idx_x_dot{t};
    idx_y = getfield(idx.Y,sprintf('%s_disc',var)); idx_y=idx_y{t};

    % Grab the number of x variables
    nvar = length(idx_x);

    % Set the derivatives
    gp(idx_y,idx_x) = speye(nvar);
    gp(idx_y,idx_x_dot) = - dir * params.Delta_t * speye(nvar);
    if t > 1
        idx_x_prior = getfield(idx.X,var); idx_x_prior=idx_x_prior{t-1};
        gp(idx_y,idx_x_prior) = -speye(nvar);
    end
end

% Grabs all of the trigonometric names
function names = trig_names(params)
    names = {};
    if params.nacdc > 0
        names = [names, {'xi_E'}];
    end
    if params.ninv > 0
        names = [names, {'xi_G'}];
    end
end

% Sets a trigonometric evaluation
function result = trig_eval(params,idx,x,var,t,result)
    % Grab the indices
    idx_x_c = getfield(idx.X,sprintf('%s_c',var)); idx_x_c=idx_x_c{t};
    idx_x_s = getfield(idx.X,sprintf('%s_s',var)); idx_x_s=idx_x_s{t};
    idx_y = getfield(idx.Y,var); idx_y=idx_y{t};

    % Grab the number of x variables
    nvar = length(idx_x_c);

    % Set evaluation
    result(idx_y) = x(idx_x_s).^2 + x(idx_x_c).^2 - ones(nvar,1);
end

% Sets a trigonometric derivative
function gp = trig_p(params,idx,x,var,t,gp)
    % Grab the indices
    idx_x_c = getfield(idx.X,sprintf('%s_c',var)); idx_x_c=idx_x_c{t};
    idx_x_s = getfield(idx.X,sprintf('%s_s',var)); idx_x_s=idx_x_s{t};
    idx_y = getfield(idx.Y,var); idx_y=idx_y{t};

    % Grab the number of x variables
    nvar = length(idx_x_c);

    % Set the derivatives
    gp(idx_y,idx_x_s) = 2. * mydiag(x(idx_x_s));
    gp(idx_y,idx_x_c) = 2. * mydiag(x(idx_x_c));
end

% Sets a trigonometric second derivative
function gpp_dx = trig_pp(params,idx,x,dx,var,t,gpp_dx)
    % Grab the indices
    idx_x_c = getfield(idx.X,sprintf('%s_c',var)); idx_x_c=idx_x_c{t};
    idx_x_s = getfield(idx.X,sprintf('%s_s',var)); idx_x_s=idx_x_s{t};
    idx_y = getfield(idx.Y,var); idx_y=idx_y{t};

    % Grab the number of x variables
    nvar = length(idx_x_c);

    % Set the derivatives
    gpp_dx(idx_y,idx_x_s) = 2. * mydiag(dx(idx_x_s));
    gpp_dx(idx_y,idx_x_c) = 2. * mydiag(dx(idx_x_c));
end

% Grabs all of the power names
function names = power_names(params)
    names = {};
    if params.nboost > 0
        names = [names; {'p_A'}, {'u_A'}, {'i_A'}, {'u_A_switch'}];
    end
    if params.ndc > 0
        names = [names; {'p_B'}, {'v_B'}, {'u_B'}, {'u_B_switch'}];
    end
    if params.ndcdc > 0
        names = [names; {'p_C'}, {'u_C'}, {'i_C'}, {'u_C_switch'}];
    end
    if params.ninv > 0
        names = [names; {'p_G'}, {'u_G'}, {'i_G'}, {'u_G_switch'}];
    end
end

% Sets a power evaluation
function result = power_eval(params,idx,x,p,v,i,s,t,result)
    % Grab the indices
    power = getfield(idx.Y,p); power=power{t};
    p = getfield(idx.X,p); p=p{t};
    i = getfield(idx.X,i); i=i{t};
    v = getfield(idx.X,v); v=v{t};
    s = getfield(params,s); s=s{t};

    % Grab the number of x variables
    nvar = length(p);

    % Set evaluation
    result(power) = result(power) + x(p) - x(i) .* x(v) .* s;
end

% Sets a power derivative
function gp = power_p(params,idx,x,p,v,i,s,t,gp)
    % Grab the indices
    power = getfield(idx.Y,p); power=power{t};
    p = getfield(idx.X,p); p=p{t};
    i = getfield(idx.X,i); i=i{t};
    v = getfield(idx.X,v); v=v{t};
    s = getfield(params,s); s=s{t};

    % Grab the number of x variables
    nvar = length(p);

    % Set the derivatives
    gp(power,p) = speye(nvar);
    gp(power,i) = - mydiag(x(v).*s);
    gp(power,v) = - mydiag(x(i).*s);
end

% Sets a power second derivative
function gpp_dx = power_pp(params,idx,x,dx,p,v,i,s,t,gpp_dx)
    % Grab the indices
    power = getfield(idx.Y,p); power=power{t};
    p = getfield(idx.X,p); p=p{t};
    i = getfield(idx.X,i); i=i{t};
    v = getfield(idx.X,v); v=v{t};
    s = getfield(params,s); s=s{t};

    % Grab the number of x variables
    nvar = length(p);

    % Set the derivatives
    gpp_dx(power,i) = - mydiag(dx(v).*s);
    gpp_dx(power,v) = - mydiag(dx(i).*s);
end

% Grabs all of the power names from the dq0 transformation
function names = power_dq0_names(params)
    names = {};
    if params.nac > 0
        names = [names; ...
            {'p_F'}, {'v_F'}, {'u_F'}, {'u_F_switch'}];
    end
end

% Sets a power evaluation for those pieces in the dq0 transformation
function result = power_dq0_eval(params,idx,x,p,v,i,s,t,result)
    % Grab the indices
    power = getfield(idx.Y,p); power=power{t};
    p = getfield(idx.X,p); p=p{t};
    i_d = getfield(idx.X,sprintf('%s_d',i)); i_d=i_d{t};
    i_q = getfield(idx.X,sprintf('%s_q',i)); i_q=i_q{t};
    v_d = getfield(idx.X,sprintf('%s_d',v)); v_d=v_d{t};
    v_q = getfield(idx.X,sprintf('%s_q',v)); v_q=v_q{t};
    s = getfield(params,s); s=s{t};

    % Grab the number of x variables
    nvar = length(p);

    % Set evaluation
    result(power) = x(p) - (x(i_d) .* x(v_d) + x(i_q) .* x(v_q)) .* s;
end

% Sets a power derivative for those pieces in the dq0 transformation
function gp = power_dq0_p(params,idx,x,p,v,i,s,t,gp)
    % Grab the indices
    power = getfield(idx.Y,p); power=power{t};
    p = getfield(idx.X,p); p=p{t};
    i_d = getfield(idx.X,sprintf('%s_d',i)); i_d=i_d{t};
    i_q = getfield(idx.X,sprintf('%s_q',i)); i_q=i_q{t};
    v_d = getfield(idx.X,sprintf('%s_d',v)); v_d=v_d{t};
    v_q = getfield(idx.X,sprintf('%s_q',v)); v_q=v_q{t};
    s = getfield(params,s); s=s{t};

    % Grab the number of x variables
    nvar = length(p);

    % Set the derivatives
    gp(power,p) = speye(nvar);
    gp(power,i_d) = - mydiag(x(v_d).*s);
    gp(power,v_d) = - mydiag(x(i_d).*s);
    gp(power,i_q) = - mydiag(x(v_q).*s);
    gp(power,v_q) = - mydiag(x(i_q).*s);
end

% Sets a power second derivative for those pieces in the dq0 transformation
function gpp_dx = power_dq0_pp(params,idx,x,dx,p,v,i,s,t,gpp_dx)
    % Grab the indices
    power = getfield(idx.Y,p); power=power{t};
    p = getfield(idx.X,p); p=p{t};
    i_d = getfield(idx.X,sprintf('%s_d',i)); i_d=i_d{t};
    i_q = getfield(idx.X,sprintf('%s_q',i)); i_q=i_q{t};
    v_d = getfield(idx.X,sprintf('%s_d',v)); v_d=v_d{t};
    v_q = getfield(idx.X,sprintf('%s_q',v)); v_q=v_q{t};
    s = getfield(params,s); s=s{t};

    % Grab the number of x variables
    nvar = length(p);

    % Set the derivatives
    gpp_dx(power,i_d) = - mydiag(dx(v_d).*s);
    gpp_dx(power,v_d) = - mydiag(dx(i_d).*s);
    gpp_dx(power,i_q) = - mydiag(dx(v_q).*s);
    gpp_dx(power,v_q) = - mydiag(dx(i_q).*s);
end

% Evaluate the Schur preconditioner for the system g'(x)g'(x)*
function ret = eval_schur(params,idx,x,dy)

    % Cache our results
    persistent cache

    % Grab our factorization from the cache if possible
    [fact cache] = getCached(cache,struct('x',x),'fact');

    % If we don't have a factorization, get a new one
    if isempty(fact)
        % Grab the derivative
        gp = eval_gp(params,idx,x);

        % Factorize the system
        fact = struct();
        [fact.L fact.U fact.p fact.q] = lu(gp*gp','vector');

        % Cache the factorization
        cache = storeCached(cache,struct('x',x),struct('fact',fact),2);
    end

    % Solve the linear system
    ret = zeros(idx.Y.size,1);
    ret (fact.q) = fact.U\(fact.L\dy(fact.p));
end
