
%% select all neurons in LP and drifting grating stimuli
[sAggStim,sAggNeuron]=loadDataNpx('lateral posterior','driftinggrating');

%% get data for neuron #16 (original neuron #30)
intNeuronToAnalyze = 16;
sNeuron = sAggNeuron(intNeuronToAnalyze);
intOldClusterNumber = sNeuron.Cluster;
[structStim,vecSpikeCounts,vecPreSpikeCounts]=loadNeuronNpx(sAggStim,sNeuron);

%% get orientation data and make plot
vecStimOrientation = structStim.Orientation;
boolPlot = true;
sTuningCurve = getTuningCurves(vecSpikeCounts,vecStimOrientation,boolPlot);
