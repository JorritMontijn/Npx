function  [structStim,vecSpikeCounts,vecPreSpikeCounts]=loadNeuronNpx(sAggStim,sNeuron,dblPreStimBaselineSecs)
	%loadNeuronNpx Load data for single neuron
	%   [structStim,vecSpikeCounts,vecPreSpikeCounts]=loadNeuronNpx(sAggStim,sNeuron,dblPreStimBaselineSecs)
	
	%% check inputs
	if ~exist('dblPreStimBaselineSecs','var') || isempty(dblPreStimBaselineSecs)
		dblPreStimBaselineSecs = 0;
	end
	
	%% get matching recording data
	sThisRec = sAggStim(strcmpi(sNeuron.Rec,{sAggStim(:).Rec}));
	
	%% concatenate stimulus structures
	structStim = catstim(sThisRec.cellStim);
	if nargout < 2,return;end
	
	%% get spike times
	vecSpikeTimes = sNeuron.SpikeTimes;
	vecStimOnTime = structStim.vecStimOnTime;
	vecStimOffTime = structStim.vecStimOffTime;
	
	vecSpikeCounts = getSpikeCounts(vecSpikeTimes,vecStimOnTime,vecStimOffTime);
	vecPreSpikeCounts = zeros(size(vecSpikeCounts));
	if nargout > 2
		if dblPreStimBaselineSecs == 0
			%calculate median ITI
			dblPreStimBaselineSecs = min(vecStimOnTime(2:end) - vecStimOffTime(1:(end-1)));
		end
		
		vecPreSpikeCounts = getSpikeCounts(vecSpikeTimes,vecStimOnTime-dblPreStimBaselineSecs,vecStimOnTime);
	end
end

