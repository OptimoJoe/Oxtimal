% Generates the objective function for the microgrid
function f = generateObjective(params,idx)
    f.eval=@(x)eval_f(params,idx,x);
    f.grad=@(x)eval_grad(params,idx,x);
    f.hessvec=@(x,dx)eval_hessvec(params,idx,x,dx);
end

% Evaluate the objective function
function result = eval_f(params,idx,x)
    % Initialize our result
    result = 0.;

    % Do the objective for timestep t
    for t=1:params.ntime
        % Duty cycles
        names = duty_names(params);
        for i = 1:length(names)
            result = duty_eval(params,idx,x,names{i},t,result);
        end

        % Controls
        names = control_names(params);
        for i = 1:size(names,1)
            result = switch_eval(params,idx,x,names{i,1},names{i,2}, ...
                names{i,3},t,result);
        end

        % Parasitic losses
        names = parasitic_names(params);
        for i = 1:size(names,1)
            result = parasitic_eval(params,idx,x,names{i,1},names{i,2}, ...
                names{i,3},t,result);
        end

        % Power
        names = power_names(params);
        for i = 1:size(names,1)
            result = switch_eval(params,idx,x,names{i,1},names{i,2}, ...
                names{i,3},t,result);
        end
    end

    % Scale the result by the number of time steps
    result = result / params.ntime;
end

% Find the gradient of the objective function
function result = eval_grad(params,idx,x)
    % Initialize our result
    result = zeros(length(x),1);

    % Do the gradient for timestep t
    for t=1:params.ntime
        % Duty cycles
        names = duty_names(params);
        for i = 1:length(names)
            result = duty_grad(params,idx,x,names{i},t,result);
        end

        % Controls
        names = control_names(params);
        for i = 1:size(names,1)
            result = switch_grad(params,idx,x,names{i,1},names{i,2}, ...
                names{i,3},t,result);
        end

        % Parasitic losses
        names = parasitic_names(params);
        for i = 1:size(names,1)
            result = parasitic_grad(params,idx,x,names{i,1},names{i,2}, ...
                names{i,3},t,result);
        end

        % Power
        names = power_names(params);
        for i = 1:size(names,1)
            result = switch_grad(params,idx,x,names{i,1},names{i,2}, ...
                names{i,3},t,result);
        end
    end

    % Scale the result by the number of time steps
    result = result / params.ntime;
end

% Find the Hessian-vector product of the objective function
function result = eval_hessvec(params,idx,x,dx)
    % Initialize our result
    result = zeros(length(x),1);

    % Do the hess-vec for timestep t
    for t=1:params.ntime
        % Duty cycles
        names = duty_names(params);
        for i = 1:length(names)
            result = duty_hessvec(params,idx,x,dx,names{i},t,result);
        end

        % Controls
        names = control_names(params);
        for i = 1:size(names,1)
            result = switch_hessvec(params,idx,x,dx,names{i,1},names{i,2}, ...
                names{i,3},t,result);
        end

        % Parasitic losses
        names = parasitic_names(params);
        for i = 1:size(names,1)
            result = parasitic_hessvec(params,idx,x,dx,names{i,1},names{i,2},...
                names{i,3},t,result);
        end

        % Power
        names = power_names(params);
        for i = 1:size(names,1)
            result = switch_hessvec(params,idx,x,dx,names{i,1},names{i,2}, ...
                names{i,3},t,result);
        end
    end

    % Scale the result by the number of time steps
    result = result / params.ntime;
end

% Grabs all duty cycles
function names = duty_names(params)
    names = {};
    if params.nboost > 0
        names = [names {'A'}];
    end
    if params.ndcdc > 0
        names = [names {'C'}];
    end
    if params.nacdc > 0
        names = [names {'E'}];
    end
    if params.ninv > 0
        names = [names {'G'}];
    end
end

% Evaluation of the duty cycles
function result = duty_eval(params,idx,x,var,t,result)
    % Grab the indices and weight
    w = getfield(params,sprintf('w_%s_duty',var)); w=w{t};
    var = getfield(idx.X,sprintf('lambda_%s_dot',var)); var=var{t};

    % Evaluate
    result = result + 0.5 * norm(w.*x(var))^2;
end

% Evaluation of the duty cycle gradients
function result = duty_grad(params,idx,x,var,t,result)
    % Grab the indices and weight
    w = getfield(params,sprintf('w_%s_duty',var)); w=w{t};
    var = getfield(idx.X,sprintf('lambda_%s_dot',var)); var=var{t};

    % Evaluate
    result(var) = result(var) + w .* x(var);
end

% Evaluation of the duty cycle Hessian-vector product
function result = duty_hessvec(params,idx,x,dx,var,t,result)
    % Grab the indices and weight
    w = getfield(params,sprintf('w_%s_duty',var)); w=w{t};
    var = getfield(idx.X,sprintf('lambda_%s_dot',var)); var=var{t};

    % Evaluate
    result(var) = result(var) + w .* dx(var);
end

% Grabs all the controls
function names = control_names(params)
    names = {};
    if params.nboost > 0
        names = [names; {'u_A'}, {'u_A_switch'}, {'w_A_control'}];
    end
    if params.ndc > 0
        names = [names; {'u_B'}, {'u_B_switch'}, {'w_B_control'}];
    end
    if params.ndcdc > 0
        names = [names; {'u_C'}, {'u_C_switch'}, {'w_C_control'}];
    end
    if params.nac > 0
        names = [names; ...
            {'u_F_d'}, {'u_F_switch'}, {'w_F_control'}; ...
            {'u_F_q'}, {'u_F_switch'}, {'w_F_control'}];
    end
    if params.ninv > 0
        names = [names; {'u_G'}, {'u_G_switch'}, {'w_G_control'}];
    end
end

% Grabs all the power
function names = power_names(params)
    names = {};
    if params.nboost > 0
        names = [names; {'p_A'}, {'u_A_switch'}, {'w_A_power'}];
    end
    if params.ndc > 0
        names = [names; {'p_B'}, {'u_B_switch'}, {'w_B_power'}];
    end
    if params.ndcdc > 0
        names = [names; {'p_C'}, {'u_C_switch'}, {'w_C_power'}];
    end
    if params.nac > 0
        names = [names; {'p_F'}, {'u_F_switch'}, {'w_F_power'}];
    end
    if params.ninv > 0
        names = [names; {'p_G'}, {'u_G_switch'}, {'w_G_power'}];
    end
end

% Evaluation of a switched objective
function result = switch_eval(params,idx,x,var,s,w,t,result)
    % Grab the indices
    var = getfield(idx.X,var); var=var{t};
    s = getfield(params,s); s=s{t};
    w = getfield(params,w); w=w{t};

    % Evaluate
    result = result + 0.5 * norm(x(var).*s.*w)^2;
end

% Evaluation of the switched gradient
function result = switch_grad(params,idx,x,var,s,w,t,result)
    % Grab the indices
    var = getfield(idx.X,var); var=var{t};
    s = getfield(params,s); s=s{t};
    w = getfield(params,w); w=w{t};

    % Evaluate
    result(var) = result(var) + x(var).*s.*w;
end

% Evaluation of the switched Hessian-vector product
function result = switch_hessvec(params,idx,x,dx,var,s,w,t,result)
    % Grab the indices
    var = getfield(idx.X,var); var=var{t};
    s = getfield(params,s); s=s{t};
    w = getfield(params,w); w=w{t};

    % Evaluate
    result(var) = result(var) + dx(var).*s.*w;
end

% Grabs all the parasitic loss names
function names = parasitic_names(params)
    names = {};
    if params.nboost > 0
        names = [names; {'i_A'}, {'R_A'}, {'w_A_loss'}];
    end
    if params.ndcdc > 0
        names = [names; {'i_C'}, {'R_C'}, {'w_C_loss'}];
    end
    if params.nacdc > 0
        names = [names; ...
            {'i_E_d'}, {'R_E'}, {'w_E_loss'}; ...
            {'i_E_q'}, {'R_E'}, {'w_E_loss'}];
    end
    if params.ninv > 0
        names = [names; ...
            {'i_G_d'}, {'R_G'}, {'w_G_loss'}; ...
            {'i_G_q'}, {'R_G'}, {'w_G_loss'}];
    end
end

% Evaluation of a parasitic loss objective
function result = parasitic_eval(params,idx,x,var,R,w,t,result)
    % Grab the indices
    var = getfield(idx.X,var); var=var{t};
    R = getfield(params,R); R=R{t};
    w = getfield(params,w); w=w{t};

    % Evaluate
    result = result + 0.5 * (R.*w.*x(var))'*x(var);
end

% Evaluation of a parasitic loss gradient
function result = parasitic_grad(params,idx,x,var,R,w,t,result)
    % Grab the indices
    var = getfield(idx.X,var); var=var{t};
    R = getfield(params,R); R=R{t};
    w = getfield(params,w); w=w{t};

    % Evaluate
    result(var) = result(var) + R.*w.*x(var);
end

% Evaluation of a parasitic loss Hessian-vector product
function result = parasitic_hessvec(params,idx,x,dx,var,R,w,t,result)
    % Grab the indices
    var = getfield(idx.X,var); var=var{t};
    R = getfield(params,R); R=R{t};
    w = getfield(params,w); w=w{t};

    % Evaluate
    result(var) = result(var) + R.*w.*dx(var);
end
