function [output1,output2] = MyFunction(requiredPar1,requiredPar2,varargin)
% -------------------------------------------------------------------------
% Function help file:
% -------------------------------------------------------------------------
% MyFunction(requiredPar1,requiredPar2) 
%
% Description of what my function does when passed requiredPar1 and
% requiredPar2.  
%
% -------------------------------------------------------------------------
% Required Inputs
% -------------------------------------------------------------------------
% requiredPar1, datatype, description of what this par is 
% requiredPar2, datatype, description of what this par is 
% 
% -------------------------------------------------------------------------
% Outputs
% -------------------------------------------------------------------------
% output1, datatype, description of what this par is 
% output2, datatype, description of what this par is 
% 
% -------------------------------------------------------------------------
% Optional Inputs
% -------------------------------------------------------------------------
% format: 'name', 'datatype', defaultValue, description 
% 'verbose', 'boolean', false, function will print text reports of progress 
% 'optionalFlag', 'boolean', true, function does something you can switch off
% 'optionalColormap','colormap', jet(256) change the colormap.
% 'optionalString','string','', some string parameter.
%
% -------------------------------------------------------------------------
% Notes
% -------------------------------------------------------------------------
% This is a demo of how to construct a function using the matlab-storm
% standard format and default parameter options. 
% 
% Alistair Boettiger and Jeff Moffitt
% rewrote demo Nov 17, 2016
% 
% END of help file.


% -------------------------------------------------------------------------
% Defaults for optional variables
% -------------------------------------------------------------------------
defaults = cell(0,3);
defaults(end+1,:) = {'verbose', 'boolean', true}; % example optional par and its default 
defaults(end+1,:) = {'optionalFlag', 'boolean', false};
defaults(end+1,:) = {'optionalColormap', 'colormap', jet(256)};
defaults(end+1,:) = {'optionalString', 'string', ''};
defaults(end+1,:) = {'optionalNumber', 'nonnegative', 5.3};
% defaults(end+1,:) = {'optionalVar', '<VarType>', <VarValue>};

% -------------------------------------------------------------------------
% Parse necessary input
% -------------------------------------------------------------------------
if nargin < 2
    error('matlabSTORM:invalidArguments', 'a requiredPar1 (datatype) and requiredPar2 (datatype) are required');
end

% -------------------------------------------------------------------------
% Parse variable input
% -------------------------------------------------------------------------
parameters = ParseVariableArguments(varargin, defaults, mfilename);

%--------------------------------------------------------------------------
%% Actual Function
%--------------------------------------------------------------------------

% do something
disp('this is just a demo function, it doesnt run completely');

% call optional parameters
if parameter.verbose
    disp('hello!')
end

% do something with optional parameters if not default
if ~isempty(parameters.optionalString)
    disp(['you entered ',parameters.optionalString]);
end

% --- pass parameters to another function
output1 = NewFunction(reqIn1,'parameters',parameters);

% any parameters with the same name (e.g. 'verbose', will be treated the
% same as they were here).

% --- pass parameters to another function and change something
output2 = NewFunction(reqIn1,'verbose',false,'parameters',parameters);

