% Reads optimization parameters from file and merges them with the state
function state = readParams(state,params)
    % If we don't have any parameters, exit
    if isempty(params)
        return;
    end

    % Grab the fields names
    snames = fieldnames(state);
    pnames = fieldnames(params);

    % If there are names in params not in state, then there's a problem
    bad_names = setdiff(pnames,snames);
    if length(bad_names) > 0
        err = 'Found invalid parameter names: ';
        for i = 1:length(bad_names)-1
            err = sprintf('%s%s, ',err,bad_names{i});
        end
        err = sprintf('%s%s',err,bad_names{end});
        error(err);
    end

    % Otherwise, merge the names
    for i = 1:length(pnames)
        state.(pnames{i}) = params.(pnames{i});
    end
end
