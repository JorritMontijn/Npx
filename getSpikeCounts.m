function matSpikeCounts = getSpikeCounts(varData,vecStart,vecStop)
	%getSpikeCounts Returns spike counts of time-stamped spike data
	%   Syntax: matSpikeCounts = getSpikeCounts(varData,vecStart,vecStop)
	%
	%varData can be vector of single neuron with time-stamps or cell-array
	%of multiple neurons [1 x N] with time-stamped spike vectors
	%
	%vecStart is [1 x S] vector containing epoch starts
	%
	%vecStop can be a [1 x S] vector containing epoch stops, or can be a
	%scalar [1 x 1], in which case it is the duration of all epochs
	%
	%output is [N x S] matrix of spike counts
	
	
	%get timing data
	intEpochs = length(vecStart);
	if isscalar(vecStop)
		vecStop = vecStart + vecStop;
	end
	hTic = tic;
	
	%check if input is cell array or vector
	if iscell(varData)
		%pre-allocate output
		intNumN = length(varData);
		matSpikeCounts = zeros(intNumN,intEpochs);
		
		vecBins = sort(cat(1,vecStart(1)-1,vecStart(:),vecStop(:),vecStop(end)+1));
		for intN=1:intNumN
			vecSpikes = histcounts(varData{intN},vecBins);
			matSpikeCounts(intN,:) = vecSpikes(2:2:end);
		end
	else
		%data is single neuron
		vecTimestamps = varData;
		intSpikes = length(vecTimestamps);
		%pre-allocate output
		matSpikeCounts = zeros(1,intEpochs);
		if intSpikes == 0
			%if no spikes, skip counting
			matSpikeCounts=zeros(1,intEpochs);
		else
			%vectorization is MUCH slower than loop
			%matSpikes = repmat(vecTimestamps',[1 intEpochs]);
			%matSpikeCounts(intNeuron,:) = sum(matSpikes >= repmat(vecStart,[intSpikes 1]) & matSpikes < repmat(vecStop,[intSpikes 1]),1);
			
			%ah yes, good old loops...
			for intSpike=1:intSpikes
				intBinBeforeEnd = find(vecTimestamps(intSpike) < vecStop,1,'first');
				intBinAfterStart = find(vecTimestamps(intSpike) > vecStart,1,'last');
				if ~isempty(intBinBeforeEnd) && ~isempty(intBinAfterStart) && intBinBeforeEnd == intBinAfterStart
					matSpikeCounts(1,intBinBeforeEnd) = matSpikeCounts(1,intBinBeforeEnd) + 1;
				end
			end
		end
	end
end

