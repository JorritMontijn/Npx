function [structStim] = catstim(cellStimCell)
	%catstim Concatatenates stimulus fields
	%   [structStim] = catstim(cellStimCell)
	
	structStim= cellStimCell{1}.structEP;
	intRecs = numel(cellStimCell);
	for intRec=2:intRecs
		intStimNr = cellStimCell{intRec}.structEP.intStimNumber;
		cellFields= fieldnames(cellStimCell{intRec}.structEP);
		vecSize = structfun(@numel,cellStimCell{intRec}.structEP);
		vecCatFields = find(vecSize==intStimNr);
		for intField=vecCatFields(:)'
			strField = cellFields{intField};
			structStim.(strField) = cat(2,flat(structStim.(strField))',flat(cellStimCell{intRec}.structEP.(strField))');
		end
	end
end	
