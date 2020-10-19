%% set parameters
strDataMasterPath = 'F:\Data\Processed\ePhys\';
intMakePlots =0;
vecRandTypes = [1];%1=normal,2=rand
vecRestrictRange = [0 inf];
vecResamples = 100;
boolUseSubset = false;
intArea = 2;

%% set variables
cellUniqueAreas = {...
	'lateral geniculate',...Area 1
	'Primary visual',...Area 2
	'Lateral posterior nucleus',...Area 3
	'Anterior pretectal nucleus',...Area 4
	'Nucleus of the optic tract',...Area 5
	'Superior colliculus',...Area 6
	'Anteromedial visual',...Area 7
	'posteromedial visual',...Area 8
	'Anterolateral visual',...Area 9
	'Lateral visual',...Area 10
	};
cellRunStim = {'RunDriftingGratings','RunNaturalMovie'};
intRunStim = 1;
strRunStim = cellRunStim{intRunStim};
cellRepStr = {...
	'RunDriftingGratings','-DG';...
	'RunNaturalMovie','-NM';...
	'lateral geniculate','LGN';...
	'Primary visual','V1';...
	'Lateral posterior nucleus','LP';...
	'Anterior pretectal nucleus','APN';...
	'Nucleus of the optic tract','NOT';...
	'Superior colliculus','SC';...
	'Anteromedial visual','AM';...
	'posteromedial visual','PM';...
	'Anterolateral visual','AL';...
	'Lateral visual','L';...
	};

%% run
for intRandType=vecRandTypes
	%reset vars
	clearvars -except boolUseSubset vecTrialNum vecRestrictRange cellRepStr intRandType vecRandTypes intRunStim vecRunStim cellRunStim intArea vecRunAreas cellUniqueAreas boolSave vecResamples strDataMasterPath strDataTargetPath strFigPath intMakePlots vecRunTypes
	strArea = cellUniqueAreas{intArea};
	strRunStim = cellRunStim{intRunStim};
	
	if intRandType == 1
		strRunType = strArea;
		fprintf('Prepping normal... [%s]\n',getTime);
	elseif intRandType ==2
		strRunType = [strArea '-Rand'];
		fprintf('Prepping random... [%s]\n',getTime);
	end
	
	if boolUseSubset
		strRunType = ['Subset-' strRunType];
		fprintf('Note: Using only subset of trials!\n');
	end
	
	%% load data
	strName = replace([lower(strArea) strRunStim],lower(cellRepStr(:,1)),cellRepStr(:,2));
	[sAggStim,sAggNeuron]=loadDataNpx(strArea,strRunStim);
	cellRecIdx = {sAggStim.Rec};
	intNeurons = numel(sAggNeuron);
	
	
	for intResampleIdx = 1:numel(vecResamples)
		intResampleNum = vecResamples(intResampleIdx);
		%% message
		fprintf('Processing %s, resampling %d (%d/%d) [%s]\n',strRunType,intResampleNum,intResampleIdx,numel(vecResamples),getTime);
		hTic=tic;
		
		%% pre-allocate output variables
		vecNumSpikes = nan(1,intNeurons);
		vecZetaP = nan(1,intNeurons);
		vecZetaZ = nan(1,intNeurons);
		vecMeanD = nan(1,intNeurons);
		vecMeanP = nan(1,intNeurons);
		cellArea = cell(1,intNeurons);
			
		%% prep progress
		global intWaitbarTotal;
		intWaitbarTotal = intNeurons;
		ptrProgress = parallel.pool.DataQueue;
		afterEach(ptrProgress, @UpdateWaitbar);

		%% analyze
		parfor intNeuron=1:intNeurons
			%% progress
			send(ptrProgress, intNeuron);
			
			%% get neuronal data
			sThisNeuron = sAggNeuron(intNeuron);
			vecSpikeTimes = sThisNeuron.SpikeTimes;
			strRecIdx = sThisNeuron.Rec;
			strMouse = sThisNeuron.Mouse;
			strBlock = '';
			strArea = strName;
			strDate = sThisNeuron.Date;
			intSU = sThisNeuron.Cluster;
			intClust = sThisNeuron.IdxClust;
			
			%% get matching recording data
			sThisRec = sAggStim(strcmpi(strRecIdx,cellRecIdx));
			if isempty(sThisRec),continue;end
			vecStimOnTime = [];
			vecStimOffTime = [];
			if boolUseSubset
				intMaxRec = 1;
			else
				intMaxRec = numel(sThisRec.cellStim);
			end
			for intRec=1:intMaxRec
				vecStimOnTime = cat(2,vecStimOnTime,sThisRec.cellStim{intRec}.structEP.vecStimOnTime);
				vecStimOffTime = cat(2,vecStimOffTime,sThisRec.cellStim{intRec}.structEP.vecStimOffTime);
			end
			
			vecTrialStarts = [];
			vecTrialStarts(:,1) = vecStimOnTime;
			vecTrialStarts(:,2) = vecStimOffTime;
			
			%% get visual responsiveness
			%get trial dur
			dblUseMaxDur = round(median(diff(vecTrialStarts(:,1)))*2)/2;
			%set derivative params
			if contains(strRunType,'Rand')
				dblDur = dblUseMaxDur;
				vecJitter = 4*dblDur*rand([numel(vecTrialStarts(:,1)) 1])-dblDur*2;
				matEventTimes = bsxfun(@plus,vecTrialStarts,vecJitter);
			else
				matEventTimes = vecTrialStarts;
			end
			
			close;close;
			%run ZETA
			[dblZetaP,vecLatencies,sZETA] = getZeta(vecSpikeTimes,matEventTimes,dblUseMaxDur,intResampleNum,intMakePlots,2,vecRestrictRange);
			
			% assign data
			vecNumSpikes(intNeuron) = numel(vecSpikeTimes);
			vecZetaP(intNeuron) = dblZetaP;
			vecZetaZ(intNeuron) = sZETA.dblZETA;
			vecMeanD(intNeuron) = sZETA.dblMeanD;
			vecMeanP(intNeuron) = sZETA.dblMeanP;
			cellArea{intNeuron} = strArea;
		end
		
		%% plot
		figure;
		plot([0 1],[0 1],'k--');
		hold on;
		vecType = 1+((vecMeanP < 0.05) + 2*(vecZetaP < 0.05));
		if intRandType == 1
			matC = [0.5 0.5 0.5;...
				1 0 0;...
				0 1 0;...
				0 0 1];
		else
			matC = [0.5 0.5 0.5;...
				0 1 0;...
				1 0 0;...
				0 0 1];
		end
		for intType=1:4
			h=scatter(vecMeanP(vecType==intType),vecZetaP(vecType==intType),'x','CData',matC(intType,:));
		end
		hold off;
		ylabel('ZETA p-value');
		xlabel('t-test p-value');
		title(sprintf('%s; Inclusion: ZETA=%.1f%%, t-test=%.1f%%',strRunType,(sum(vecZetaP < 0.05)/numel(vecZetaP))*100,(sum(vecMeanP < 0.05)/numel(vecMeanP))*100));
	end
end