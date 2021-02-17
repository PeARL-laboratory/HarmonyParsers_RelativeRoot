%% Parse the chord symbols in the Rolling Stone data set using the Relative Root encoding scheme.
%
% *Rolling Stone DATA SET*
%
%   Download: <http://rockcorpus.midside.com/index.html>
%   Citation: Declercq, T., & Temperley, D. (2011). A corpus analysis of 
%             rock harmony. Popular Music, 30, 47-70. 
%
%
% *PARSE -- Relative Root Representation* 
%
%   Encoding:    <RN><Quality><Inversion><Extensions>
%
%     RN         -- Roman numeral encoded in relation to the key. Case
%                   denotes quality of the triad (major or minor).
%                   Named chords (+6, Ct, etc.) are converted to RN roots,
%                   with the names included in the quality slot (e.g., 
%                   #ivGer). Applied dominants (e.g., V/ii) receive 
%                   diatonic equivalents. Chords may also be preceded by a
%                   chromatic accidental relative to the major scale 
%                   (e.g., viio/V --> #ivo):
%                       --  double flat
%                        -  flat 
%                        #  sharp
%                       ##  double sharp
%
%     Quality    -- Chord quality: 
%                        M  major seventh (never annotated in this data
%                           set)
%                           minor seventh (no symbol)
%                        h  half-diminished seventh
%                        o  diminished triad or seventh
%                        +  augmented
%                      Ger  German augmented sixth (never annotated in this
%                           data set)
%                       Fr  French augmented sixth (never annotated in this
%                           data set)
%                       It  Italian augmented sixth (never annotated in
%                           this data set)
%                       Ct  Common-tone diminished seventh (never annotated
%                           in this data set)
%
%     Inversion  -- Chord inversion:
%                           root position (no symbol)
%                        6  first inversion triad
%                       64  second inversion triad
%                        7  root position seventh
%                       65  first inversion seventh
%                       43  second inversion seventh
%                       42  third inversion seventh 
%
%     Extensions -- Suspensions or added tones appear in parentheses, with
%                   added tones preceded by '+'.
%
%   Example:     V(64) (i.e., a cadential six-four)
%
% *DEPENDENCIES*
%
%                -- None.
%
% *HISTORY*
%
%   Date:          2.16.2021          
%   Time:          16:33	
%   Programmer:    David Sears	    
%   Version:       MATLAB 9.6 (R2019a, PC)


%% IMPORT

% Files.
cd('<file_path>\RS_200\rs200_harmony_exp\rs200_harmony_exp')
files = dir('*dt.txt');
files = {files.name}';
len = length(files);
fnames = extractBefore(files,'.txt');
fnames = replace(fnames,'-','_');
fnames = strcat('RollingStone_',fnames);


% Variables
RNs = {'--IV' '--I' '--V' '--II' '--VI' '--III' '--VII'  ...
       '-IV' '-I' '-V' '-II' '-VI' '-III' '-VII'  ...
       'IV' 'I' 'V' 'II' 'VI' 'III' 'VII'  ...
       '#IV' '#I' '#V' '#II' '#VI' '#III' '#VII' ...
       '##IV' '##I' '##V' '##II' '##VI' '##III' '##VII'};     
for i = 1:len
    
    % Import file.
    tmp = importdata(files{i});
    
    
    %% PREPROCESS
    
    % Delete line with warning from tmp.
    if length(tmp)>1
        idx = find(contains(tmp,'Warning'));
        tmp(idx) = [];
    end
    
    % Tokenize
    chords = split(tmp);
    
    % Delete empty cells.
    chords = chords(~cellfun(@isempty, chords));
    
    % Replace dots with preceding RN.
    x = any(ismember(chords,'.'));
    while x==1
        idx = find(ismember(chords,'.'));
        chords(idx) = chords(idx-1);
        x = any(ismember(chords,'.'));
    end
    
    % Delete tokens with special characters not relating to the RNs.
    del = {'[' ']' '|' 'R'};
    idx = find(contains(chords,del));
    chords(idx) = [];
    
    % Save raw chord tokens.
    RollingStone.chords.(fnames{i}) = chords; % RNs
    
    
    %% CONVERT
    
    % Replace flat symbol.
    chords = replace(chords,'b','-');
    
    % Replace 'a' with '+'.
    chords = replace(chords,'a','+');
    
    % Replace 'x' with 'o'.
    chords = replace(chords,'x','o');
    
    % Create extensions and replace 's' symbol (for 'sus').
    chords = replace(chords,'11','7(11)');
    
    % Add cadential six-four 'V(64)' to I64-V progressions.
    idx = find(strcmp(chords,'I64'));
    idx2 = find(strcmp(chords,'i64'));
    idx = union(idx,idx2);
    tmp = [chords(idx) chords(idx+1)];
    if ~isempty(tmp)
        change = contains(tmp(:,2),{'V7' 'V/'}) | strcmp(tmp(:,2),'V');
        tmp = tmp(:,1);
        relroot = extractAfter(tmp,'/');
        relroot = strcat('/',relroot);
        relroot(strcmp(relroot,'/')) = {''};
        tmp(change) = {'V(64)'};
        tmp(change) = strcat(tmp(change),relroot(change));
        chords(idx) = tmp;
    end
    
    % Add parentheses to all other sus chords (e.g., 'I(4)').
    idx = find(contains(chords,'s'));
    chords(idx) = replace(chords(idx),'s','(');
    chords(idx) = strcat(chords(idx),')');
    
    % Add parentheses to chords with '5' following the RN (presumably power
    % chords).
    chords = replace(chords,'-5','(-5)');
    
    % Get rid of applied chords of I (bug in the corpus).
    chords = regexprep(chords,'[/]+I$','','ignorecase');
    
    % Convert applied chords to diatonic space.
    applied_idx = find(contains(chords,'/'));
    
    if ~isempty(applied_idx)
        applied = chords(applied_idx);
        
        % Create numerator and denominator of applied chords.
        [num_1 den] = strtok(applied,'/');
        num = regexprep(num_1,'[^vViI]','');
        den = erase(den,'/');
        
        % Index for adding 'd' for V7/ and its inversions.
        dom_idx = find(strcmp(num,'V') & contains(num_1,{'7' '65' '43' '42'}));
        
        % Determine relative root for applied chords.
        [~,den_idx] = ismember(upper(den),RNs);
        [~,num_idx] = ismember(upper(num),RNs);
        [~,tonic_idx] = ismember('I',RNs);
        root_idx = mod(num_idx-tonic_idx + den_idx,length(RNs));
        roots = [RNs(root_idx)]';
        
        % Ensure relative root reflects quality of numerator chord.
        idx = isstrprop(num,'upper');
        for j = 1:length(idx)
            if any(idx{j})==1
                idx2(j,1) = 1;
            else idx2(j,1) = 0;
            end
        end
        idx = idx2;
        roots(idx==0) = lower(roots(idx==0));

        % Include other symbols from numerator chord to root (e.g., 'o' '+').
        num = regexprep(num_1,'[^ho+123456789]','');
        roots(dom_idx) = strcat(roots(dom_idx),'d'); % Add 'd' for Mm7ths
        roots = strcat(roots,num);

        chords(applied_idx) = roots;
        clear applied_idx applied dom_idx num_1 den num den_idx num_idx tonic_idx root_idx roots idx roots idx2
    end
    
    % Add to structure.
    RollingStone.RNs.(fnames{i}) = chords; % RNs
    RollingStone.rootRNs.(fnames{i}) = regexprep(chords,'[^-#vViI]',''); % RN roots
    
    clear tmp chords del idx x
    
end

% Alphabet
for i=1:len
    sequence.(fnames{i}) = cellstr(RollingStone.RNs.(fnames{i}));
end
chords = cellfun(@(x) cellstr(sequence.(x)), fnames, 'UniformOutput', false);
alphabet = unique(vertcat(chords{:}));
RollingStone.fnames = fnames;
RollingStone.alphabet = alphabet;

% Add years for songs.
cd('<file_path>\RS_200')
tmp = readtable('song_list_DS.csv');
fnames_new = tmp.fname;
fnames_new = erase(fnames_new,'''');
fnames_new = replace(fnames_new,'-','_');
fnames_new = replace(fnames_new,'miind','mind');
fnames_new = replace(fnames_new,'nite','night');
fnames_new = erase(fnames_new,'_perkins');
fnames = erase(fnames,'RollingStone_');
fnames = erase(fnames,'_dt');
[~,idx] = ismember(fnames,fnames_new);
year = tmp.year(idx);
RollingStone.year = year;

cd('<destination_file_path>')
save('RollingStone.mat','RollingStone')











    
   