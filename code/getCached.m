% Grab a cached value if stored.  Here,
%
% storage - Cache of values and points where these values were generated.
%     We need its structure to be something like storage.x{i}, storage.y{i}
%     for the points and storage.v{i} for the values.
% point - Cell array of structures that contain the location of the cached
%     point
% value - Name of the value to be returned
function [ret storage] = getCached(storage,point,value)
    % Check that we have initialized the storage
    if ~isstruct(storage)
        ret = [];
        return;
    end

    % Check that there's a value cached
    if ~isfield(storage,value)
        ret = []
        return;
    end

    % Loop over the various cached points
    for i = 1:length(storage.(value))

        % Loop over the names in the point that we're checking
        names = fieldnames(point);
        match = true;
        for j=1:length(names)
            % If the storage doesn't contained the cached point or if the cached
            % point differs from queried point, then we're not cached
            if  ~isfield(storage,names{j}) || ...
                ~isequal(storage.(names{j}){i},point.(names{j}))
                match = false;
            end

            % If we match the point, return the value
            if match
                ret = storage.(value){i};
                break;

            % Otherwise, return something empty
            else
                ret = [];
            end
        end

        % If we've successfully cached a value, break out
        if ~isempty(ret)
            break;
        end
    end

    % If we found the cached value, reshuffle things so this point and value is
    % first in the cached storage
    if ~isempty(ret)
        % Loop over the names in the point that we're checking
        names = fieldnames(point);
        for j=1:length(names)
            start = storage.(names{j})(i);
            middle = storage.(names{j})(1:i-1);
            last = storage.(names{j})(i+1:end);
            storage.(names{j}) = [start,middle,last];
        end
    end
end
