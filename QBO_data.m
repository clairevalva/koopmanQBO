function QBO_data( fld, tLim, tLimInd, dt, levs,ylims, fldname )
% BLOCKING_DATA Helper function to import datasets for NLSA/Koopman analysis of
% blocking.
%
% fld   - String identifier for variable to read. 
% tLim  - Cell array of strings for time limits of analysis period. 
%
% This function creates a data structure with input data specifications as 
% appropriate for the dataset and fld arguments. 
%
% The data is then retrieved and saved on disk using the importData function. 
%
% Modified 2020/10/29

% Directory for input data 
DataSpecs.In.dir = '/kontiki6/cnv5172/QBO';
fn = '/kontiki6/cnv5172/QBO/newdat_02.nc'; 
DataSpecs.In.dir  = fullfile( DataSpecs.In.dir, 'era5' );

% Output directory
strstr = fldname
DataSpecs.Out.dir = fullfile( pwd, 'data/raw', strstr );

% Time specification
DataSpecs.Time.tFormat = 'yyyymmdd';    
DataSpecs.Time.tLim    = tLim;
    
% Spatial domain 
DataSpecs.Domain.xLim = [ 0 360 ]; % longitude, taking zonal mean so irrelevant
DataSpecs.Domain.yLim = ylims;

% Output variable name
DataSpecs.Out.fld = fld;


% Output options
DataSpecs.Opts.ifWrite  = true; % write data to disk
DataSpecs.Opts.ifWeight = true; % do area weighting


% Set variable/file names, read data 
switch fld
case 'uzonal_5'
    fn = '/kontiki6/cnv5172/QBO/climatedata/era5/u_5day_zonal_july23.nc'
    DataSpecs.In.yrstart = tLimInd(1);
    DataSpecs.In.yrend = tLimInd(2);
    DataSpecs.In.file = 'u';
    DataSpecs.In.getlevs = levs;
    DataSpecs.In.var  = 'u';
    DataSpecs.In.dt = 73;
    DataSpecs.Out.fld = 'u'
    importData_QBO_5zonal( DataSpecs , fn)
case 'uzonal_5f'
    fn = '/kontiki6/cnv5172/QBO/climatedata/era5/u_5day_zonal_july23.nc'
    DataSpecs.In.yrstart = tLimInd(1);
    DataSpecs.In.yrend = tLimInd(2);
    DataSpecs.In.file = 'u';
    DataSpecs.In.getlevs = levs;
    DataSpecs.In.var  = 'u';
    DataSpecs.In.dt = 73;
    DataSpecs.Out.fld = 'u_al'
    importData_QBO_5zonal( DataSpecs , fn)
otherwise
    error( 'Invalid input variable' )
end


