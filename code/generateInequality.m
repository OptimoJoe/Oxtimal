% Generates the inequality constraint for the microgrid
function h = generateInequality(params,idx)
    % Grab our core inequality functions
    h.eval=@(x)eval_h(params,idx,x);
    h.p=@(x,dx)eval_hp(params,idx,x)*dx;
    h.ps=@(x,z)eval_hp(params,idx,x)'*z;
    h.pps=@(x,dx,z)zeros(size(x));
end

% Creates a sparse diagonal matrix from a vector
function A=mydiag(x)
    A=spdiags(x,0,length(x),length(x));
end

% Find the inequality constraint
function result = eval_h(params,idx,x)
    % Initialize our result
    result = zeros(idx.Z.size,1);

    % Do the equations for timestep t
    for t=1:params.ntime
        % Bounds
        names = bound_names(params);
        for i = 1:length(names)
            result = bound_eval(params,idx,x,names{i},t,result);
        end

        % Bounds with switches
        names = switch_names(params);
        for i = 1:size(names,1);
            result = switch_eval(params,idx,x,names{i,1},names{i,2},t,result);
        end
    end

    % Scale the result by the number of time steps
    result = (result / params.ntime) * params.ineq_scaling;
end

% Find the total derivative of h
function hp = eval_hp(params,idx,x)

    % Cache our results
    persistent cache

    % Grab our result from cache if possible
    [hp cache] = getCached(cache,struct('x',x),'hp');
    if ~isempty(hp)
        return;
    end

    % Initialize everything to zero
    hp=sparse(idx.Z.size,idx.X.size);

    % Do the equations for timestep t
    for t=1:params.ntime
        % Bounds
        names = bound_names(params);
        for i = 1:length(names)
            hp = bound_p(params,idx,names{i},t,hp);
        end

        % Bounds with switches
        names = switch_names(params);
        for i = 1:size(names,1);
            hp = switch_p(params,idx,names{i,1},names{i,2},t,hp);
        end
    end

    % Scale the result by the number of time steps
    hp = (hp / params.ntime) * params.ineq_scaling;

    % Cache the result
    cache = storeCached(cache,struct('x',x),struct('hp',hp),1);
end

% Grabs all of the bound names
function names = bound_names(params)
    names = {};
    if params.nboost > 0
        names = [names, {'i_A'}, {'lambda_A'}];
    end
    if params.ndc > 0
        names = [names, {'v_B'}];
    end
    if params.ndcdc > 0
        names = [names, {'i_C'}, {'lambda_C'}];
    end
    if params.nacdc > 0
        names = [names, {'i_E_d'}, {'i_E_q'}, {'lambda_E'}];
    end
    if params.nac > 0
        names = [names, {'v_F_d'}, {'v_F_q'}];
    end
    if params.ninv > 0
        names = [names, {'v_G_dc'}, {'i_G_d'}, {'i_G_q'}, {'lambda_G'}];
    end
end

% Sets a bound evaluation
function result = bound_eval(params,idx,x,var,t,result)
    % Grab the indices
    lb = getfield(params,sprintf('%s_min',var)); lb=lb{t};
    ub = getfield(params,sprintf('%s_max',var)); ub=ub{t};
    bound_l = getfield(idx.Z,sprintf('%s_lb',var)); bound_l=bound_l{t};
    bound_u = getfield(idx.Z,sprintf('%s_ub',var)); bound_u=bound_u{t};
    var = getfield(idx.X,var); var=var{t};

    % Set evaluation
    result(bound_l) = x(var) - lb;
    result(bound_u) = ub - x(var);
end

% Sets a bound derivative
function hp = bound_p(params,idx,var,t,hp)
    % Grab the indices
    lb = getfield(params,sprintf('%s_min',var)); lb=lb{t};
    bound_l = getfield(idx.Z,sprintf('%s_lb',var)); bound_l=bound_l{t};
    bound_u = getfield(idx.Z,sprintf('%s_ub',var)); bound_u=bound_u{t};
    var = getfield(idx.X,var); var=var{t};

    % Grab the number of x variables
    nvar = length(lb);

    % Set evaluation
    hp(bound_l,var) = speye(nvar);
    hp(bound_u,var) = -speye(nvar);
end

% Grabs all of the bound names that have switches
function names = switch_names(params)
    names = {};
    if params.nboost > 0
        names = [names; {'u_A'}, {'u_A_switch'}; {'e_A'}, {'u_A_switch'}];
    end
    if params.ndc > 0
        names = [names; {'u_B'}, {'u_B_switch'}; {'e_B'}, {'u_B_switch'}];
    end
    if params.ndcdc > 0
        names = [names; {'u_C'}, {'u_C_switch'}; {'e_C'}, {'u_C_switch'}];
    end
    if params.nac > 0
        names = [names; ...
            {'u_F_d'}, {'u_F_switch'}; {'u_F_q'}, {'u_F_switch'}; ...
            {'e_F'}, {'u_F_switch'}];
    end
    if params.ninv > 0
        names = [names; {'u_G'}, {'u_G_switch'}; {'e_G'}, {'u_G_switch'}];
    end
end

% Sets a switch evaluation
function result = switch_eval(params,idx,x,var,s,t,result)
    % Grab the indices
    lb = getfield(params,sprintf('%s_min',var)); lb=lb{t};
    ub = getfield(params,sprintf('%s_max',var)); ub=ub{t};
    s = getfield(params,s); s=s{t};
    bound_u = getfield(idx.Z,sprintf('%s_ub',var)); bound_u=bound_u{t};
    bound_l = getfield(idx.Z,sprintf('%s_lb',var)); bound_l=bound_l{t};
    var = getfield(idx.X,var); var=var{t};

    % Grab a safe point
    safe = (ub - lb)/2;
    safe = 1e4;

    % Set evaluation
    result(bound_l) = (x(var) - lb).*s + safe .* not(s);
    result(bound_u) = (ub - x(var)).*s + safe .* not(s);
end

% Sets a switch derivative
function hp = switch_p(params,idx,var,s,t,hp)
    % Grab the indices
    s = getfield(params,s); s=s{t};
    bound_u = getfield(idx.Z,sprintf('%s_ub',var)); bound_u=bound_u{t};
    bound_l = getfield(idx.Z,sprintf('%s_lb',var)); bound_l=bound_l{t};
    var = getfield(idx.X,var); var=var{t};

    % Set evaluation
    hp(bound_l,var) = mydiag(s);
    hp(bound_u,var) = -mydiag(s);
end
