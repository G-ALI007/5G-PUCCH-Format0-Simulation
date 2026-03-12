function sym = mynrPUCCH0(carrier,pucch,uciBits,varargin)

    % Ensure UCI bits are in a cell array for consistent processing.
    if iscell(uciBits)
        uciBitsCell = uciBits;
    else
        uciBitsCell = {uciBits};
    end
    
    % Determine the intra-slot frequency hopping configuration.
    if strcmpi(pucch.FrequencyHopping,'intraSlot')
        intraSlotfreqHopping = 'enabled';
    else
        intraSlotfreqHopping = 'disabled';
    end
    
    % Get the scrambling identity (NID), defaulting to NCellID if HoppingID is not provided.
    if isempty(pucch.HoppingID)
        nid = double(carrier.NCellID);
    else
        nid = double(pucch.HoppingID(1));
    end
    
    % Calculate the relative slot number within a frame.
    nslot = mod(double(carrier.NSlot),carrier.SlotsPerFrame);
    
    % Return an empty sequence if no resources are allocated or no UCI data is provided.
    if isempty(pucch.SymbolAllocation) || (pucch.SymbolAllocation(2) == 0) ...
            || isempty(pucch.PRBSet) || isempty(uciBits)
        seq = zeros(0,1);
    else
        % Separate the UCI cell array into ACK and SR bits.
        switch numel(uciBitsCell)
            case 1
                % Only one cell, treat it as ACK bits.
                ack = uciBitsCell{1};
                sr = zeros(0,1);
            otherwise
                % First cell is ACK bits, second cell is SR bit.
                ack = uciBitsCell{1};
                sr = double(uciBitsCell{2});
        end
        
        % Call the underlying function to generate the PUCCH format 0 symbols.
        % Note: This assumes a function 'nrPUCCH0' exists on the path.
        seq = nrPUCCH0(logical(ack(:)),logical(sr),pucch.SymbolAllocation,...
            carrier.CyclicPrefix,nslot,nid,pucch.GroupHopping,...
            pucch.InitialCyclicShift,intraSlotfreqHopping);
    end
    
    % Handle optional arguments for output data type.
    if nargin > 3
        fcnName = 'nrPUCCH';
        opts = coder.const(nr5g.internal.parseOptions(fcnName,...
            {'OutputDataType'},varargin{:}));
        sym = cast(seq,opts.OutputDataType);
    else
        sym = seq;
    end
end