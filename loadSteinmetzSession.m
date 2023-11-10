function sAP = loadSteinmetzSession(strSesPath)
	% function to load a session of the Steinmetz Neuropixels dataset
	% Author: Michael G. Moore, Michigan State University,
	%  - Modified by NS 2020-03-09, with some dataset-specific enhancements
	%  - Modified by Jorrit Montijn 2023-11-07, returns pseudo-Acquipix format
	% Version:  V3 2023-11-07
	
	% strSesPath   is the directory name of the session, including any required
	%           path information
	
	% sAP         a data structure containing all the session variables
	
	% assumptions:
	%   - the data files for a session are in a unique folder.
	%   - all .npy and .tsv files in the folder are part of the data
	%   - file names indicate a structural hierarchy of the data via the '.'
	%   - matlab knows the path to the npy-matlab-master package
	
	fprintf(' Loading %s [%s]\n',strSesPath,getTime);
	
	sRaw = struct;
	sRaw.sesPath = strSesPath;
	
	% get session name
	temp = strsplit(strSesPath,filesep);
	sRaw.sesName = temp{end};
	
	% list all files and info
	fdir = dir(strSesPath);
	fdir = fdir(3:end); % remove '.' and '..' from the file-list
	
	sRaw.fileList = fdir; % add the file-list to the dataset structure as a record
	
	% examine each file and either read it into Matlab or ignore it
	for f = 1:length(fdir)
		% check if file or subdirectory (ignore subdirectories)
		if fdir(f).isdir
			continue
		end
		% separate file type and data structure fields
		temp = strsplit(fdir(f).name,'.');
		ftype = temp{end};
		fields = temp(1:(end-1));
		% keep only .npy and .tsv files
		if ~isequal(ftype,'npy') && ~isequal(ftype,'tsv')
			continue
		end
		% check fields for valid names
		for m = 1:length(fields)
			% Modify the names so that they are valid Matlab variable names
			%   if first character is not a letter, will prefix an "x"
			%   whitespace will be deleted
			%   whitespace followed by a letter will be replaced by the capitalized letter
			%   invalid characters will be replaced by underscore
			fields{m} = matlab.lang.makeValidName(fields{m});
		end
		% read the .npy and .tsv files
		if isequal(ftype,'npy')
			val = readNPY([strSesPath filesep fdir(f).name]);
		elseif isequal(ftype,'tsv')
			val = tdfread([strSesPath filesep fdir(f).name]);
		end
		% create a field of S using fields and val
		sRaw = setfield(sRaw,fields{1:end},val);
		
	end
	
	
	% acronyms for each channel
	acrPerChannel = arrayfun(@(x)sRaw.channels.brainLocation.allen_ontology(x,:), 1:size(sRaw.channels.brainLocation.allen_ontology,1), 'uni', false);
	acrPerChannel = cellfun(@(x)x(1:iff(any(x==' '), find(x==' ',1)-1, numel(x))), acrPerChannel, 'uni', false);
	sRaw.channels.acronym = acrPerChannel';
	
	%% transform data
	%other data
	strRec = sRaw.sesName;
	strExp = 'SteinmetzNpx';
	cellSplit=strsplit(strRec,'_');
	strSubject = cellSplit{1};
	strDate = cellSplit{2};
	
	%behavior
	lickTimes = sRaw.licks.times;
	
	contrastLeft = sRaw.trials.visualStim_contrastLeft;
	contrastRight = sRaw.trials.visualStim_contrastRight;
	feedback = sRaw.trials.feedbackType;
	choice = sRaw.trials.response_choice;
	choice(choice==0) = 3; choice(choice==1) = 2; choice(choice==-1) = 1;
	
	cweA = table(contrastLeft, contrastRight, feedback, choice);
	
	stimOn = sRaw.trials.visualStim_times;
	beeps = sRaw.trials.goCue_times;
	feedbackTime = sRaw.trials.feedback_times;
	
	cwtA = table(stimOn, beeps, feedbackTime);
	
	moveData = struct();
	moveData.moveOnsets = sRaw.wheelMoves.intervals(:,1);
	moveData.moveOffsets = sRaw.wheelMoves.intervals(:,2);
	moveData.moveType = sRaw.wheelMoves.type;
	
	%% assign behavior data
	sBehaviour = struct;
	sBehaviour.vecLickTimes = sRaw.licks.times;
	sBehaviour.vecMoveTimesOn = moveData.moveOnsets;
	sBehaviour.vecMoveTimesOff = moveData.moveOffsets;
	sBehaviour.vecMoveType = moveData.moveType;
	sBehaviour.eye = sRaw.eye;
	sBehaviour.face = sRaw.face;
	
	%% assign stim/performance data
	indLeftTrials = cweA.contrastLeft > cweA.contrastRight;
	indRightTrials = cweA.contrastLeft < cweA.contrastRight;
	indEqualTrials = cweA.contrastLeft == cweA.contrastRight;
	indCorrect = (cweA.choice==2 & indLeftTrials) | (cweA.choice==1 & indRightTrials) | (cweA.choice==3 & indEqualTrials);
	
	vecTrialType = indLeftTrials+indRightTrials*2+indEqualTrials*3+indCorrect*3; %1-3=wrong,4-6=correct
	
	sStim=struct;
	sStim.vecStimOnTime = sRaw.trials.visualStim_times;
	sStim.vecStimOffTime = sRaw.trials.intervals(:,2);
	sStim.vecGoCueTime = sRaw.trials.goCue_times;
	sStim.vecResponseTime = sRaw.trials.response_times;
	sStim.vecFeedbackTime = sRaw.trials.feedback_times;
	sStim.vecContrastLeft = cweA.contrastLeft;
	sStim.vecContrastRight = cweA.contrastRight;
	sStim.vecChoice = cweA.choice;
	sStim.indCorrect = indCorrect;
	sStim.indIncluded = sRaw.trials.included;
	sStim.vecTrialType = vecTrialType;
	sStim.sSource = sRaw.trials;
	
	%% ephys
	vecProbes = unique(sRaw.clusters.probes);
	intTotClustNum = numel(sRaw.clusters.probes);
	
	sCluster = struct;
	%assign to object
	intClustEntry = 0;
	sCluster(intTotClustNum).Depth = nan;%depth on probe
	sCluster(intTotClustNum).Area = '';
	sCluster(intTotClustNum).DepthBelowIntersect = nan;%depth in brain
	sCluster(intTotClustNum).Exp = strExp;
	sCluster(intTotClustNum).Rec = strRec;
	sCluster(intTotClustNum).SubjectType = 'BL6';
	sCluster(intTotClustNum).Subject = strSubject;
	sCluster(intTotClustNum).Date = strDate;
	sCluster(intTotClustNum).Probe = nan;
	sCluster(intTotClustNum).Cluster = nan;
	sCluster(intTotClustNum).IdxClust = nan;
	sCluster(intTotClustNum).SpikeTimes = [];
	sCluster(intTotClustNum).Waveform = [];
	sCluster(intTotClustNum).NonStationarity = nan;
	sCluster(intTotClustNum).Violations1ms = nan;
	sCluster(intTotClustNum).Violations2ms = nan;
	sCluster(intTotClustNum).Contamination = nan;
	
	intPrevProbeCh = 0;
	for intProbeIdx=1:numel(vecProbes)
		intProbe = vecProbes(intProbeIdx);
		
		%cluster data
		indIncludeClusts = sRaw.clusters.probes==intProbe;
		vecClustIDs = find(indIncludeClusts)-1;
		intClustNum = numel(vecClustIDs);
		indIncludeSpikes = ismember(sRaw.spikes.clusters, vecClustIDs);
		vecClustPeakCh = sRaw.clusters.peakChannel(indIncludeClusts)-intPrevProbeCh;
		intPrevProbeCh = intPrevProbeCh + sum(sRaw.channels.probe==intProbe);
		indClustGood = sRaw.clusters.x_phy_annotation(indIncludeClusts)>=2;
		vecClustDepth = sRaw.clusters.depths(indIncludeClusts);
		
		% anatData - a struct with:
		%   - coords - [nCh 2] coordinates of sites on the probe
		%   - wfLoc - [nClu nCh] size of the neuron on each channel
		%   - borders - table containing upperBorder, lowerBorder, acronym
		%   - clusterIDs - an ordering of clusterIDs that you like
		%   - waveforms - [nClu nCh nTimepoints] waveforms of the neurons
		anatData = struct();
		coords = sRaw.channels.sitePositions(sRaw.channels.probe==intProbe,:);
		anatData.coords = coords;
		
		temps = sRaw.clusters.templateWaveforms(vecClustIDs+1,:,:);
		tempIdx = sRaw.clusters.templateWaveformChans(vecClustIDs+1,:);
		wfs = zeros(numel(vecClustIDs), size(coords,1), size(temps,2));
		for q = 1:size(wfs,1); wfs(q,tempIdx(q,:)+1,:) = squeeze(temps(q,:,:))'; end
		anatData.wfLoc = max(wfs,[],3)-min(wfs,[],3);
		anatData.waveforms = wfs;
		
		acr = sRaw.channels.brainLocation.allen_ontology(sRaw.channels.probe==intProbe,:);
		lowerBorder = 0; upperBorder = []; acronym = {acr(1,:)};
		for q = 2:size(acr,1)
			if ~strcmp(acr(q,:), acronym{end})
				upperBorder(end+1) = coords(q,2);
				lowerBorder(end+1) = coords(q,2);
				acronym{end+1} = acr(q,:);
			end
		end
		upperBorder(end+1) = max(coords(:,2));
		upperBorder = upperBorder'; lowerBorder = lowerBorder'; acronym = acronym';
		anatData.borders = table(upperBorder, lowerBorder, acronym);
		
		pkCh = sRaw.clusters.peakChannel(sRaw.clusters.probes==intProbe);
		[~,ii] = sort(pkCh);
		anatData.clusterIDs = vecClustIDs(ii);
		anatData.wfLoc = anatData.wfLoc(ii,:);
		anatData.waveforms = anatData.waveforms(ii,:,:);
		
		%spikes
		vecSpikeTimesAll = sRaw.spikes.times(indIncludeSpikes);
		vecClustIDofSpikes = sRaw.spikes.clusters(indIncludeSpikes);
		
		%transform spikes to cell arrays
		tLocs = anatData.borders;
		[vecClusts,vecCounts,vecIndices]=unique(vecClustIDofSpikes);
		
		%% assign cluster data of this probe
		hTic=tic;
		for intCluster=1:intClustNum
			%%
			%check if good, skip otherwise
			sCluster(intCluster).KilosortGood = indClustGood(intCluster);
			%if ~indClustGood(intCluster),continue;end
			if toc(hTic)>5
				fprintf('   %s, probe %d: %d/%d [%s]\n',strRec,intProbe,intCluster,intClustNum,getTime);
				hTic=tic;
			end
			
			%get data
			intClustID = vecClustIDs(intCluster);
			vecSpikeTimes = vecSpikeTimesAll(vecClustIDofSpikes==intClustID);
			dblDepth = vecClustDepth(intCluster);
			strArea = tLocs.acronym{dblDepth < tLocs.upperBorder & dblDepth >= tLocs.lowerBorder};
			intPeakCh = vecClustPeakCh(intCluster);
			
			%get waveform data
			intWfId = find(anatData.clusterIDs ==intClustID);
			vecWaveform = squeeze(anatData.waveforms(intWfId,intPeakCh,:));
			
			%get cluster quality
			sOut = getClusterQuality(vecSpikeTimes,0);
			
			%assign to object
			intClustEntry = intClustEntry + 1;
			sCluster(intClustEntry).Depth = dblDepth;%depth on probe
			sCluster(intClustEntry).Area = strArea;
			sCluster(intClustEntry).DepthBelowIntersect = nan;%depth in brain
			
			sCluster(intClustEntry).Exp = strExp;
			sCluster(intClustEntry).Rec = strRec;
			sCluster(intClustEntry).SubjectType = 'BL6';
			sCluster(intClustEntry).Subject = strSubject;
			sCluster(intClustEntry).Date = strDate;
			sCluster(intClustEntry).Probe = intProbe;
			sCluster(intClustEntry).Cluster = intCluster;
			sCluster(intClustEntry).IdxClust = intClustID;
			sCluster(intClustEntry).SpikeTimes = vecSpikeTimes;
			sCluster(intClustEntry).Waveform = vecWaveform;
			sCluster(intClustEntry).NonStationarity = sOut.dblNonstationarityIndex;
			sCluster(intClustEntry).Violations1ms = sOut.dblViolIdx1ms;
			sCluster(intClustEntry).Violations2ms = sOut.dblViolIdx2ms;
			sCluster(intClustEntry).Contamination = nan;
		end
	end
	
	%% make pseudo-AP data
	sAP = struct;
	sAP.Exp = strExp;
	sAP.Rec = strRec;
	sAP.Source = strSesPath;
	sAP.sBehaviour = sBehaviour;
	sAP.sStim = sStim;
	sAP.sCluster = sCluster;
end
