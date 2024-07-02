function [ model, In, Out ] = QBO_nlsaModel( experiment )
    % Construct NLSA model for analysis of zonal wind ERA5 data

    %% "Default" Arguments - makes individual model construction less painful
    %% can reset any of these in model selection, but shouldn't have to change original 

    % data settings
    In.dataspacing = 1. /(52); % have weekly timepoints
    In.levels = [10, 20, 30, 50, 70, 100, 125];
    
    % Time specification (finished at bottom)
    In.tLimInd = [ 1, 41 ];
    yearstart = 1979;

    % Batches to partition the in-sample data
    In.Res( 1 ).nB    = 12; % partition batches, make higher for less RAM
    In.Res( 1 ).nBRec = 12; % batches for reconstructed data

    % z500 field (source)
    In.Src( 1 ).field      = 'uw';   % physical field (area-weighted u)
    In.Src( 1 ).xLim       = [ 0 360 ]; % longitude limits
    In.Src( 1 ).yLim       = [ -90 90 ]; % latitude limits

    % z500 field (target)
    In.Trg( 1 ).field      = 'uw';      % physical field
    In.Trg( 1 ).xLim       = [ 0 360 ]; % longitude limits
    In.Trg( 1 ).yLim       = [ -90 90 ]; % latitude limits

    % Delay-embedding/finite-difference parameters; in-sample data
    In.Src( 1 ).idxE      = 1 : 140;      % delay-embedding indices 
    In.Src( 1 ).nXB       = 2;          % samples before main interval
    In.Src( 1 ).nXA       = 2;          % samples after main interval
    In.Src( 1 ).fdOrder   = 4;          % finite-difference order 
    In.Src( 1 ).fdType    = 'central';  % finite-difference type
    In.Src( 1 ).embFormat = 'overlap';  % storage format 

    % Delay-embedding/finite-difference parameters; out of -sample data
    In.Trg( 1 ).idxE      = 1 : 140;    % delay-embedding indices 
    In.Trg( 1 ).nXB       = 0;          % samples before main interval
    In.Trg( 1 ).nXA       = 0;          % samples after main interval
    In.Trg( 1 ).fdOrder   = 0;          % finite-difference order 
    In.Trg( 1 ).fdType    = 'central';  % finite-difference type
    In.Trg( 1 ).embFormat = 'overlap';  % storage format 

    % NLSA parameters; in-sample data 
    In.nN         = 0;          % nearest neighbors; defaults to max. value if 0, want at least 10% of timesteps
    In.lDist      = 'cone';     % local distance
    In.tol        = 0;          % 0 distance threshold (for cone kernel)
    In.zeta       = 0.995;      % cone kernel parameter 
    In.coneAlpha  = 0;          % velocity exponent in cone kernel
    In.nNS        = In.nN;      % nearest neighbors for symmetric distance
    In.diffOpType = 'gl_mb_bs'; % diffusion operator type
    In.epsilon    = 2;          % kernel bandwidth parameter 
    In.epsilonB   = 2;          % kernel bandwidth base
    In.epsilonE   = [ -40 40 ]; % kernel bandwidth exponents 
    In.nEpsilon   = 200;        % number of exponents for bandwidth tuning
    In.alpha      = 0.5;        % diffusion maps normalization 
    
    %% may want to adjust these parameters later on
    In.nPhi       = 150;%25;         % diffusion eigenfunctions to compute, how many eigenfunctions
    In.nPhiPrj    = In.nPhi;    % eigenfunctions to project the data
    In.idxPhiRec  = { [ 2 3 ] ...
                    [ 4 5 ] };  % eigenfunctions for reconstruction
    In.idxPhiSVD  = 1 : 1;        % eigenfunctions for linear mapping
    In.idxVTRec   = 1 : 1;        % SVD termporal patterns for reconstruction

    % Koopman generator parameters; in-sample data
    In.koopmanOpType = 'diff';     % Koopman generator type
    In.koopmanFDType  = 'central'; % finite-difference type
    In.koopmanFDOrder = 4;         % finite-difference order
    % In.koopmanDt      = In.dataspacing;        % sampling interval (in weeks)
    In.koopmanAntisym = true;      % enforce antisymmetrization
    In.koopmanEpsilon = 1.0E-3;      % regularization parameter
    In.koopmanRegType = 'inv';     % regularization type
    In.idxPhiKoopman  = 1 : In.nPhi;   % diffusion eigenfunctions used as basis
    In.nPhiKoopman    = 50; % eigenfunctions to compute
    In.nKoopmanPrj    = In.nPhiKoopman; % eigenfunctions to project the data 
    
     
    %% construct individual experiments
    if nargin == 0
        experiment = 'u_0-41_emb5_coneKernel';
    end
    
    switch experiment

    case 'u_5day_zonal'
        % Dataset specification  
        In.Res( 1 ).experiment = 'all_QBO5day_zonal';       
        In.Src( 1 ).yLim       = [ -90 90 ]; % latitude limits    
        In.Trg( 1 ).yLim       = [ -90 90 ]; % latitude limits     
    
        In.tLimInd = [ 1, 41 ]; % time limit in year start, year end  
        In.Res( 1 ).nB    = 6; % partition batches, make higher for less RAM
        In.Res( 1 ).nBRec = 32; % batches for reconstructed data
        In.dataspacing = 1. /(73);

    case 'u_5day_zonal_full'
        % Dataset specification  
        In.Res( 1 ).experiment = 'all_QBO5day_zonal';       
        In.Src( 1 ).yLim       = [ -90 90 ]; % latitude limits    
        In.Trg( 1 ).yLim       = [ -90 90 ]; % latitude limits     
    
        In.tLimInd = [ 1, 41 ]; % time limit in year start, year end  
        In.Res( 1 ).nB    = 6; % partition batches, make higher for less RAM
        In.Res( 1 ).nBRec = 32; % batches for reconstructed data
        In.Trg( 1 ).field      = 'u_alw'; 
        In.dataspacing = 1. /(73);
    otherwise
    
        error( 'Invalid experiment' )
    end
    
    
    In.tFormat        = 'yyyymmdd';              % time format
    yr = string(yearstart + In.tLimInd - 1);
    yrstr = [yr(1) + '0101',  yr(2) + '1231']';
    In.Res( 1 ).tLim  = [yrstr(1) yrstr(2)]; % time limit, i do have to match these  
    In.idxKoopmanRec  = num2cell(1:2:In.nPhiKoopman);
    In.koopmanDt      = In.dataspacing;

    %% PREPARE TARGET COMPONENTS (COMMON TO ALL MODELS)
    if ~isfield( In, 'Trg' )
        In.Trg = In.Src;
    end
    
    %% CHECK IF WE ARE DOING OUT-OF-SAMPLE EXTENSION
    ifOse = exist( 'Out', 'var' );
    
    %% SERIAL DATE NUMBERS FOR IN-SAMPLE DATA
    % Loop over the in-sample realizations
    for iR = 1 : numel( In.Res )
        %limNum = datenum( In.Res( iR ).tLim, In.tFormat );
        In.Res( 1 ).tLim(1);
        
        In.Res( iR ).tNum = In.tLimInd(1) : In.dataspacing : In.tLimInd(2);
    end
    
    %% SERIAL DATE NUMBERS FOR OUT-OF-SAMPLE DATA
    if ifOse
        % Loop over the out-of-sample realizations
        for iR = 1 : numel( Out.Res )
            limNum = datenum( Out.Res( iR ).tLim, In.tFormat );
            Out.Res( iR ).tNum = In.tLimInd(1) : In.dataspacing : In.tLimInd(2);
        end
    end
    
    %% CONSTRUCT NLSA MODEL
    if ifOse
        args = { In Out };
    else
        args = { In };
    end
    [ model, In, Out ] = climateNLSAModel( args{ : } );
    