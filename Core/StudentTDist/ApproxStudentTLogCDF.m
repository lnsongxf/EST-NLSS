function log_y = ApproxStudentTLogCDF( x, nu )

    % Test with:
    % [ xr, xi ] = meshgrid( -100:1:100, -0.5:0.01:0.5 );
    % x = xr + xi .* 1i;
    % z1 = abs( ApproxStudentTLogCDF( x, 1 ) - log( 0.5 + 1 ./ pi .* atan( x ) ) );
    % z2 = abs( ApproxStudentTLogCDF( x, 2 ) - log( 0.5 + 0.5 .* x ./ sqrt( 2 + x .* x ) ) ) ;
    % disp( max( z1(:) ) );
    % disp( max( z2(:) ) );
    % figure( 1 ); surf( xr, xi, z1 );
    % figure( 2 ); surf( xr, xi, z2 );

    ESTNLSSassert( numel( nu ) == 1, 'ESTNLSS:ApproxStudentTLogCDF:NuSize', 'ApproxStudentTLogCDF only supports univariate nu.' );
    ESTNLSSassert( real( nu ) >= 0, 'ESTNLSS:ApproxStudentTLogCDF:NuSign', 'ApproxStudentTLogCDF requires nu to be weakly positive.' );
    ESTNLSSassert( all( ~isnan( x(:) ) ), 'ESTNLSS:ApproxStudentTLogCDF:NaNInputX', 'ApproxStudentTLogCDF was passed a NaN input x.' );
    
    lognu = log( nu );
    if real( lognu ) <= -Inf
        if isreal( x ) && isreal( nu )
            log_y = log( 0.5 ) * ones( size( x ) );
        else
            log_y = complex( log( 0.5 ) * ones( size( x ) ) );
        end
        log_y( real( x ) <= -Inf ) = -Inf;
        log_y( real( x ) >= Inf ) = 0;
        return
    end
    
    if isreal( x ) && isreal( nu )
        log_y = zeros( size( x ) );
    else
        log_y = complex( zeros( size( x ) ) );
    end
    
    SelInf = real( x ) >= Inf;
    
    SelNInf = real( x ) <= -Inf;
    log_y( SelNInf ) = -Inf;
    
    SelNaN = isnan( real( x ) );
    log_y( SelNaN ) = NaN;
    
    Done = SelInf | SelNInf | SelNaN;
    Remaining = find( ~Done );
    
    logH = log( 0.5 );
    
    xRemaining = x( Remaining );
    
    Pos_xRemaining = ( real( xRemaining ) > 0 ) | ( ( real( xRemaining ) == 0 ) & ( imag( xRemaining ) > 0 ) );
    xRemaining( Pos_xRemaining ) = -xRemaining( Pos_xRemaining );
    
    % start with a normal cdf which provides a lower bound in the t case
    
    if isreal( x )
        yRemaining = 0.5 + 0.5 * erf( xRemaining * 0.7071067811865475244008 ); % 0.7071067811865475244008 = 1 / sqrt( 2 )
    else
        yRemaining = 0.5 + 0.5 * erfz( xRemaining * 0.7071067811865475244008 ); % 0.7071067811865475244008 = 1 / sqrt( 2 )
    end
    SelGood = real( yRemaining ) > 0;
    IdxGood = Remaining( SelGood );
    SelBad = ~SelGood;
    IdxBad = Remaining( SelBad );
    log_y( IdxGood ) = log( yRemaining( SelGood ) );

    t = xRemaining( SelBad );
    t = t(:).';

    tR2 = t .* t;
    ItR2 = 1 ./ tR2;
    ItR4 = ItR2 .* ItR2;
    ItR6 = ItR4 .* ItR2;
    ItR8 = ItR4 .* ItR4;
    ItR10 = ItR6 .* ItR4;
    ItR12 = ItR6 .* ItR6;

    log_y( IdxBad ) = Shanks( bsxfun( @times, [ 1; -1; 2.5; -12.33333333333333333333; 88.25; -816.2; 9200.833333333333333333 ], [ -.5*tR2-.9189385332046727417802-log(-t); ItR2; ItR4; ItR6; ItR8; ItR10; ItR12 ] ) );

    log_y( IdxBad( real( ItR12 ) >= Inf ) ) = logH;

    log_y( IdxBad( real( log_y( IdxBad ) ) > real( logH ) ) ) = logH;
    
    % now adjust the t-elements
    
    if real( nu ) < Inf
        
        if isreal( x ) && isreal( nu )
            yRemaining = real( betainc( nu ./ ( xRemaining .* xRemaining + nu ), 0.5 * nu, 0.5 ) * 0.5 );
        else
            yRemaining = cbetainc( nu ./ ( xRemaining .* xRemaining + nu ), 0.5 * nu, 0.5 ) * 0.5;
        end
        SelGood = real( yRemaining ) > realmin;
        IdxGood = Remaining( SelGood );
        SelBad = ~SelGood;
        IdxBad = Remaining( SelBad );
        log_y_IdxGood_tmp = log( yRemaining( SelGood ) );
        SubSelGood = real( log_y_IdxGood_tmp ) > real( log_y( IdxGood ) );
        log_y( IdxGood( SubSelGood ) ) = log_y_IdxGood_tmp( SubSelGood );

        InuP2 = 1 / ( 2 + nu );
        InuP2R2 = InuP2 * InuP2;
        InuP2R3 = InuP2R2 * InuP2;
        InuP2R4 = InuP2R2 * InuP2R2;
        InuP2R5 = InuP2R3 * InuP2R2;
        InuP2R6 = InuP2R3 * InuP2R3;
        InuP4 = 1 / ( 4 + nu );
        InuP4R2 = InuP4 * InuP4;
        InuP4R3 = InuP4R2 * InuP4;
        InuP6 = 1 / ( 6 + nu );
        InuP6R2 = InuP6 * InuP6;
        InuP8 = 1 / ( 8 + nu );
        InuP10 = 1 / ( 10 + nu );
        InuP12 = 1 / ( 12 + nu );
        
        Cnu = [ -lognu;
                -1+2*InuP2;
                +2.5-2*InuP2R2+8*InuP2-24*InuP4;
                -12.33333333333333333333+2.666666666666666666667*InuP2R3-16*InuP2R2+41*InuP2-288*InuP4+405*InuP6;
                +88.25-4*InuP2R4+32*InuP2R3-114*InuP2R2+239.5*InuP2-288*InuP4R2-2256*InuP4+9112.5*InuP6-8960*InuP8;
                -816.2+6.4*InuP2R5-64*InuP2R4+292*InuP2R3-807*InuP2R2+1516.166666666666666667*InuP2-6912*InuP4R2-10560*InuP4+123018.75*InuP6-334506.6666666666666667*InuP8+246093.75*InuP10;
                +9200.833333333333333333-10.66666666666666666667*InuP2R6+128*InuP2R5-712*InuP2R4+2440.666666666666666667*InuP2R3-5788.833333333333333333*InuP2R2+10131.82638888888888889*InuP2-4608*InuP4R3-95616*InuP4R2+17904*InuP4-82012.5*InuP6R2+1283495.625*InuP6-7470648.888888888888889*InuP8+13842773.4375*InuP10-8083152*InuP12;
              ];
        
        t = xRemaining( SelBad );
        t = t(:).';
        
        tR2 = t .* t;
        ItR2 = 1 ./ tR2;
        ItR4 = ItR2 .* ItR2;
        ItR6 = ItR4 .* ItR2;
        ItR8 = ItR4 .* ItR4;
        ItR10 = ItR6 .* ItR4;
        ItR12 = ItR6 .* ItR6;
        
        nuOtR2Pnu = nu ./ ( tR2 + nu );
        
        if isreal( nu )
            log_y_IdxBad_tmp = Shanks( bsxfun( @times, Cnu, [ ones( size( t ) ); ItR2; ItR4; ItR6; ItR8; ItR10; ItR12 ] ) ) - betaln( nu * 0.5, 0.5 ) + 0.5 * nu * log( nuOtR2Pnu ) - 0.5 * log1p( - nuOtR2Pnu );
        else
            log_y_IdxBad_tmp = Shanks( bsxfun( @times, Cnu, [ ones( size( t ) ); ItR2; ItR4; ItR6; ItR8; ItR10; ItR12 ] ) ) - cbetaln( nu * 0.5, 0.5 ) + 0.5 * nu * log( nuOtR2Pnu ) - 0.5 * log1p( - nuOtR2Pnu );
        end
        SubSelBad = real( log_y_IdxBad_tmp ) > real( log_y( IdxBad ) );
        log_y( IdxBad( SubSelBad ) ) = log_y_IdxBad_tmp( SubSelBad );
        
        log_y( IdxBad( real( ItR12 ) >= Inf ) ) = logH;
        
        log_y( IdxBad( real( log_y( IdxBad ) ) > logH ) ) = logH;
        
    end
    
    IdxPos = Remaining( Pos_xRemaining );
    log_y( IdxPos ) = log1p( -exp( log_y( IdxPos ) ) );
    
    ESTNLSSassert( all( ~isnan( log_y(:) ) ), 'ESTNLSS:ApproxStudentTLogCDF:NaNOutputLogY', 'ApproxStudentTLogCDF returned a NaN output log_y.' );    
    
end
