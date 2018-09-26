% Runs the microgrid problem on a given problem setup
function [solution fns state ops idx] = runScenario(scenario,variant)

    % Make sure Optizelle is in the path
    global Optizelle;
    setupOptizelle();

    % Find the location of this directory
    here = fileparts(mfilename('fullpath'));

    % Set the requisite paths
    mname = sprintf('%s/../data/%s/microgrid.json',here,scenario);
    rdir = sprintf('%s/../results/%s',here,scenario);
    sname = sprintf('%s/solution.json',rdir);
    dname = sprintf('%s/last_output.txt',rdir);
    lname = sprintf('%s/last_solution.json',rdir);
    %addpath(sprintf('%s/../thirdparty/jsonlab',here));

    % Throw an error if the scenario does not exist
    if exist(mname) ~= 2
        error(sprintf('Can not find scenario file: %s',mname));
    end

    % Create the result directory if not availible
    if exist(rdir) == 0
        mkdir(rdir);
    elseif exist(rdir) ~= 7
        error('Unable to create the folder %s due to an existing object',rdir)
    end

    % Create the solution files if they don't exist
    files = {sname,lname};
    for i=1:2
        if exist(files{i}) == 0
            fid = fopen(files{i},'w');
            fprintf(fid,'{}\n');
            fclose(fid);
        elseif exist(files{i}) ~= 2
            error('Unable to create the file %s due to an existing object', ...
                files{i});
        end
    end

    % Create the output file if it doesn't exist
    if exist(dname) == 0
        fid = fopen(dname,'w');
        fprintf(fid,'\n');
        fclose(fid);
    elseif exist(dname) ~= 2
        error('Unable to create the file %s due to an existing object',dname);
    end

    % Grab the parameters
    params = loadjson(mname);

    % Merge the parameters from the particular problem variant
    if nargin > 1 && ~isempty(params.(variant));

        % Grab the variant names
        vnames = fieldnames(params.(variant));

        % Otherwise, merge the variant names into the microgrid
        for i = 1:length(vnames)
            params.microgrid.(vnames{i}) = params.(variant).(vnames{i});
        end
    end

    % Run the scenario
    diary(dname);
    [solution fns state ops idx] = runDirect(params);
    diary off;

    % Save the solution to file
    old_solutions = loadjson(sname);
    if nargin > 1
        old_solutions.(variant) = solution;
        savejson('',old_solutions,sname);
    end
    savejson('',solution,lname);
end
