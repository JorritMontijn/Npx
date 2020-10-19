function [sAggStim,sAggNeuron]=loadDataNpx(strArea,strRunStim)
%loadDataNpx Loads neuropixels data for requested area/stimulus combination
	%   [sAggStim,sAggNeuron]=loadDataNpx(strArea,strRunStim)
	%
	%Inputs:
	% - strArea; name of area, e.g. 'Primary visual', 'Lateral posterior nucleus', etc
	% - strRunStim; name of stimulus, e.g. 'RunDriftingGratings'
	%
	%Outputs:
	%sAggStim; [1 x S] structure for each recording corresponding to your query
	%sAggNeuron; [1 x N] structure for each neuron corresponding to your query
	%
	%Notes:
	%sAggStim contains the fields .cellStim and .Rec; cellStim contains
	%recording metadata in cellStim{i}.sParamsSGL and stimulus variables in
	%cellStim{i}.structEP
	%
	%sAggNeuron contains several fields with information on the neuron,
	%including the source recording (.Rec) and spike times (.SpikeTimes)
	%
	%	By Jorrit Montijn (Heimel lab), 14-10-20 (dd-mm-yy; NIN-KNAW)
	
	%% find data
	strDataSourcePath = 'D:\Data\Processed\Neuropixels\';
	if exist(strDataSourcePath,'dir') == 0
		fprintf('Cannot find default path "%s"\n',strDataSourcePath);
		strDataSourcePath = input('Please enter path to .mat data files:\n  ','s');
	end
	sFiles = dir([strDataSourcePath '*.mat']);
	cellFiles = {sFiles(:).name}';
	
	%% go through files
	clear sAggStim;
	clear sAggNeuron;
	intNeurons = 0;
	for intFile=1:numel(cellFiles)
		%% load
		fprintf('Loading %s [%s]\n',cellFiles{intFile},getTime);
		sLoad = load([strDataSourcePath cellFiles{intFile}]);
		sAP = sLoad.sAP;
		intNewFile = 1;
		%check if neuron is in target area
		for intClust=1:numel(sAP.sCluster)
			strClustArea = sAP.sCluster(intClust).Area;
			%KiloSort's "good" classification mainly depends on the contamination being lower than 0.1, so these inclusion
			%criteria should be very similar. For cells with low spike numbers, however, the contamination can be low while 
			%the "good" classification is set to 0; that's why we use either here
			if ~isempty(strClustArea) && contains(strClustArea,strArea,'IgnoreCase',true) && (sAP.sCluster(intClust).KilosortGood || sAP.sCluster(intClust).Contamination < 0.1)
				%% aggregate data
				%check if stim type is present
				indUseStims = ismember(cellfun(@(x) x.structEP.strFile,sAP.cellStim,'uniformoutput',false),strRunStim);
				if isempty(indUseStims) || ~any(indUseStims)
					continue;
				end
				%add data
				if intNeurons == 0
					intNewFile = 0;
					sAggNeuron(1) = sAP.sCluster(intClust);
					sAggStim(1).cellStim = sAP.cellStim(indUseStims);
					sAggStim(1).Rec = sAggNeuron(end).Rec;
				elseif ~isempty(indUseStims) && any(indUseStims)
					sAggNeuron(end+1) = sAP.sCluster(intClust);
				end
				if intNewFile
					sAggStim(end+1).cellStim = sAP.cellStim(indUseStims);
					sAggStim(end).Rec = sAggNeuron(end).Rec;
					intNewFile = 0;
				end
				intNeurons = intNeurons + 1;
			end
		end
	end
	if ~exist('sAggStim','var')
		return;
	end
	
	cellRecIdx = {sAggStim.Rec};
	fprintf('Found %d cells from %d recordings in "%s" [%s]\n',intNeurons,numel(cellRecIdx),strArea,getTime);
end