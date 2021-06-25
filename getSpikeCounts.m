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
		vecBins = sort(cat(1,vecStart(1)-1,vecStart(:),vecStop(:),vecStop(end)+1));
		vecSpikes = histcounts(vecTimestamps,vecBins);
		matSpikeCounts = vecSpikes(2:2:end);
	end
end

