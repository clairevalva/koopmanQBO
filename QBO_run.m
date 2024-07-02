%% NLSA/KOOPMAN ANALYSIS OF QBO DATA
%
% phi   = getDiffusionEigenfunctions( model ); -- NLSA eigenfunctions
% lambda = getDiffusionEigenvalues(model); -- NLSA evenvalues
% z     = getKoopmanEigenfunctions( model );   -- Koopman eigenfunctions
% gamma = getKoopmanEigenvalues( model ) / (2*pi) -- Koopman eigenvalues  
% T     = getKoopmanEigenperiods( model ) / ; -- Koopman eigenperiods
% uPhi  = getProjectedData( model ); -- Projected data onto NLSA eigenfunctons
% uZ    = getKoopmanProjectedData( model ); -- Proj. data onto Koopman eigenfunctions
% Zrec =getKoopmanReconstructedData(model);

%% SCRIPT EXECUTION OPTIONS

% Data extraction
ifDataSource = false;  % extract source data fron netCDF files

% Spectral decomposition
ifNLSA    = false; % compute kernel (NLSA) eigenfunctions
ifKoopman = false;  % compute Koopman eigenfunctions

% Reconstruction
ifNLSARec    = false; % do reconstruction based on NLSA
ifKoopmanRec = false; % do reconstruction based on Koopman run


%% BUILD NLSA MODEL, DETERMINE BASIC ARRAY SIZES
% In is a data structure containing the NLSA parameters for the training data.
%
% nSE is the number of samples avaiable for data analysis after Takens delay
% embedding.
%
% nSB is the number of samples left out in the start of the time interval (for
% temporal finite differnences employed in the kernel).

experiment = 'u_5day_zonal_full'
namecon = experiment;

fulllevs = [ 1, 2, 3, 5, 7, 10,   20,   30,   50,   70,  100,  125,  200,  300,  400,  500,  600, 700,  800,  900, 1000];
highlevs = [1, 2, 3, 5, 7, 10, 20, 30, 50, 70, 100, 125];


if ifDataSource 
    if strcmp(experiment,'u_5day_zonal_full')
        tLim = { '19790101' '20191231' };
        tLimInd = [ 1, 41 ];
        yLims = [ -90 90 ];
        levs = fulllevs; % [10, 20, 30, 50, 70, 100, 125];
        dt = 73;
        fldname = 'all_QBO5day_zonal'
        QBO_data('uzonal_5f', tLim, tLimInd, dt, levs, yLims, fldname)
    end
end

[ model, In ] = QBO_nlsaModel( experiment); 

% nSE          = getNTotalSample( model.embComponent );
% nSB          = getNXB( model.embComponent );

% Create parallel pool if running NLSA and the NLSA model has been set up
% with parallel workers. This part can be commented out if no parts of the
% NLSA code utilizing parallel workers are being executed. 
%
% In.nParE is the number of parallel workers for delay-embedded distances
% In.nParNN is the number of parallel workers for nearest neighbor search
if ifNLSA || ifNLSARec || ifKoopmanRec
    if isfield( In, 'nParE' ) && In.nParE > 0
        nPar = In.nParE;
    else
        nPar = 0;
    end
    if isfield( In, 'nParNN' ) && In.nParNN > 0
        nPar = max( nPar, In.nParNN );
    end
    if isfield( In, 'nParRec' ) && In.nParRec > 0
        nPar = max( nPar, In.nParRec );
    end
    if nPar > 0
        poolObj = gcp( 'nocreate' );
        if isempty( poolObj )
            poolObj = parpool( nPar );
        end
    end
end

iProc = 1;
nProc = 1;
%% PERFORM NLSA
if ifNLSA
    
    % Execute NLSA steps. Output from each step is saved on disk

    disp( 'Takens delay embedding...' ); t = tic; 
    computeDelayEmbedding( model )
    toc( t )

    disp( 'Phase space velocity (time tendency of data)...' ); t = tic; 
    computeVelocity( model )
    toc( t )

    fprintf( 'Pairwise distances (%i/%i)...\n', iProc, nProc ); t = tic;
    computePairwiseDistances( model, iProc, nProc )
    toc( t )

    disp( 'Distance symmetrization...' ); t = tic;
    symmetrizeDistances( model );
    toc( t )

    disp( 'Kernel tuning...' ); t = tic;
    computeKernelDoubleSum( model );
    toc( t )

    disp( 'Kernel eigenfunctions...' ); t = tic;
    computeDiffusionEigenfunctions( model );
    toc( t )
end

%% COMPUTE EIGENFUNCTIONS OF KOOPMAN GENERATOR
if ifKoopman
    disp( 'Koopman eigenfunctions...' ); t = tic;
    computeKoopmanEigenfunctions( model, 'ifLeftEigenfunctions', true );
    toc( t )
end

%% PERFORM NLSA RECONSTRUCTION
if ifNLSARec

    disp( 'Takens delay embedding...' ); t = tic; 
    computeTrgDelayEmbedding( model )
    toc( t )
    
    disp( 'Projection of target data onto kernel eigenfunctions...' ); t = tic;
    computeProjection( model )
    toc( t )

    % disp( 'Reconstruction of target data from kernel eigenfunctions...' ); 
    % t = tic;
    % computeReconstruction( model, [],[], [], [], nPar  )
    % toc( t )
end
    

%% PERFORM KOOPMAN RECONSTRUCTION
if ifKoopmanRec

    % disp( 'Takens delay embedding...' ); t = tic; 
    % computeTrgDelayEmbedding( model )
    % toc( t ) 
    % above unneeded as it repeats
    
    disp( 'Projection of target data onto Koopman eigenfunctions...' ); t = tic;
    computeKoopmanProjection( model )
    toc( t )

    disp( 'Reconstruction of target data from Koopman eigenfunctions...' ); 
    t = tic;
    computeKoopmanReconstruction( model, [],[], [], [], nPar  )
    toc( t )
end
    
