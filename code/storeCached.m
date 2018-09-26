% Caches a value and cleans up old results
function storage = storeCached(storage,point,value,limit)

    % Initialize the storage if need be
    if ~isstruct(storage)
        storage = struct();
    end

    % Initialize the points if need be
    names = fieldnames(point);
    for i=1:length(names)
        if ~isfield(storage,names{i})
            storage.(names{i}) = {};
        end
    end

    % Initialize the value if need be
    names = fieldnames(value);
    if ~isfield(storage,(names{1}))
        storage.(names{1}) = {};
    end

    % Store the points
    names = fieldnames(point);
    for i=1:length(names)
        storage.(names{i}) = [point.(names{i}) storage.(names{i})];
    end

    % Store the value
    names = fieldnames(value);
    storage.(names{1}) = [{value.(names{1})} storage.(names{1})];

    % Truncate the stored points and value if there exceed our limit
    names = fieldnames(point);
    for i=1:length(names)
        if length(storage.(names{i})) > limit
            storage.(names{i}) = storage.(names{i})(1:limit);
        end
    end
    names = fieldnames(value);
    if length(storage.(names{1})) > limit
        storage.(names{1}) = storage.(names{1})(1:limit);
    end
end
