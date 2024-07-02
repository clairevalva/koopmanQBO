function Data = importData_QBO_5zonal( DataSpecs, fn)
    % as of May 2, 2022 — this is the working data import file for zonally meaned data
    % IMPORTDATA_Z500 Read QBO netCDF file, and output in format appropriate for 
    % NLSA code.
    % 
    % DataSpecs is a data structure containing the specifications of the data to
    % be read. 
    %
    % Data is a data structure containing the data read and associated attributes.
    %
    % DataSpecs has the following fields:
    %
    % In.dir:             Input directory name
    % In.file:            Input filename base
    % In.var:             Variable to be read
    % Out.dir:            Output directory name
    % Out.fld:            Output label 
    % Time.tFormat:       Format of serial date numbers (e.g, 'yyyymm')
    % Time.tLim:          Cell array of strings with time limits 
    % Domain.xLim:        Longitude limits
    % Domain.yLim:        Latitude limits
    % Opts.ifWeight:      Perform area weighting if true 
    % Opts.ifOutputData:  Only data attributes are returned if set to false
    % Opts.ifWrite:       Write data to disk
    %
    % Modified 2020/11/24
    
    
    %% UNPACK INPUT DATA STRUCTURE FOR CONVENIENCE
    In     = DataSpecs.In;
    Out    = DataSpecs.Out; 
    Time   = DataSpecs.Time;
    Domain = DataSpecs.Domain;
    Opts   = DataSpecs.Opts;
    Opts.ifWeight = true;
    
    
    dt = In.dt

    %% READ DATA
    % Variable name
    fldStr = Out.fld; 
    %% fidStr needs one quote mark!
    
    % Append 'w' if performing area weighting
    if Opts.ifWeight
        fldStr = [ fldStr 'w' ];
    end
    
    % Output directory
    dataDir = fullfile( Out.dir, ...
                        fldStr, ...
                        [ sprintf( 'x%i-%i',  Domain.xLim ) ...
                          sprintf( '_y%i-%i', Domain.yLim ) ...
                          '_' Time.tLim{ 1 } '-' Time.tLim{ 2 } ] );
    
    if Opts.ifWrite && ~isdir( dataDir )
        mkdir( dataDir )
    end
    
    
    In.file; % should be "u"
    getlevs = In.getlevs; % the levels want for the experiment
    
    ncId = netcdf.open(fn);
    fldFile = ncread(fn,In.file);
    size(fldFile)
    size(fldFile)

    % get and parse levels
    levels = ncread(fn, 'level');
    lats = ncread(fn, 'latitude');
    lats(1:10)
    % get the things with the right level
    
    lev_inds = ones(size(getlevs));
    lev_wgts = ones(size(getlevs));
    for j = 1:size(getlevs,2)
        lev_inds(j) = find(levels == getlevs(j));
        lev_wgts(j) = getlevs(j)*100 / 9.8;
    end
    lev_wgts = lev_wgts ./ lev_wgts(end);
    lev_wgts
    
    % % Create longitude-latitude grid, assumping 1.5 degree resolution
    dLon = 0.25; 
    dLat = 0.25;
    lon = ( 0 : 1 - 1 ) * dLon;
    lon = lon( : ); % make into column vector 
    lat = ( 0 : 721 - 1 ) * dLat;
    lat = lat( : ) - 90;
    lat(1:10)

    
    [ X, Y ] = ndgrid( lon, lat );
    
    % % Create region mask 
    ifXY = X >= Domain.xLim( 1 ) & X <= Domain.xLim( 2 ) ...
         & Y >= Domain.yLim( 1 ) & Y <= Domain.yLim( 2 );
    iXY = find( ifXY( : ) );
    size(ifXY);
    nXY = length( iXY );
    
    
    % deal with dates  // this is annoying to work with definitely
    yearstart = squeeze(In.yrstart);
    
    yearend = In.yrend;
    nT = (yearend - (yearstart - 1))*dt
    yearstart
    nL = size(getlevs,2);
    size(fldFile)
    fldFile = fldFile(:,1 + (yearstart - 1)*dt: yearend*dt, :);
    fldFile = fldFile(:,:, lev_inds);
    for j = 1:size(getlevs,2)
        fldFile(:,:,j) = fldFile(:,:,j).*lev_wgts(j);
    end
    % roll axis to match prev
    fldT = reshape(fldFile, [], nT, nL);
    fldT = permute(fldT,[1 3 2]);
    size(fldT)
    fldT = fldT(:,:,:);
    
    fld = fldT;
    
    % Initialize data array
    %fld = zeros( nXY, nT );
    
    % If requested, weigh the data by the (normalized) grid cell surface areas. 
    % Surface area calculation is approximate as it treats Earth as spherical
    if Opts.ifWeight
        lat = (0:720)*0.25;
        lat = lat( : ) - 90;
        dLat = 0.25;
        nY = 721
        diffLat = [ lat( 1 ) - dLat; lat; lat( end ) + dLat ] * pi / 180;
    
        diffLat = ( diffLat( 1 : end - 1 ) + diffLat( 2 :end ) ) / 2;
        diffLat = diffLat( 2 : end ) - diffLat( 1 : end - 1 );
        diffLat = abs( diffLat .* cos( lat * pi / 180 ) );
    
        % Compute surface area weights
        w = diffLat;
        w = sqrt( w / sum( w ) * nY );
        fld = w .* fld ;
    end
    
    % print size of fld
    disp("size of data is (should be [spatial * levels,time])")
    size(fld)
    fld = reshape(fld, [], nT);
    % Output data dimension
    nD = size( fld, 1 )
    
    %% RETURN AND WRITE DATA
    % Grid information
    gridVarList = { 'lat', 'lon', 'ifXY', 'fldStr', 'nD' };
    if Opts.ifWrite
        gridFile = fullfile( dataDir, 'dataGrid.mat' );
        save( gridFile, gridVarList{ : }, '-v7.3' )  
    end
    
    % Output data and attributes
    x = fld; % for compatibility with NLSA code
    varList = { 'x' };
    dataDir
    if Opts.ifWrite
        fldFile = fullfile( dataDir, 'dataX.mat' );
        save( fldFile, varList{ : },  '-v7.3' )  
    end
    
    % If needed, assemble data and attributes into data structure and return
    if nargout > 0
        varList = [ varList gridVarList ];
        if ~Opts.ifOutputData
            % Exclude data from output 
            varList = varList( 2 : end );
        end
        nVar = numel( varList );
        vars = cell( 1, nVar );
        for iVar = 1 : nVar
           vars{ iVar } = eval( varList{ iVar } );
        end
        Data = cell2struct( vars, varList, 2 );
    end
    
    
    