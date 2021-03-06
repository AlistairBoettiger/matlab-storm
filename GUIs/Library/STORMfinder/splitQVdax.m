function splitQVdax(pathin,varargin)
%--------------------------------------------------------------------------
% splitQVdax(filepath) splits all the movies in the designated folder into
% quadrants corresponding to the layout of the quadview.  The default is
% set for our Zhuang Lab system.  
%
%--------------------------------------------------------------------------
%% Required Inputs
% pathin / string 
%          folder containing dax files 
% 
%--------------------------------------------------------------------------
%% Optional Inputs
% alldax / structure / []
%           structure output from dirs command containing list of all dax
%       in folder to extract quadview.  If empty code will attempt to
%       process all dax in folder.  This will produce errors if some files
%       are already split.
% chns / cell / {'750','647','561','488'};
%           List of QV quadrants to pull out of the image. The names must
%           match those in QVorder
% QVorder / cell / {'647', '561', '750', '488'}
%           Name of QV channels, left to right, top to bottom.
% savepath / string / ''
%           Location to save the output daxfile 
% step / double / 100
%           Number of frames to load at once
% delete / boolean / false
%           Delete original file after data has been split
% maxsize / double / 1E3
%           skip files larger than this (in Mb)
% verbose / boolean / true
%           Print messages to screen
%
%--------------------------------------------------------------------------
%% Examples
% folders ={'N:\2013-10-31_G9'};
% 
% 
% for i=1:length(folders)
%     pathin = [folders{i},filesep];
%     savepath = [folders{i},filesep,'splitdax\'];
%     mkdir(savepath);
%     splitQVdax(pathin,'chns',{'647','561','488'},'savepath',...
%         savepath,'delete',true);
% end

% pathin = 'O:\2013-11-26_E11\'


%% default parameters
alldax = [];
QVorder = {'647', '561', '750', '488'};
chns = {'750','647','561','488'};    
savepath = '';
step = 2500;
verbose = true; 
promptoverwrite = true;
delFile = false;
maxsize = 1E3;
% pathin = 'K:\2013-10-26_D12\QVDax\';

QVc{1,1} = 1:256;  QVc{1,2} = 1:256;
QVc{2,1} = 1:256;  QVc{2,2} = 257:512;
QVc{3,1} =  257:512;  QVc{3,2} = 1:256;
QVc{4,1} = 257:512;  QVc{4,2} = 257:512;

if nargin > 1
    if (mod(length(varargin), 2) ~= 0 ),
        error(['Extra Parameters passed to the function ''' mfilename ''' must be passed in pairs.']);
    end
    parameterCount = length(varargin)/2;
    for parameterIndex = 1:parameterCount,
        parameterName = varargin{parameterIndex*2 - 1};
        parameterValue = varargin{parameterIndex*2};
        switch parameterName  
            case 'maxsize'
                maxsize = CheckParameter(parameterValue,'positive','maxsize'); 
            case 'alldax'
                alldax= CheckParameter(parameterValue,'struct','alldax');
            case 'QVorder'
                QVorder= CheckParameter(parameterValue,'cell','QVorder');
            case 'chns'
                chns = CheckParameter(parameterValue,'cell','chns');
            case 'savepath'
                savepath = CheckParameter(parameterValue,'string','savepath');
            case 'step'
                step = CheckParameter(parameterValue,'positive','step'); 
            case 'delete'
                delFile = CheckParameter(parameterValue,'boolean','delete'); 
            case 'verbose'
                verbose =  CheckParameter(parameterValue,'boolean','verbose');
            otherwise
                error(['The parameter ''' parameterName ''' is not recognized by the function ''' mfilename '''.']);
        end
    end
end

% Parse default options
if isempty(alldax)
    alldax = dir([pathin,filesep,'*.dax']); 
end

inrange = ([alldax.bytes] < maxsize*1E6); 
alldax = alldax(inrange); 

if isempty(savepath)
    savepath = pathin;
end


%% Main code

D = length(alldax);
if verbose
    disp(['found ',num2str(D),' dax files in folder']);
    disp(pathin);
end

for d=1:D  % Main loop over daxfiles
    try
        dax = [pathin,alldax(d).name];
        infoFile = ReadInfoFile(dax,'verbose',verbose);
    catch
        warning(['Unable to read info file for ' dax]);
        disp('skipping this file...'); 
        continue;
    end
    
    % ---- Determine which frames of the QV are present in the image
    fin = infoFile.frame_dimensions;
    chns_id = [true, fin(1)>256, fin(2)>257, fin(1)>256 && fin(2)>257];
    chns_in = 1:4;
    chns_in = chns_in(chns_id);
   
    C = length(chns); 
    chns_out = zeros(1,C);
    for c=1:C
        chns_out(c) = find(1-cellfun(@isempty,strfind(QVorder,chns{c})));
    end   
    chns_out = intersect(chns_out,chns_in); % can't have more channels out than channels in; 
    C = length(chns_out);

    % ---- Write Infofiles for all the quadrants
    name = infoFile.localName;
    Nframes = infoFile.number_of_frames;
    infoOut = cell(C,1); 
    daxnames = cell(C,1); 
    daxname = regexprep(name,'\.inf','\.dax');

    for c=chns_out
        infoOut{c} = infoFile;
        infoOut{c}.x_end = 256;
        infoOut{c}.y_end = 256;
        infoOut{c}.frame_dimensions = [256,256];
        infoOut{c}.frame_size = 256*256; 
        infoOut{c}.localName = [QVorder{c},'quad_',name];   
        infoOut{c}.localPath = savepath; 
        daxnames{c} = [QVorder{c},'quad_',daxname];
        WriteInfoFiles(infoOut{c}, 'verbose', true);
    end
  

    correctBits = zeros(C,1); 
    
    
    % Main Loop over channels
    cn = 0;
    for c=chns_out
        cn = cn+1;
        %---- Open dax for writing 
        % check if file exists, if it does, ask user to overwrite
         newDaxName = [infoOut{c}.localPath daxnames{c}];
        if exist(newDaxName,'file') && promptoverwrite
            ow = input('file exists, overwrite? 0=skip, 1=yes, 2=skip all, 3=overwrite all,  ');
            if ow==0
                owrite = false;
                continue
            elseif ow==1
                owrite = true;
            elseif ow==2
              owrite = false;
              promptoverwrite = false;
              continue
            elseif ow==3
              owrite = true;
              promptoverwrite = false;
            end
        elseif exist(newDaxName,'file')
            if ~owrite
                continue
            end
        end
             
        fid = fopen(newDaxName, 'w+');
        if fid<0
            warning(['Unable to open ' infoOut{c}.localPath daxnames{c}]);
        elseif verbose
            disp(['Parsing ' infoOut{c}.localPath daxnames{c},'...']);
        end
        

        for n=1:step:Nframes  % n = 3;
            % write movie 'step' frames at a time;
            try
                movie = ReadDax(dax,'startFrame',n,'endFrame',n+step-1,'verbose',false);
  %             figure(1); clf; subplot(1,2,1); imagesc( int16(movie(QVc{c,1},QVc{c,2},1)) );
  %             subplot(1,2,2); imagesc( int16(movie(QVc{c,1},QVc{c,2},2)) );
                fwrite(fid, ipermute(movie(QVc{c,1},QVc{c,2},:), [2 1 3]), 'int16', 'b');
                if verbose
                    progress = min([(n)/Nframes*100,100]);
                    disp(['Movie ',num2str(d),' of ',num2str(D),' ',...
                         'Panel ', num2str(cn),' of ',num2str(C),' ',...
                         num2str(progress,3),'% complete']) 
                end
            catch
                if verbose
                    disp('end of movie reached'); 
                end
                fclose(fid);
                break
            end
        end 
        
        if verbose
            disp(['finished writing ',newDaxName]);
        end
        dat = dir(newDaxName);
        expectedSize = 16/8*infoOut{c}.number_of_frames*...
            infoOut{c}.frame_dimensions(1)*infoOut{c}.frame_dimensions(2);
        if dat.bytes < expectedSize
            warning(['Saved file size was ',num2str(dat.bytes),...
                ' Expected files size was ',num2str(expectedSize)]);
            correctBits(cn) = 0; 
        elseif dat.bytes == expectedSize
            correctBits(cn) = 1;
        end
        
        
    end
    correctBits
    if prod(correctBits)==1 && delFile
      warning(['Deleting original file ',dax]);
      delete(dax); 
    end
    pause(.5);
end
fclose('all');

