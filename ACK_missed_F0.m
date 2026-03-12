clearvars;
% =========================================================================
% 1. Define Simulation Parameters
% =========================================================================
simParameters = struct;
simParameters.NFrames = 2500;
simParameters.SNRIn =0:12; % SNR range in dB
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
pucch.FrequencyHopping="intraslot";

% Specify the control information to be sent
ack = 1; % Transmit ACK
sr = [0]; % No SR
uci = {ack, sr};
ouci = [numel(ack), numel(sr)];

% --- Channel Settings ---
channel = nrTDLChannel;
channel.DelayProfile = 'TDL-C';
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
chInfo = info(channel);

% Matrix to store probability results
ackMissedDetectionProb = zeros(length(simParameters.SNRIn), length(thresholdValues));

fprintf('Starting ACK Missed Detection simulation...\n');

% =========================================================================
% 2. Start Main Simulation Loop
% =========================================================================
for thresIdx = 1:numel(thresholdValues)
    currentThreshold = thresholdValues(thresIdx);
    fprintf('... Simulating at threshold = %.2f dB ...\n', thresholdValues(thresIdx));

    for snrIdx = 1:numel(simParameters.SNRIn)
        SNRdB = simParameters.SNRIn(snrIdx);
        fprintf('... Simulating at SNR = %.2f dB ...\n', SNRdB);
        numAckMissedErrors = 0;



        % Reset channel and random generator for each simulation point
        rng('default');
        reset(channel);

        % Loop over each time slot
        for nslot = 0:nSlots-1
            carrier.NSlot = nslot;

            % --- Transmitter ---
            symbols = mynrPUCCH0(carrier, pucch, uci);
            pucchGrid = nrResourceGrid(carrier, simParameters.NTxAnts);
            [pucchIndices, ~] = nrPUCCHIndices(carrier, pucch);
            pucchGrid(pucchIndices) = symbols;

            txWaveform = nrOFDMModulate(carrier, pucchGrid);
            txWaveformChDelay = [txWaveform; zeros(chInfo.MaximumChannelDelay,size(txWaveform,2))];
            [rxWaveform,pathGains,sampleTimes] = channel(txWaveformChDelay);

            % --- Channel + Noise ---
            %            [rxWaveform_noNoise, ~] = channel(txWaveform);

            % Add AWGN noise
            SNR = 10^(SNRdB / 20);
            N0 = 1 / (sqrt(2.0 * simParameters.NRxAnts * nFFT) * SNR);
            noise = N0 * complex(randn(size(rxWaveform)), randn(size(rxWaveform)));
            rxWaveform = rxWaveform + noise;

            % --- Receiver ---
            rxGrid = nrOFDMDemodulate(carrier, rxWaveform);
            [K,L,R] = size(rxGrid);
            if (L < symbolsPerSlot)
                rxGrid = cat(2, rxGrid, zeros(K, symbolsPerSlot-L, R));
            end
            [pucchIndices, ~] = nrPUCCHIndices(carrier, pucch);
            [pucchRx, ~] = nrExtractResources(pucchIndices, rxGrid);

            % --- Decoding ---
            [decucibits, ~] = mynrPUCCHDecode(carrier, pucch, ouci, pucchRx, 'Threshold', currentThreshold);

            % --- Error Checking ---
            % ACK missed detection if no ACK detected or wrong ACK
            rxACK = decucibits{1};
            if (isempty(rxACK) || rxACK~=ack)
                numAckMissedErrors = numAckMissedErrors + 1;
            end
        end

        % Calculate and store the probability
        ackMissedDetectionProb(snrIdx, thresIdx) = numAckMissedErrors / (nSlots+1);
    end
end

fprintf('... Simulation finished.\n');

% =========================================================================
% 3. Display Results
% =========================================================================
figure;
semilogy(simParameters.SNRIn, ackMissedDetectionProb);
hold on;

% xline(3.4, '--r', 'SNR = 3.4 dB');
hold off; % الأمر لإيقاف الإضافة إلى الرسم البياني الحالي
xline(9.3, '--r', 'SNR = 9.3 dB');

legend('ACK missed', 'Location', 'southwest');
xlabel('SNR (dB)');
ylabel('ACK Missed Detection Probability');
title('PUCCH Format 0 Detection Performance (ACK Missed Detection)');
grid on;
ylim([1e-3 1]);
