% Generate the indexing functions for the microgrid

function idx = generateIndexing(params)
    % Different indices
    X = struct();
    Y = struct();
    Z = struct();

    % Boost converter
    if params.nboost > 0
        names = {
            'u_A', ...
            'i_A', ...
            'i_A_dot', ...
            'lambda_A', ...
            'lambda_A_dot', ...
            'p_A', ...
            'e_A'};
        X = cellfold(@(arr,name)setfield(arr,name,params.nboost),X,names);
    end

    % DC bus
    if params.ndc > 0
        names = { ...
            'v_B', ...
            'v_B_dot', ...
            'u_B', ...
            'p_B', ...
            'e_B'};
        X = cellfold(@(arr,name)setfield(arr,name,params.ndc),X,names);
    end

    % Connection between the bus and transmission line
    if params.ndcdc > 0
        names = { ...
            'u_C', ...
            'lambda_C', ...
            'lambda_C_dot', ...
            'i_C', ...
            'i_C_dot', ...
            'p_C', ...
            'e_C'};
        X = cellfold(@(arr,name)setfield(arr,name,params.ndcdc),X,names);
    end
    if params.nacdc > 0
        names = { ...
            'i_E_d', ...
            'i_E_q', ...
            'i_E_d_dot', ...
            'i_E_q_dot', ...
            'lambda_E', ...
            'lambda_E_dot', ...
            'xi_E_s', ...
            'xi_E_c'};
        X = cellfold(@(arr,name)setfield(arr,name,params.nacdc),X,names);
    end
    if params.nac > 0
        names = { ...
            'v_F_d', ...
            'v_F_q', ...
            'v_F_d_dot', ...
            'v_F_q_dot', ...
            'u_F_d', ...
            'u_F_q', ...
            'p_F', ...
            'e_F'};
        X = cellfold(@(arr,name)setfield(arr,name,params.nac),X,names);
    end
    if params.ninv > 0
        names = { ...
            'u_G', ...
            'v_G_dc', ...
            'v_G_dc_dot', ...
            'i_G', ...
            'i_G_d', ...
            'i_G_q', ...
            'i_G_d_dot', ...
            'i_G_q_dot', ...
            'lambda_G', ...
            'lambda_G_dot', ...
            'xi_G_s', ...
            'xi_G_c', ...
            'p_G', ...
            'e_G'};
        X = cellfold(@(arr,name)setfield(arr,name,params.ninv),X,names);
    end

    % Boost converters
    if params.nboost > 0
        names = {'boost','i_A_disc','e_A_disc','p_A'};
        if params.ndc > 0
            names = [names 'lambda_A_disc'];
        end
        Y = cellfold(@(arr,name)setfield(arr,name,params.nboost),Y,names);
    end

    % DC bus
    if params.ndc > 0
        names = {'dc','v_B_disc','e_B_disc','p_B'};
        Y = cellfold(@(arr,name)setfield(arr,name,params.ndc),Y,names);
    end

    % DC to DC connector
    if params.ndcdc > 0
        names = {'dcdc','i_C_disc','lambda_C_disc','e_C_disc','p_C'};
        Y = cellfold(@(arr,name)setfield(arr,name,params.ndcdc),Y,names);
    end

    % AC to DC connector
    if params.nacdc > 0
        names = {'acdc_d','acdc_q','i_E_d_disc','i_E_q_disc', ...
            'lambda_E_disc','xi_E'};
        Y = cellfold(@(arr,name)setfield(arr,name,params.nacdc),Y,names);
    end

    % AC buses
    if params.nac > 0
        names = {'ac_d','ac_q','v_F_d_disc','v_F_q_disc','e_F_disc','p_F'};
        Y = cellfold(@(arr,name)setfield(arr,name,params.nac),Y,names);
    end

    % Inverters
    if params.ninv > 0
        names = {'inv_gen','inv_dc','inv_d','inv_q','i_G_d_disc', ...
            'i_G_q_disc','v_G_dc_disc','lambda_G_disc','e_G_disc','p_G','xi_G'};
        Y = cellfold(@(arr,name)setfield(arr,name,params.ninv),Y,names);
    end

    % Boost converters
    if params.nboost > 0
        names = {'i_A_lb','i_A_ub','u_A_lb','u_A_ub','e_A_lb','e_A_ub'};
        if params.ndc > 0
            names = [names 'lambda_A_lb' 'lambda_A_ub'];
        end
        Z = cellfold(@(arr,name)setfield(arr,name,params.nboost),Z,names);
    end

    % DC bus
    if params.ndc > 0
        names = {'u_B_lb','u_B_ub','v_B_lb','v_B_ub','e_B_lb','e_B_ub'};
        Z = cellfold(@(arr,name)setfield(arr,name,params.ndc),Z,names);
    end

    % DC to DC connector
    if params.ndcdc > 0
        names = {'i_C_lb','i_C_ub','u_C_lb','u_C_ub','lambda_C_lb', ...
            'lambda_C_ub','e_C_lb','e_C_ub'};
        Z = cellfold(@(arr,name)setfield(arr,name,params.ndcdc),Z,names);
    end

    % AC to DC connector
    if params.nacdc > 0
        names = {'i_E_d_lb','i_E_d_ub','i_E_q_lb','i_E_q_ub','lambda_E_lb', ...
            'lambda_E_ub'};
        Z = cellfold(@(arr,name)setfield(arr,name,params.nacdc),Z,names);
    end

    % AC buses
    if params.nac > 0
        names = {'v_F_d_lb','v_F_d_ub','v_F_q_lb','v_F_q_ub', ...
            'u_F_d_lb','u_F_d_ub','u_F_q_lb','u_F_q_ub', ...
            'e_F_lb','e_F_ub'};
        Z = cellfold(@(arr,name)setfield(arr,name,params.nac),Z,names);
    end

    % Inverters
    if params.ninv > 0
        names = {'v_G_dc_lb','v_G_dc_ub','i_G_d_lb','i_G_d_ub', ...
            'i_G_q_lb','i_G_q_ub','u_G_lb','u_G_ub', ...
            'lambda_G_lb','lambda_G_ub','e_G_lb','e_G_ub'};
        Z = cellfold(@(arr,name)setfield(arr,name,params.ninv),Z,names);
    end

    % Create the indexing functions
    X = createIndexing(X,params.ntime);
    Y = createIndexing(Y,params.ntime);
    Z = createIndexing(Z,params.ntime);

    % Collocate all of the indexing functions
    idx.X = X;
    idx.Y = Y;
    idx.Z = Z;
end

% Folds a function across cell data
function x = cellfold(f,x,y)
    for i=1:length(y)
        x = f(x,y{i});
    end
end
