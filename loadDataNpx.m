function loadDataNpx

%% find data
	strDataSourcePath = 'D:\Data\Processed\Neuropixels\';
	sFiles = dir([strDataSourcePath '*.mat']);
	cellFiles = {sFiles(:).name}';
	strName = replace([lower(strArea) strRunStim],lower(cellRepStr(:,1)),cellRepStr(:,2));
	
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
		continue;
	end
	
	cellRecIdx = {sAggStim.Rec};
	fprintf('Found %d cells from %d recordings in "%s" [%s]\n',intNeurons,numel(cellRecIdx),strRunType,getTime);
	