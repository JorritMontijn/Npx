function [structStim] = catstim(cellStimCell)
	%catstim Concatatenates stimulus fields
	%   [structStim] = catstim(cellStimCell)
	
	structStim= cellStimCell{1};
	intRecs = numel(cellStimCell);
	for intRec=2:intRecs
		intStimNr = cellStimCell{intRec}.intStimNumber;
		cellFields= fieldnames(cellStimCell{intRec});
		vecSize = structfun(@numel,cellStimCell{intRec});
		vecCatFields = find(vecSize==intStimNr);
		for intField=vecCatFields(:)'
			strField = cellFields{intField};
			if isfield(structStim,strField) && isfield(cellStimCell{intRec},strField)
				structStim.(strField) = cat(2,flat(structStim.(strField))',flat(cellStimCell{intRec}.(strField))');
			end
		end
	end
end	
