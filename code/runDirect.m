% Runs the microgrid problem on a given problem setup
function [solution fns state ops idx] = runDirect(params)

    % Make sure Optizelle is in the path
    global Optizelle;
    setupOptizelle();

    % Initialize the random seed
    rand('seed',0);
    randn('seed',0);

    % Check that we have a microgrid and Optizelle sections
    if ~isfield(params,'microgrid')
        error( ...
            'Microgrid specification requires a section labeled ''microgrid''');
    end
    if ~isfield(params,'Optizelle')
        error( ...
            'Microgrid specification requires a section labeled ''Optizelle''');
    end

    % Check the parameters and fill in any missing pieces
    params.microgrid = generateFull(params.microgrid);

    % Generate our indexing functions
    idx = generateIndexing(params.microgrid);

    % Allocate memory for our initial vectors
    x = generateInitial(params.microgrid,idx);
    y = zeros(idx.Y.size,1);
    z = zeros(idx.Z.size,1);

    % Set the vector spaces
    ops = struct();
    ops.X = Optizelle.Rm;
    ops.Y = Optizelle.Rm;
    ops.Z = Optizelle.Rm;
    ops.X.norm = @(x)sqrt(ops.X.innr(x,x));
    ops.Y.norm = ops.X.norm;
    ops.Z.norm = ops.X.norm;

    % Create an optimization state
    state = Optizelle.Constrained.State.t( ...
        Optizelle.Rm,Optizelle.Rm,Optizelle.Rm,x,y,z);
    state = readParams(state,params.Optizelle);
    state.PSchur_left_type = Optizelle.Operators.UserDefined;

    % Grab our functions
    fns = Optizelle.Constrained.Functions.t;
    fns.f = generateObjective(params.microgrid,idx);
    [fns.g,fns.PSchur_left] = generateEquality(params.microgrid,idx);
    fns.h = generateInequality(params.microgrid,idx);

    % Solve the optimization problem
    state = Optizelle.Constrained.Algorithms.getMin( ...
        ops.X,ops.Y,ops.Z,Optizelle.Messaging.stdout,fns,state);

    % Extract the solution
    solution = struct();
    solution = unvectorizeX(params.microgrid,idx,state.x);
    names = fieldnames(solution);
    for i=1:length(names)
        solution.(names{i})=cell2mat(solution.(names{i}));
    end

    % Put some metrics into the solution
    solution.metrics.optimality = ops.X.norm( ...
        fns.f.grad(state.x) ...
        + fns.g.ps(state.x,state.y) ...
        - fns.h.ps(state.x,state.z));
    solution.metrics.feasibility = ops.Y.norm(fns.g.eval(state.x));
    solution.metrics.barrier = state.mu;

    % Compute some derived quantities

    % Boost converters
    if params.microgrid.nboost > 0
        % Load
        solution.derived.load_v_A = ...
            cell2mat(params.microgrid.L_A) .* solution.i_A_dot ...
            + cell2mat(params.microgrid.R_A) .* solution.i_A ...
            + cell2mat(params.microgrid.P_A) ./ solution.i_A;
        solution.derived.load_i_A = solution.i_A;
        solution.derived.load_p_A = ...
            solution.derived.load_i_A .* solution.derived.load_v_A;

        % Generation
        solution.derived.generation_A = ...
            (cell2mat(params.microgrid.v_A) + solution.u_A) .* solution.i_A;

        % Storage
        solution.derived.storage_v_A = solution.u_A;
        solution.derived.storage_i_A = solution.i_A;
        solution.derived.storage_p_A = solution.p_A;
        solution.derived.storage_e_A = solution.e_A;

        % Duty cycle
        solution.derived.duty_A = solution.lambda_A;
    end

    % DC bus
    if params.microgrid.ndc > 0
        % Load
        solution.derived.load_v_B = solution.v_B;
        solution.derived.load_i_B = ...
            cell2mat(params.microgrid.C_B) .* solution.v_B_dot ...
            + solution.v_B ./ cell2mat(params.microgrid.R_B) ...
            + cell2mat(params.microgrid.P_B) ./ solution.v_B;
        solution.derived.load_p_B = ...
            solution.derived.load_i_B .* solution.derived.load_v_B;

        % Generation
        solution.derived.generation_B = solution.u_B .* solution.v_B;

        % Storage
        solution.derived.storage_v_B = solution.v_B;
        solution.derived.storage_i_B = solution.u_B;
        solution.derived.storage_p_B = solution.p_B;
        solution.derived.storage_e_B = solution.e_B;
    end

    % DC to DC connector
    if params.microgrid.ndcdc > 0
        % Load
        solution.derived.load_v_C = ...
            cell2mat(params.microgrid.L_C) .* solution.i_C_dot ...
            + cell2mat(params.microgrid.R_C) .* solution.i_C;
        solution.derived.load_i_C = solution.i_C;
        solution.derived.load_p_C = ...
            solution.derived.load_i_C .* solution.derived.load_v_C;

        % Generation
        solution.derived.generation_C = solution.u_C .* solution.i_C;

        % Storage
        solution.derived.storage_v_C = solution.u_C;
        solution.derived.storage_i_C = solution.i_C;
        solution.derived.storage_p_C = solution.p_C;
        solution.derived.storage_e_C = solution.e_C;

        % Duty cycle
        solution.derived.duty_C = solution.lambda_C;
    end

    % AC to DC connector
    if params.microgrid.nacdc > 0
        % Load
        solution.derived.load_v_E_d = ...
            cell2mat(params.microgrid.L_E) .* solution.i_E_d_dot ...
            + cell2mat(params.microgrid.R_E) .* solution.i_E_d;
        solution.derived.load_v_E_q = ...
            cell2mat(params.microgrid.L_E) .* solution.i_E_q_dot ...
            + cell2mat(params.microgrid.R_E) .* solution.i_E_q;
        solution.derived.load_v_E = ...
            sqrt(solution.derived.load_v_E_d.^2+solution.derived.load_v_E_q.^2);
        solution.derived.load_i_E_d = solution.i_E_d;
        solution.derived.load_i_E_q = solution.i_E_q;
        solution.derived.load_i_E = ...
            sqrt(solution.derived.load_i_E_d.^2+solution.derived.load_i_E_q.^2);
        solution.derived.load_p_E = ...
            solution.derived.load_i_E_d .* solution.derived.load_v_E_d ...
            + solution.derived.load_i_E_q .* solution.derived.load_v_E_q;

        % Duty cycle
        solution.derived.duty_E = solution.lambda_E;
    end

    % AC bus
    if params.microgrid.nac > 0
        % Load
        solution.derived.load_v_F_d = solution.v_F_d;
        solution.derived.load_v_F_q = solution.v_F_q;
        solution.derived.load_v_F = ...
            sqrt(solution.derived.load_v_F_d.^2+solution.derived.load_v_F_q.^2);
        solution.derived.load_i_F_d = ...
            cell2mat(params.microgrid.C_F) .* solution.v_F_d_dot ...
            + solution.v_F_d ./ cell2mat(params.microgrid.R_F) ...
            + cell2mat(params.microgrid.P_F_d) ./ solution.v_F_d ...
            - cell2mat(params.microgrid.omega_F) ...
                .* cell2mat(params.microgrid.C_F) ...
                .* solution.v_F_q;
        solution.derived.load_i_F_q = ...
            cell2mat(params.microgrid.C_F) .* solution.v_F_q_dot ...
            + solution.v_F_q ./ cell2mat(params.microgrid.R_F) ...
            + cell2mat(params.microgrid.P_F_q) ./ solution.v_F_q ...
            + cell2mat(params.microgrid.omega_F) ...
                .* cell2mat(params.microgrid.C_F) ...
                .* solution.v_F_d;
        solution.derived.load_i_F = ...
            sqrt(solution.derived.load_i_F_d.^2+solution.derived.load_i_F_d.^2);
        solution.derived.load_p_F = ...
            solution.derived.load_i_F_d .* solution.derived.load_v_F_d ...
            + solution.derived.load_i_F_q .* solution.derived.load_v_F_q;

        % Generation
        solution.derived.generation_F = ...
            solution.u_F_d .* solution.v_F_d  ...
            + solution.u_F_q .* solution.v_F_q;

        % Storage
        solution.derived.storage_v_F = ...
            sqrt(solution.v_F_d.^2 + solution.v_F_q.^2);
        solution.derived.storage_i_F = ...
            sqrt(solution.u_F_d.^2 + solution.u_F_q.^2);
        solution.derived.storage_p_F = solution.p_F;
        solution.derived.storage_e_F = solution.e_F;
    end

    % Inverter
    if params.microgrid.ninv > 0
        % Load (AC)
        solution.derived.load_v_G_d = ...
            cell2mat(params.microgrid.L_G) .* solution.i_G_d_dot ...
            + cell2mat(params.microgrid.R_G) .* solution.i_G_d;
        solution.derived.load_v_G_q = ...
            cell2mat(params.microgrid.L_G) .* solution.i_G_q_dot ...
            + cell2mat(params.microgrid.R_G) .* solution.i_G_q;
        solution.derived.load_v_G_ac = ...
            sqrt(solution.derived.load_v_G_d.^2+solution.derived.load_v_G_q.^2);
        solution.derived.load_i_G_d = solution.i_G_d;
        solution.derived.load_i_G_q = solution.i_G_q;
        solution.derived.load_i_G_ac = ...
            sqrt(solution.derived.load_i_G_d.^2+solution.derived.load_i_G_q.^2);
        solution.derived.load_p_G_ac = ...
            solution.derived.load_i_G_d .* solution.derived.load_v_G_d ...
            + solution.derived.load_i_G_q .* solution.derived.load_v_G_q;

        % Load (DC)
        solution.derived.load_v_G_dc = solution.v_G_dc;
        solution.derived.load_i_G_dc = ...
            cell2mat(params.microgrid.C_G_dc) .* solution.v_G_dc_dot ...
            + solution.v_G_dc ./ cell2mat(params.microgrid.R_G_dc);
        solution.derived.load_p_G_dc = ...
            solution.derived.load_i_G_dc .* solution.derived.load_v_G_dc;

        % Generation
        solution.derived.generation_A = ...
            (cell2mat(params.microgrid.v_G) + solution.u_G) .* solution.i_G;

        % Storage
        solution.derived.storage_v_G = solution.u_G;
        solution.derived.storage_i_G = solution.i_G;
        solution.derived.storage_p_G = solution.p_G;
        solution.derived.storage_e_G = solution.e_G;

        % Duty cycle
        solution.derived.duty_G = solution.lambda_G;
    end
end
