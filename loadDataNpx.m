function [sAggStim,sAggNeuron]=loadDataNpx(strArea,strRunStim,strDataSourcePath)
%loadDataNpx Loads neuropixels data for requested area/stimulus combination
	%   [sAggStim,sAggNeuron]=loadDataNpx(strArea,strRunStim,strDataSourcePath)
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
	%sAggStim contains the fields .cellBlock and .Exp; cellBlock contains
	%stimulus variables
	%
	%sAggNeuron contains several fields with information on the neuron,
	%including the source recording (.Rec) and spike times (.SpikeTimes)
	%
	%	By Jorrit Montijn (Heimel lab), 14-10-20 (dd-mm-yy; NIN-KNAW)
	
	%% find data
	if ~exist('strDataSourcePath','var') || isempty(strDataSourcePath)
		strDataSourcePath = 'F:\Data\Processed\Neuropixels\';
	end
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
		cellClustAreas = {sAP.sCluster(:).Area};
		intNewFile = 1;
		%check if neuron is in target area
		for intClust=1:numel(sAP.sCluster)
			strClustArea = cellClustAreas{intClust};
			%KiloSort's "good" classification mainly depends on the contamination being lower than 0.1, so these inclusion
			%criteria should be very similar. For cells with low spike numbers, however, the contamination can be low while 
			%the "good" classification is set to 0; that's why we use either here
			if ~isempty(strClustArea) && contains(strClustArea,strArea,'IgnoreCase',true) && (sAP.sCluster(intClust).KilosortGood || sAP.sCluster(intClust).Contamination < 0.1)
				%% aggregate data
				%check if stim type is present
				indUseStims = contains(cellfun(@(x) x.strExpType,sAP.cellBlock,'uniformoutput',false),strRunStim,'IgnoreCase',true);
				if isempty(indUseStims) || ~any(indUseStims)
					continue;
				end
				%add data
				if intNeurons == 0
					intNewFile = 0;
					sAggNeuron(1) = sAP.sCluster(intClust);
					sAggStim(1).cellBlock = sAP.cellBlock(indUseStims);
					sAggStim(1).Exp = sAggNeuron(end).Exp;
				elseif ~isempty(indUseStims) && any(indUseStims)
					sAggNeuron(end+1) = sAP.sCluster(intClust);
				end
				if intNewFile
					sAggStim(end+1).cellBlock = sAP.cellBlock(indUseStims);
					sAggStim(end).Exp = sAggNeuron(end).Exp;
					intNewFile = 0;
				end
				intNeurons = intNeurons + 1;
			end
		end
	end
	if ~exist('sAggStim','var')
		return;
	end
	
	cellExpIdx = {sAggStim.Exp};
	fprintf('Found %d cells from %d recordings in "%s" [%s]\n',intNeurons,numel(cellExpIdx),strArea,getTime);
end