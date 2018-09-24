% Creates an indexing function that match the elements specifified in the
% given structure
function idx_new = createIndexing(idx,ntime)

% Grab the field names
fn = fieldnames(idx);

% Loop over time then each of the field names while keeping track of the
% current starting index number
curr = 1;
for t=1:ntime
    for i=1:length(fn)
        % Get the size of the current field
        m = idx.(fn{i});

        % Write the new indices
        idx_new.(fn{i}){t} = curr:(curr+m-1);

        % Update the current index
        curr = curr + m;
    end
end

% Add a special size element to the indexing function
idx_new.size = curr-1;
