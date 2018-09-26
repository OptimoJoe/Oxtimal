% Adds any missing parameters and checks everything for errors
function params=generateFull(params)
    % Process out any textual arguments that we used for placeholders.  We do
    % this to mark sources that we may turn off, but we need the elements in
    % the setup to make sure the sizes line up.
    names = {'u_A_min','e_A_min', ...
             'u_B_min','e_B_min', ...
             'u_C_min','e_C_min', ...
             'u_F_d_min','e_F_d_min', ...
             'u_F_q_min','e_F_q_min', ...
             'u_G_min','e_G_min'};
    params = remove_text(params,names,0);
    names = {'u_A_max','e_A_max', ...
             'u_B_max','e_B_max', ...
             'u_C_max','e_C_max', ...
             'u_F_d_max','u_F_q_max','e_F_max', ...
             'u_G_max','e_G_max'};
    params = remove_text(params,names,1);
    names = {'e_A_0', ...
             'e_B_0', ...
             'e_C_0', ...
             'e_F_0', ...
             'e_G_0'};
    params = remove_text(params,names,0.5);

    % List of all dimensions
    dim = {
        'nboost', ...
        'ndc', ...
        'ndcdc', ...
        'nacdc', ...
        'nac', ...
        'ninv'};

    % Set default values for the dimensions if they don't exist
    params = cellfold(@(params,name)setdefault(params,name,0),params,dim);

    % Check that each of the values is nonnegative
    cellfun(@(name)checkNonnegative(name,getfield(params,name)),dim);

    % Check that certain sizes make sense
    if params.nboost > 0 && params.ndc==0
        error('When nboost > 0, ndc must be > 0');
    end
    if params.ndcdc > 0 && params.ndc==0
        error('When ndcdc > 0, ndc must be > 0');
    end
    if params.nacdc > 0 && (params.ndc==0 || params.nac==0)
        error('When nacdc > 0, ndc and nac must be > 0');
    end
    if params.ninv > 0 && params.nac==0
        error('When ninv > 0, nac must be > 0');
    end

    % List all of the parameters that we require
    names = {};

    % Generic
    names = [names, ...
        'ntime', ...
        'Delta_t'];

    % Topology
    if params.ndc > 0
        if params.nboost > 0
            names = [names 'Phi_boost_dc_1'];
        end
        if params.ndcdc > 0
            names = [names 'Phi_dcdc_dc_2', 'Phi_dcdc_dc_3'];
        end
        if params.nacdc > 0 && params.nac > 0
            names = [names, 'Phi_acdc_dc_5', 'Phi_acdc_ac_6'];
        end
    end
    if params.nac > 0
        if params.ninv > 0
            names = [names, 'Phi_inv_ac_7'];
        end
    end

    % Boost converters
    if params.ndc > 0
        boost.generic.transient = { ...
            'w_A_duty', ...
            'w_A_control', ...
            'w_A_loss', ...
            'w_A_power', ...
            'v_A', ...
            'u_A_switch', ...
            'L_A', ...
            'R_A', ...
            'P_A', ...
            'i_A_min','i_A_max', ...
            'u_A_min','u_A_max', ...
            'lambda_A_min','lambda_A_max', ...
            'e_A_min','e_A_max'};
        boost.generic.initial = { ...
            'i_A_0', ...
            'lambda_A_0', ...
            'e_A_0'};
        names = [names boost.generic.transient boost.generic.initial];
    end

    % DC buses
    if params.ndc > 0
        dc.generic.transient = { ...
            'w_B_control', ...
            'w_B_power', ...
            'R_B', ...
            'P_B', ...
            'C_B', ...
            'u_B_switch', ...
            'v_B_min','v_B_max', ...
            'u_B_min','u_B_max', ...
            'e_B_min','e_B_max'};
        dc.generic.initial = { ...
            'v_B_0', ...
            'e_B_0'};
        names = [names dc.generic.transient dc.generic.initial];
    end

    % DC to DC connectors
    if params.ndcdc > 0
        dcdc.generic.transient = { ...
            'w_C_duty', ...
            'w_C_control', ...
            'w_C_loss', ...
            'w_C_power', ...
            'u_C_switch', ...
            'L_C', ...
            'R_C', ...
            'i_C_min','i_C_max', ...
            'u_C_min','u_C_max', ...
            'lambda_C_min','lambda_C_max', ...
            'e_C_min','e_C_max'};
        dcdc.generic.initial = { ...
            'i_C_0', ...
            'lambda_C_0', ...
            'e_C_0'};
        names = [names dcdc.generic.transient dcdc.generic.transient];
    end

    % AC to DC connectors
    if params.nacdc > 0
        acdc.generic.transient = { ...
            'w_E_duty', ...
            'w_E_loss', ...
            'L_E', ...
            'R_E', ...
            'i_E_d_min','i_E_d_max', ...
            'i_E_q_min','i_E_q_max', ...
            'lambda_E_min','lambda_E_max'};
        acdc.generic.initial = { ...
            'i_E_d_0', ...
            'i_E_q_0', ...
            'lambda_E_0'};
        names = [names acdc.generic.transient acdc.generic.transient];
    end

    % AC buses
    if params.nac > 0
        ac.generic.transient = { ...
            'w_F_control', ...
            'w_F_power', ...
            'omega_F', ...
            'R_F', ...
            'P_F_d', ...
            'P_F_q', ...
            'C_F', ...
            'u_F_switch', ...
            'v_F_d_min','v_F_d_max', ...
            'v_F_q_min','v_F_q_max', ...
            'u_F_d_min','u_F_d_max', ...
            'u_F_q_min','u_F_q_max', ...
            'e_F_min','e_F_max'};
        ac.generic.initial = {
            'v_F_d_0', ...
            'v_F_q_0', ...
            'e_F_0'};
        names = [names ac.generic.transient ac.generic.initial];
    end

    % Inverters
    if params.ninv > 0
        inv.generic.transient = {
            'w_G_duty', ...
            'w_G_control', ...
            'w_G_loss', ...
            'w_G_power', ...
            'u_G_switch', ...
            'v_G', ...
            'C_G_dc', ...
            'R_G_dc', ...
            'L_G', ...
            'R_G', ...
            'v_G_dc_min','v_G_dc_max', ...
            'i_G_d_min','i_G_d_max', ...
            'i_G_q_min','i_G_q_max', ...
            'u_G_min','u_G_max', ...
            'lambda_G_min','lambda_G_max', ...
            'e_G_min','e_G_max'};
        inv.generic.initial = {
            'i_G_d_0', ...
            'i_G_q_0', ...
            'v_G_dc_0', ...
            'lambda_G_0', ...
            'e_G_0'};
        names = [names inv.generic.transient inv.generic.initial];
    end

    % Check that all of these names exist
    checkName_ = @(name)checkName(params,name);
    cellfun(checkName_,names);

    % Check our generic parameters
    checkGeneric = @(name,dim1,dim2) ...
        checkSize(name,getfield(params,name),dim1,dim2);
    checkGeneric('ntime',1,1);
    checkGeneric('Delta_t',1,1);

    % Check our expansion operators
    checkExpansion = @(name,dim1,dim2) checkOperator( ...
        name,getfield(params,name),getfield(params,dim1),getfield(params,dim2));
    if params.nboost > 0
        checkExpansion('Phi_boost_dc_1','nboost','ndc');
    end
    if params.ndcdc > 0
        checkExpansion('Phi_dcdc_dc_2','ndcdc','ndc');
        checkExpansion('Phi_dcdc_dc_3','ndcdc','ndc');
    end
    if params.nacdc > 0
        checkExpansion('Phi_acdc_dc_5','nacdc','ndc');
        checkExpansion('Phi_acdc_ac_6','nacdc','nac');
    end
    if params.ninv > 0
        checkExpansion('Phi_inv_ac_7','ninv','nac');
    end

    % Boost converters
    if params.nboost > 0
        % Fix and check functions
        fix = @(params,name)checkAndExpand(params,name,params.nboost);
        check = @(name) checkInitial( ...
            name, ...
            getfield(params,name), ...
            params.nboost, ...
            getfield(params,sprintf('%s_min',name(1:end-2))), ...
            getfield(params,sprintf('%s_max',name(1:end-2))));

        % Check and fix the parameters
        params = cellfold(fix,params,boost.generic.transient);
        cellfun(check,boost.generic.initial);
    end

    % DC buses
    if params.ndc>0
        % Fix and check functions
        fix = @(params,name)checkAndExpand(params,name,params.ndc);
        check = @(name) checkInitial( ...
            name, ...
            getfield(params,name), ...
            params.ndc, ...
            getfield(params,sprintf('%s_min',name(1:end-2))), ...
            getfield(params,sprintf('%s_max',name(1:end-2))));

        % Check and fix the parameters
        params = cellfold(fix,params,dc.generic.transient);
        cellfun(check,dc.generic.initial);
    end

    % DC to DC connections
    if params.ndcdc > 0
        % Fix and check functions
        fix = @(params,name)checkAndExpand(params,name,params.ndcdc);
        check = @(name) checkInitial( ...
            name, ...
            getfield(params,name), ...
            params.ndcdc, ...
            getfield(params,sprintf('%s_min',name(1:end-2))), ...
            getfield(params,sprintf('%s_max',name(1:end-2))));

        % Check and fix the parameters
        params = cellfold(fix,params,dcdc.generic.transient);
        cellfun(check,dcdc.generic.initial);
    end

    % AC to DC connections
    if params.nacdc > 0
        % Fix and check functions
        fix = @(params,name)checkAndExpand(params,name,params.nacdc);
        check = @(name) checkInitial( ...
            name, ...
            getfield(params,name), ...
            params.nacdc, ...
            getfield(params,sprintf('%s_min',name(1:end-2))), ...
            getfield(params,sprintf('%s_max',name(1:end-2))));

        % Check and fix the parameters
        params = cellfold(fix,params,acdc.generic.transient);
        cellfun(check,acdc.generic.initial);
    end

    % AC buses
    if params.nac>0
        % Fix and check functions
        fix = @(params,name)checkAndExpand(params,name,params.nac);
        check = @(name) checkInitial( ...
            name, ...
            getfield(params,name), ...
            params.nac, ...
            getfield(params,sprintf('%s_min',name(1:end-2))), ...
            getfield(params,sprintf('%s_max',name(1:end-2))));

        % Check and fix the parameters
        params = cellfold(fix,params,ac.generic.transient);
        cellfun(check,ac.generic.initial);
    end

    % Inverters
    if params.ninv>0
        % Fix and check functions
        fix = @(params,name)checkAndExpand(params,name,params.ninv);
        check = @(name) checkInitial( ...
            name, ...
            getfield(params,name), ...
            params.ninv, ...
            getfield(params,sprintf('%s_min',name(1:end-2))), ...
            getfield(params,sprintf('%s_max',name(1:end-2))));

        % Check and fix the parameters
        params = cellfold(fix,params,inv.generic.transient);
        cellfun(check,inv.generic.initial);
    end

    % Add any remaining constants
    params.Xi = (1./2.) * sqrt(3./2.);

    % Fixes any parameters that correspond to control variables that we've
    % turned off
    names = switch_names(params);
    for t=1:params.ntime
        for i=1:size(names,1)
            params = switch_off(params,names{i,1},names{i,2},t);
        end
    end

    % Adds in the inequality scaling if it's not specified
    if ~isfield(params,'ineq_scaling')
        params.ineq_scaling = 1.;
    end
end

% Processes out textual elements from the parameters
function params = remove_text(params,names,value)
    % Loop over all of the potential names
    for i=1:length(names)
        if isfield(params,names{i})
            % Grab the parameter
            param = getfield(params,names{i});

            % If the parameter is a cell, we have text somewhere
            if iscell(param)
                for j=1:size(param,2)
                    % If the individual cell element is also a cell, we
                    % definately have text
                    if iscell(param{j})
                        % Set all of the cell elements to the specified value
                        for k=1:size(param{j},2)
                            param{j}{k}=value;
                        end

                        % Turn the cell array into a matrix
                        param{j}=cell2mat(param{j});

                    % Alternatively, if we have a string, we have text
                    elseif ischar(param{j})
                        param{j}=value;
                    end
                end

                % Turn this parameter back into a matrix
                param = reshape(cell2mat(param),size(param,2),size(param{1},2));
                params = setfield(params,names{i},param);

            % Alternatively, we could have a single string
            elseif ischar(param)
                params = setfield(params,names{i},value);
            end
        end
    end
end

% Folds a function across cell data
function x = cellfold(f,x,y)
    for i=1:length(y)
        x = f(x,y{i});
    end
end

% Checks that the values are nonnegative
function checkNonnegative(name,value)
    if value < 0
        error(sprintf('Parameter %s must be nonnegative',name));
    end
end

% Sets a default value in a structure array if it doesn't already exist
function arr = setdefault(arr,name,value)
    if ~isfield(arr,name)
        arr = setfield(arr,name,value);
    end
end

% Checks if a parameter exists.  If it doesn't, throw an error.
function checkName(params,name)
    if ~isfield(params,name)
        error(sprintf('Parameters must include parameter: %s',name));
    end
end

% Check the size of different parameters
function checkSize(name,param,dim1,dim2)
    % Make sure that we actually have dimensions
    if  dim1 == 0 || dim2 == 0
        return;
    end

    % Check that we have the right size
    if  ~isequal(size(param),[dim1 dim2])
        error(sprintf('Parameter %s must have size %d x %d',name,dim1,dim2));
    end
end

% Checks that an expansion operator has the right size and elements
function checkOperator(name,param,dim1,dim2)
    % Check that we have the right size
    checkSize(name,param,dim1,dim2);

    % Loop over all the rows and make sure that we have at most one element
    % per row
    for i = 1:dim1
        if ~sum(param(i,:)) == 1
            error(sprintf( ...
                'Expansion operator %s requires exactly one element per row'))
        end
    end
end

% Verifies the sizes and expands upon them if necessary so that we have a
% parameter valid for all our time steps
function params = checkAndExpand(params,name,dim)
    % Grab the parameter and the time
    param = getfield(params,name);
    ntime = getfield(params,'ntime');

    % Check the size
    if  ~isequal(size(param),[dim 1]) && ...
        ~isequal(size(param),[dim ntime])
        error(sprintf('Parameter %s must have size %d x 1 or %d x %d', ...
            name,dim,dim,ntime));
    end

    % Expand if necessary
    if size(param,2)==1
        param=repmat(param,1,ntime);
    end

    % Divide into cells
    param = mat2cell(param,dim,ones(1,ntime));

    % Set the parameter
    params = setfield(params,name,param);
end

% Check that a value lies between two bounds
function checkBetween(name,val,lower,upper)
    b = (val >= upper(:,1)) + (val <= lower(:,1));
    if ~isequal(sum(b),0)
        error(['Parameter %s must lie strictly between the bounds %s_min ' ...
            'and %s_max'],name,name,name);
    end
end

% Checks our initial conditions
function checkInitial(name,val,dim,lower,upper)
    checkSize(name,val,dim,1);
    checkBetween(name,val,lower,upper);
end

% Grabs the names of the parameters that we turn off due to switching
function names = switch_names(params)
    % Keep track of the names that we're modifying
    names = {};

    % Boost
    if params.nboost > 0
        names = [names; ...
            {'u_A_min'},{'u_A_switch'}; ...
            {'u_A_max'},{'u_A_switch'}; ...
            {'e_A_min'},{'u_A_switch'}; ...
            {'e_A_max'},{'u_A_switch'}; ...
            {'e_A_0'},{'u_A_switch'}];
    end

    % DC buses
    if(params.ndc > 0)
        names = [names; ...
            {'u_B_min'},{'u_B_switch'}; ...
            {'u_B_max'},{'u_B_switch'}; ...
            {'e_B_min'},{'u_B_switch'}; ...
            {'e_B_max'},{'u_B_switch'}; ...
            {'e_B_0'},{'u_B_switch'}];
    end

    % Connections between DC buses
    if(params.ndcdc > 0)
        names = [names; ...
            {'u_C_min'},{'u_C_switch'}; ...
            {'u_C_max'},{'u_C_switch'}; ...
            {'e_C_min'},{'u_C_switch'}; ...
            {'e_C_max'},{'u_C_switch'}; ...
            {'e_C_0'},{'u_C_switch'}];
    end

    % AC bus
    if(params.nac > 0)
        names = [names; ...
            {'u_F_d_min'},{'u_F_switch'}; ...
            {'u_F_d_max'},{'u_F_switch'}; ...
            {'e_F_min'},{'u_F_switch'}; ...
            {'e_F_max'},{'u_F_switch'}; ...
            {'e_F_0'},{'u_F_switch'}; ...
            {'u_F_q_min'},{'u_F_switch'}; ...
            {'u_F_q_max'},{'u_F_switch'}];
    end

    % Inverters
    if(params.ninv > 0)
        names = [names; ...
            {'u_G_min'},{'u_G_switch'}; ...
            {'u_G_max'},{'u_G_switch'}; ...
            {'e_G_min'},{'u_G_switch'}; ...
            {'e_G_max'},{'u_G_switch'}; ...
            {'e_G_0'},{'u_G_switch'}];
    end
end

% Turns off various parameters if we're not using that control element
function params = switch_off(params,pp,ss,t)
    % Determine if we have an initial parameter
    is_initial = isequal(pp(end-1:end),'_0');

    % Grab the parameters
    p = getfield(params,pp);
    if ~is_initial
        pt = p{t};
    else
        pt = p;
    end
    s = getfield(params,ss); s = s{t};

    % Turn off the parameters when required
    pt = pt.*s;

    % Put everything back into params
    if ~is_initial
        p{t}=pt;
    else
        p = pt;
    end
    params = setfield(params,pp,p);
end
