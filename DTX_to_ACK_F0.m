clearvars;
% =========================================================================
% 1. Define Simulation Parameters
% =========================================================================
simParameters = struct;
simParameters.NFrames = 3000;
simParameters.SNRIn = 10; % SNR range in dB
simParameters.NTxAnts = 1;
simParameters.NRxAnts = 2;
% Threshold values to be tested
thresholdValues = 0.55;

% --- Transmitter Settings ---
% Carrier settings
carrier = nrCarrierConfig;
carrier.NCellID = 2;
carrier.SubcarrierSpacing = 15;
carrier.NSizeGrid = 25;
% PUCCH Format 0 settings
pucch = nrPUCCH0Config;
pucch.PRBSet = 0;
pucch.SymbolAllocation = [13 1]; % Allocate two symbols for PUCCH
pucch.InitialCyclicShift = 0;
pucch.FrequencyHopping="intraSlot";
pucch.SecondHopStartPRB=0;
% Specify the control information expected at the receiver (for decoding purposes)
% Assume the receiver expects one ACK bit
ack_expected = 1;
sr_expected = 0;
ouci = [numel(ack_expected), numel(sr_expected)];
% --- Channel Settings ---
channel = nrTDLChannel;
channel.DelayProfile = 'TDL-C';
channel.DelaySpread = 300e-9;
channel.MaximumDopplerShift = 100;
channel.MIMOCorrelation = 'Low';
channel.TransmissionDirection = 'Uplink';
channel.NumTransmitAntennas = simParameters.NTxAnts;
channel.NumReceiveAntennas = simParameters.NRxAnts;
channel.NormalizeChannelOutputs = 0;

% --- Simulation Setup ---
waveformInfo = nrOFDMInfo(carrier);
slotsPerFrame = carrier.SlotsPerFrame;
nFrames = simParameters.NFrames;
channel.SampleRate = waveformInfo.SampleRate;
nSlots = simParameters.NFrames * carrier.SlotsPerFrame;
nFFT = waveformInfo.Nfft;
symbolsPerSlot = carrier.SymbolsPerSlot;
% Matrix to store probability results
dtxToAckProb = zeros(length(simParameters.SNRIn), length(thresholdValues));
fprintf('Starting DTX to ACK Probability simulation...\n');
chInfo = info(channel);
nTxAnts = simParameters.NTxAnts;
nRxAnts = simParameters.NRxAnts;
% =========================================================================
% 2. Start Main Simulation Loop
% =========================================================================
for thresIdx = 1:numel(thresholdValues)

    currentThreshold = thresholdValues(thresIdx);
    fprintf('... Simulating at threshold = %.2f dB ...\n', thresholdValues(thresIdx));

    for snrIdx = 1:numel(simParameters.SNRIn)

        SNRdB = simParameters.SNRIn(snrIdx);
        fprintf('... Simulating at SNR = %.2f dB ...\n', SNRdB);
        offset = 0;
        % Reset channel and random generator for each simulation point
        rng('default');
        reset(channel);




        numDtxToAckErrors = 0;

        % Loop over each time slot
        for nslot = 0:nSlots-1
            carrier.NSlot = nslot;

            % --- Transmitter (DTX case) ---
            % In the DTX case, no symbols are transmitted.
            % We create an empty resource grid (all zeros).
            pucchGrid = nrResourceGrid(carrier, simParameters.NTxAnts);

            % We do not generate or map PUCCH symbols, because we are simulating DTX.

            % OFDM modulation of an empty grid results in a zero-energy waveform
            txWaveform = nrOFDMModulate(carrier, pucchGrid);
            txWaveformChDelay = [txWaveform; zeros(chInfo.MaximumChannelDelay,size(txWaveform,2))];
            % --- Channel + Noise ---
            % Pass the zero waveform through the channel (it will remain zero)
            %             [rxWaveform_noNoise, ~] = channel(txWaveform);
            [rxWaveform,pathGains,sampleTimes] = channel(txWaveformChDelay);

            % Add Additive White Gaussian Noise (AWGN)
            SNR = 10^(SNRdB / 20); % Convert from dB to linear magnitude
            N0 = 1 / (sqrt(2.0 * simParameters.NRxAnts * nFFT) * SNR);
            noise = N0 * complex(randn(size(rxWaveform)), randn(size(rxWaveform)));
            rxWaveform = rxWaveform + noise;
            [pucchIndices, ~] = nrPUCCHIndices(carrier, pucch);
            rxGrid = nrOFDMDemodulate(carrier, rxWaveform);

            [pucchRx, ~] = nrExtractResources(pucchIndices, rxGrid);

            % --- Decoding ---
            % Decode the received symbols using the current threshold
            [decucibits, ~] = mynrPUCCHDecode(carrier, pucch, ouci, pucchRx, 'Threshold', currentThreshold);

            % --- Error Checking ---
            % A DTX-to-ACK error occurs if any ACK bit is detected
            rxACK = decucibits{1};
            if ~isempty(rxACK)
                numDtxToAckErrors = numDtxToAckErrors + 1;

            end

        end

        % Calculate and store the probability
        dtxToAckProb(snrIdx, thresIdx) = numDtxToAckErrors / (nSlots+1);
    end
end
fprintf('... Simulation finished.\n');
% =========================================================================
% 3. Display Results
% =========================================================================
semilogy(simParameters.SNRIn, dtxToAckProb);
hold on

ylabel('Probability');
xlabel('SNR(dB)');
title('PUCCH Format 0 Detection Performance (DTX to ACK)');
grid on;
legend('1 receiver', '2 receiver', 'Location', 'northeast');

ylim([1e-3 1]);
