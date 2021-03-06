function [MosaicView,Im,box_coords] = MosaicViewer(folder,position,varargin)
%--------------------------------------------------------------------------
% MosaicView = MosaicViewer(folder,position,varargin)
% 
%--------------------------------------------------------------------------
% Inputs: 
% folder / string 
%                   -- folder containing the mosaic created by STEVE
% position / 1x2 double
%                   -- vector location on which to center the mosaic, given
%                   in stage units (as recorded in .info files).
% 
%--------------------------------------------------------------------------
% Outputs:
% MosaicView / handle to figure created. 
% Im / image matrix plotted in figure
% box / coordinates of box
%--------------------------------------------------------------------------
% Optional Inputs:
% 'Ntiles' / double / 30
%                   -- number of images from the mosaic file nearest to the
%                   seed point to inculde in the output image
% 'multicolor' / logical / string
%                   -- format of .msc file, whether it contains a column
%                   indicating the parameters file used.  if parameters
%                   files contain '488','561', or '647' they will be mapped
%                   to G/R/B.  
% 'shrink' / double / 1
%                   -- downsample the ouput by this factor.  
%                   for large N or for mapping lower res images which
%                   will be upsampled to high res scale, 'shrink' is
%                   advisable.  If only low res images, shrink should be at
%                   least the ratio of 100x to the mag used (i.e. 5 for
%                   20x images) 
% 'showbox' / logical / false
% 'verbose' / logical / true
%                   -- print progress and warnings to command line. 
%--------------------------------------------------------------------------
% Alistair Boettiger
% boettiger.alistair@gmail.com
% October 10th, 2012
%
% Version 1.2
%--------------------------------------------------------------------------
% Creative Commons License 3.0 CC BY  
%--------------------------------------------------------------------------


global ScratchPath

%--------------------------------------------------------------------------
%% Default Parameters
%--------------------------------------------------------------------------
multicolor = true;
showbox = false;
shrk = 1; 
N = 30; 
verbose = true; 
MosaicView = [];

% % some test parameters:
% folder = 'I:\2013-02-02_BXCemb\Mosaic';
% position_list = ['I:\2013-02-02_BXCemb\STORM',filesep,'positions.txt'];
% P = csvread(position_list);
% position = P(3,:); 

%--------------------------------------------------------------------------
% Parse mustHave variables
%--------------------------------------------------------------------------
if nargin < 1
   error([mfilename,' expects 3 inputs, folder, bead_folder and binnames']);
end


%--------------------------------------------------------------------------
% Parse variable input
%--------------------------------------------------------------------------
if nargin > 1
    if (mod(length(varargin), 2) ~= 0 ),
        error(['Extra Parameters passed to the function ''' mfilename ''' must be passed in pairs.']);
    end
    parameterCount = length(varargin)/2;
    for parameterIndex = 1:parameterCount,
        parameterName = varargin{parameterIndex*2 - 1};
        parameterValue = varargin{parameterIndex*2};
        switch parameterName
            case 'shrink'
                shrk = CheckParameter(parameterValue,'positive','shrink');
            case 'multicolor'
                multicolor = CheckParameter(parameterValue,'boolean','multicolor');
            case 'Ntiles'
                N = CheckParameter(parameterValue,'positive','Ntiles');
            case 'fighandle'
                MosaicView = CheckParameter(parameterValue,'nonnegative','fighandle');
            case 'showbox'
                showbox = CheckParameter(parameterValue,'boolean','showbox');
            case 'verbose';
                verbose = CheckParameter(parameterValue,'boolean','verbose');
            otherwise
                error(['The parameter ''' parameterName ''' is not recognized by the function ''' mfilename '''.']);
        end
    end
end


%--------------------------------------------------------------------------
%% Main code
%--------------------------------------------------------------------------


% Find msc file
fname = dir([folder,filesep,'*.msc']);
if isempty(fname)
    error(['cannot find .msc file in ',folder]);
else
fname = fname.name;
end

% Load msc file
if multicolor
    msc_length = 8;  % number of columns in new format (multi-color)
else
    msc_length = 7; % number of columns in old format
end

msc= textread([folder,filesep,fname],'%s','delimiter',',','headerlines',2,'endofline','\r\n');
try
    M = reshape(msc,msc_length,length(msc)/msc_length)';
catch er
    disp(er.message);
    disp('color data for mosaic not found...');
    msc_length = 7;
    M = reshape(msc,msc_length,length(msc)/msc_length)';
end

% parse msc file
% Note that x,y are flipped between stage and steve coordinates. 
xu = cellfun(@str2double,M(:,2)); 
yu = cellfun(@str2double,M(:,3)); 
x  = cellfun(@str2double,M(:,4));
y  = cellfun(@str2double,M(:,5));
mag= cellfun(@str2double,M(:,6));
% z  = cellfun(@str2double,M(:,7));  % could use to order 


[frames,~] = knnsearch([xu,yu],position,'k',N);



% get dimensions of grid to plot:
xmin = min(x(frames));
xmax = max(x(frames));
ymin = min(y(frames));
ymax = max(y(frames));


xs = round(xmax - xmin + 256); 
ys = round(ymax - ymin + 256);
X = round(x-xmin+ 256);
Y = round(y-ymin+ 256);

xs = round(xs/shrk); 
ys = round(ys/shrk); 
X = round(X/shrk);
Y = round(Y/shrk); 

% This is heavy on memory for large N or for scaling up low res images.

Im = zeros(ys,xs,3,'uint8');
for k = 1:length(frames); 
    i = frames(k); % start from bottom of list, oldest images first.
    try  % incase file is missing/corrupted
 im = imread([folder,filesep,M{i,1},'.png']); % load image
    catch er
        im = zeros(256,'uint8'); % load a blank
        disp(er.message);
    end

% for plotting the 4x images, need to scale up:
 if mag(i) == .04
      if verbose
          disp('skipping 4x mag image');
      end
      continue;
     % im = imresize(im,1/.04);
 end
 % rescale image if requested
      im = imresize(im,1/shrk); 
      [h,w,~] = size(im);
    % color channels
    try
        if strfind(M{i,8},'488');
            chn = 2;
        elseif strfind(M{i,8},'561');
            chn = 1;
        elseif strfind(M{i,8},'647');
            chn = 3;
        else
            chn = 2;
        end
    catch  %#ok<CTCH>
        if verbose
            disp('channel not specified');
        end
        chn = 2;
    end
    h2 = round(h/2); % avoid integer operands for colon operator warning
    w2 = round(w/2); 
    
%     if k==1  % Highlight the closest frame in red
%         chn=1;
%     end
  y1 = Y(i)+1-h2;
  y2 = Y(i)+h2;
  x1 = X(i)+1-w2;
  x2 = X(i)+w2;
  try
  Im(y1:y2,x1:x2,chn) = im(:,:,1);
  catch er
      disp(er.message);
      save([ScratchPath,'errdat.mat']);
      Im(y1:y2,x1:x2,chn) = im(:,:,1);
      % load([ScratchPath,'errdat.mat']);
  end
  
  if verbose
      if rem(k,50) == 0
          disp(['rebuilding mosaic ', num2str(100*k/length(frames),3), '% done']);
      end
  end
end



if isempty(MosaicView)
    MosaicView = figure; clf;
else
    figure(MosaicView); 
end
  image(imresize(Im,1)); 
  
% Plot box
  my = (y(end)-y(1)) / (xu(end)-xu(1));
  by = -128;
  
 %  x2 = linspace(-800,600); y2 = m*x2-128;
 % figure(2); clf; plot(xu(mag==1),y(mag==1),'k');
  %hold on; plot(x2,y2);
  
  mx = (x(end)-x(1)) / (yu(end)-yu(1));
  bx = -128; 
  %figure(2); clf; plot(yu,x,'k');
% 
  box_cy = my*position(1)+ by-ymin+256;
  box_cx = mx*position(2)+ bx-xmin+256;
  box_coords = [box_cx - 127,box_cy-127,256,256];
   
 
  if showbox
      if verbose
          disp('drawing box');
      end
      box_coords
      figure(MosaicView); hold on;
      rectangle('Position',box_coords,'EdgeColor','w');
      lin = findobj(gca,'Type','patch');
      set(lin,'color','w','linewidth',3);
      hold off; title('Mosaic');
  end
%   
%       % % For troubleshooting:   
%   sy = median(y(mag==1)./xu(mag==1));
%   sx = median(x(mag==1)./yu(mag==1));
  

