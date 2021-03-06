function appendNexWaveforms( fileName, waveIdx, numSamplesWritten, wf )
%
% usage: appendNexWaveforms( fileName, waveIdx, numSamplesWritten, wf )
%
% INPUTS:
%   fileName - name of the .nex file
%   waveIdx - index of the waveform variable to write into the file
%   numSamplesWritten - number of samples already written for each waveform
%       to the .nex file
%   wf - the waveforms to write in an m x n matrix, where m is the number
%       of points in each waveform and n is the number of waveforms. These
%       should be supplied as int16's, NOT as mV. Assume that the original
%       recording used a reasonable amount of the A to D range.

% read in the .nex header so we can figure out where in the file to write
% the waveforms

nexFile = [];

if isempty(wf); return; end;

fid = fopen(fileName, 'r+');
if (fid == -1)
   error 'Unable to open file'
end

magic = fread(fid, 1, 'int32');
if magic ~= 827868494
    error 'The file is not a valid .nex file'
end
nexFile.version = fread(fid, 1, 'int32');
nexFile.comment = deblank(char(fread(fid, 256, 'char')'));
nexFile.freq = fread(fid, 1, 'double');
nexFile.tbeg = fread(fid, 1, 'int32')./nexFile.freq;
nexFile.tend = fread(fid, 1, 'int32')./nexFile.freq;
nvar = fread(fid, 1, 'int32');

% skip location of next header and padding
fseek(fid, 260, 'cof');

neuronCount = 0;
eventCount = 0;
intervalCount = 0;
waveCount = 0;
popCount = 0;
contCount = 0;
markerCount = 0;

% figure out which variables are waveforms
for i=1:nvar
    type = fread(fid, 1, 'int32');
    varVersion = fread(fid, 1, 'int32');
	name = deblank(char(fread(fid, 64, 'char')'));
    offset = fread(fid, 1, 'int32');
	n(i) = fread(fid, 1, 'int32');
    wireNumber = fread(fid, 1, 'int32');
	unitNumber = fread(fid, 1, 'int32');
	gain = fread(fid, 1, 'int32');
	filter = fread(fid, 1, 'int32');
	xPos = fread(fid, 1, 'double');
	yPos = fread(fid, 1, 'double');
	WFrequency = fread(fid, 1, 'double'); % wf sampling fr.
	ADtoMV  = fread(fid, 1, 'double'); % coeff to convert from AD values to Millivolts.
	NPointsWave(i) = fread(fid, 1, 'int32'); % number of points in each wave
	NMarkers = fread(fid, 1, 'int32'); % how many values are associated with each marker
	MarkerLength = fread(fid, 1, 'int32'); % how many characters are in each marker value
	MVOfffset = fread(fid, 1, 'double'); % coeff to shift AD values in Millivolts: mv = raw*ADtoMV+MVOfffset
    filePosition = ftell(fid);
    
    if type == 3    % waveform data type
        waveCount = waveCount + 1;
        waveOffset(waveCount) = offset;
    end
    
    fseek(fid, filePosition, 'bof');
    fread(fid, 60, 'char');
end

% write the waveforms into the .nex file after moving the file pointer to
% the appropriate position

offset = waveOffset(waveIdx) + n(waveIdx) * 4 + ...
    NPointsWave(waveIdx) * numSamplesWritten * 2;
% the offset is the offset for the start of data for this waveform,
% plus 4 times the number of timestamps to account for int32's that
% account for the timestamps themselves, plus the number of points per
% waveform times the number of waveforms already written * 2 to account
% for int16's.
fseek(fid, offset, 'bof');
wf = int16(wf);
fwrite(fid, wf, 'int16');
    
fclose(fid);