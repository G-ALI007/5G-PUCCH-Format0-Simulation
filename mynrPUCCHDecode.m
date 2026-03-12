function [uciBits,symbols,detMet] = mynrPUCCHDecode(carrier,pucch,ouci,sym,varargin)

% --- Start: Handle optional 'DetectionThreshold' input ---

% Parse optional Name-Value pair for DetectionThreshold
thres = []; % Initialize threshold as empty
if nargin > 4
    % Check for 'DetectionThreshold' Name-Value pair
    for i = 1:2:length(varargin)
        if strcmpi(varargin{i}, 'Threshold')
            thres = varargin{i+1};
            break; % Exit loop after finding the threshold
        end
    end
end

% If the user did not provide a threshold, calculate the default value
if isempty(thres)
%     thres = 0.49 - 0.07*(pucch.SymbolAllocation(2)==2);
thres=0.49;
end

% --- End: Optional input handling ---

% Check for resource allocation to determine if transmission is possible
emptyFlag = isempty(pucch.PRBSet) || isempty(pucch.SymbolAllocation) || ...
    (pucch.SymbolAllocation(2) == 0) || isempty(sym);

numOUCIElements = numel(ouci);

% Handle the case of no transmission (Discontinuous Transmission - DTX)
if emptyFlag
    % If no resources were allocated, return an empty output
    osr = 0;
    if numOUCIElements > 1
        osr = ouci(2);
    end
    rxSR = zeros(osr,1,'int8');
    uciBits = {zeros(0,1,'int8') rxSR};
else
    % Parse the expected number of ACK and SR bits from the 'ouci' input
    if numOUCIElements > 1
        oack = ouci(1);
        osr = double(ouci(2));
    else
        oack = ouci;
        osr = 0;
    end

    % --- Start: Embedded Format 0 decoding logic ---

    dtType = class(sym);
    outDtType = 'int8';

    % Flag for SR-only transmission case
    srOnly = 0;
    if (oack == 0) && osr
        srOnly = 1;
    end

    % Generate all possible reference ACK bit combinations
    nACK = 2^oack;
    if ~srOnly
        tmpACK = dec2bin(0:nACK-1,oack) == '1';
    else
        tmpACK = false(1,0);
    end
    nSR = 2^osr;

    % Initialize matrix to store correlation results
    c = zeros([nSR nACK],dtType);

    % Reshape received symbols and calculate their energy once
    nRBSC = 12;
    symRB = reshape(sym,nRBSC,[]);
    eSymRB = sum(abs(symRB).^2);
    % Loop through all possible SR and ACK combinations to find the best match
    for srIdx = 1:nSR
        for ackIdx = 1:nACK
            % Generate the reference signal for the current UCI combination
            refSymTmp = nrPUCCH(carrier,pucch,{tmpACK(ackIdx,:)' srIdx-1},"OutputDataType",dtType);

            if ~isempty(refSymTmp) % Don't compute correlation for -SR only
                refSymRB = repmat(reshape(refSymTmp,nRBSC,[]),1,size(sym,2));
                eRefSymRB = sum(abs(refSymRB).^2);
                normE = sqrt(eSymRB.*eRefSymRB);
                % Get the mean of normalized correlation coefficients
                % across all antennas for these reference symbols. Add eps
                % to the normalization to avoid dividing by 0.
                c(srIdx,ackIdx) = mean(abs(sum(symRB.*conj(refSymRB)))./(normE+eps));
            end
        end
    end

    % Get the sequence cyclic shift based on ack and sr inputs    sr = [];
       CorrMatThr=c;%for first way
%    CorrMatThr = max(c(:))./c;%for second way
%   [rIdx,cIdx] = find(c == max(c(:)));%second way

    % Find the best correlation score (detection metric)
    detMet = max(CorrMatThr,[],'all');

    % Make a decision based on the detection threshold && max(c(:))>0.6
    if (detMet(1) >= thres )
        % If signal is detected, find the corresponding UCI bits
          [rIdx,cIdx] = find(CorrMatThr == detMet(1));%first way
        rxACK = tmpACK(cIdx(1),:)'; % Decoded ACK is from the best matching column
        if osr
            rxSR = (rIdx(1) == 2);  % Decoded SR is from the best matching row (row 2 means SR=1)
        else
            rxSR = false(0,1);
        end
    else
        % If signal is not detected (below threshold), return DTX
        rxACK = false(0,1);
        rxSR = false(srOnly,1);
    end

    % Assemble the final UCI bits
    uciBits = {cast(rxACK,outDtType) cast(rxSR,outDtType)};

    % --- End: Embedded decoding logic ---
end

% --- Final Output Formatting ---

% Ensure the output cell array format is consistent
if numOUCIElements == 1
    uciBits = {uciBits{1}};
end

% Assign empty symbols output, as Format 0 has no constellation symbols
symbols = zeros(0,1,class(sym));

% Ensure the detection metric output is always defined
if ~exist('detMet','var')
    detMet = 0;
end
end