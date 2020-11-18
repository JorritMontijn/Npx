
%% select all neurons in LP and drifting grating stimuli
[sAggStim,sAggNeuron]=loadDataNpx('lateral posterior nucleus','driftinggrating');

%% get data for neuron #16 (original neuron #30)
intNeuronToAnalyze = 16;
sNeuron = sAggNeuron(intNeuronToAnalyze);
intOldClusterNumber = sNeuron.Cluster;
[structStim,vecSpikeCounts,vecPreSpikeCounts]=loadNeuronNpx(sAggStim,sNeuron);

%% get orientation data and make plot
vecStimOrientation = structStim.Orientation;
boolPlot = true;
sTuningCurve = getTuningCurves(vecSpikeCounts,vecStimOrientation,boolPlot);

%% all neurons in area
intTotN = numel(sAggNeuron);
intTotS = numel(unique(vecStimOrientation));
matMeanOverOriPerN = nan(intTotN,intTotS);
for intNeuron=1:intTotN
	sNeuron = sAggNeuron(intNeuron);
	if ~(sNeuron.KilosortGood || sNeuron.Contamination < 0.1)
		warning([mfilename ':WrongInclusion'],sprintf('Neuron %d is included but has bad metrics',intNeuron));
	end
	[structStim,vecSpikeCounts,vecPreSpikeCounts]=loadNeuronNpx(sAggStim,sNeuron);
	intT = structStim.intTrialNum;
	[matRespNSR,vecStimTypes,vecUniqueDegs] = getStimulusResponses(vecSpikeCounts(1:intT),structStim.Orientation(1:intT));
	matMeanOverOriPerN(intNeuron,:) = mean(matRespNSR,3);
end
indRem = any(isnan(matMeanOverOriPerN),2);
matMeanOverOriPerN(indRem,:) = [];
intTotN = size(matMeanOverOriPerN,1);

%% plot
errorbar(vecUniqueDegs,mean(matMeanOverOriPerN),std(matMeanOverOriPerN,[],1)/sqrt(intTotN))
xlabel('Stimulus orientation (degs)')
ylabel('Mean spiking rate (Hz)')
title(sprintf('Mean +/- SEM over neurons (N=%d)\n %s',intTotN,sNeuron.Area))
xlim([-5 365])
set(gca,'xtick',[0:45:360])
fixfig;
